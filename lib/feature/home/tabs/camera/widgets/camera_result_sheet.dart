import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';
import 'package:lost_in_egypt/core/widgets/shimmer_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lost_in_egypt/core/models/weather_context.dart';
import 'package:lost_in_egypt/core/services/ai_storyteller_service.dart';
import 'package:lost_in_egypt/core/services/recommendation_service.dart';
import 'package:lost_in_egypt/core/services/weather_controller.dart';
import 'package:lost_in_egypt/core/widgets/weather_forecast_sheet.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/datasources/local_places_service.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/datasources/map_focus_service.dart';

class CameraResultSheet extends StatefulWidget {
  final PlaceModel place;
  final bool fromGallery;

  const CameraResultSheet({super.key, required this.place, this.fromGallery = false});

  static void show(BuildContext context, PlaceModel place, {bool fromGallery = false}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => CameraResultSheet(place: place, fromGallery: fromGallery),
    );
  }

  @override
  State<CameraResultSheet> createState() => _CameraResultSheetState();
}

class _CameraResultSheetState extends State<CameraResultSheet> {
  String? story;
  bool isLoadingStory = false;
  bool isLoadingAudio = false;
  bool isPlaying = false;
  bool isPaused = false;
  bool showFullDescription = false;
  String? _audioFilePath;

  // Nearby suggestions surfaced under the landmark — populated once on mount.
  List<PlaceModel> _nearbySuggestions = [];
  bool _loadingNearby = true;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() { isPlaying = false; isPaused = false; });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNearbySuggestions());
  }

  Future<void> _loadNearbySuggestions() async {
    try {
      final pool = await LocalPlacesService.getTopRatedPlaces(limit: 100);
      if (!mounted) return;
      // Filter to within 3 km of the identified landmark
      final lat = widget.place.coordinate.latitude;
      final lng = widget.place.coordinate.longitude;
      final nearby = pool.where((p) {
        if (p.id == widget.place.id) return false;
        final d = Geolocator.distanceBetween(
            lat, lng, p.coordinate.latitude, p.coordinate.longitude);
        return d <= 3000;
      }).toList();
      if (nearby.isEmpty) {
        setState(() => _loadingNearby = false);
        return;
      }

      final candidates = nearby.map((p) => <String, dynamic>{
            'placeId': p.id,
            'name': p.title,
            'types': [p.category],
            'tags': p.tags,
            'rating': p.rating,
            'userRatingCount': p.userRatingCount,
            'lat': p.coordinate.latitude,
            'lng': p.coordinate.longitude,
          }).toList();

      final result = await RecommendationService.recommendPlaces(
        candidates: candidates,
        context: 'similar',
        limit: 3,
        userLat: lat,
        userLng: lng,
        weather: WeatherController.weather.value,
      );
      if (!mounted) return;
      if (result == null || result.recommendations.isEmpty) {
        setState(() => _loadingNearby = false);
        return;
      }
      final idToPlace = {for (final p in nearby) p.id: p};
      final ordered = result.recommendations
          .map((r) => idToPlace[r.placeId])
          .whereType<PlaceModel>()
          .toList();
      setState(() {
        _nearbySuggestions = ordered;
        _loadingNearby = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingNearby = false);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _handleAudioButton() async {
    if (isPlaying) {
      await _audioPlayer.pause();
      if (mounted) setState(() { isPlaying = false; isPaused = true; });
      return;
    }
    if (isPaused) {
      await _audioPlayer.resume();
      if (mounted) setState(() { isPlaying = true; isPaused = false; });
      return;
    }
    await _startPlayback();
  }

  Future<void> _handleReplay() async {
    await _audioPlayer.stop();
    setState(() { isPlaying = false; isPaused = false; });
    await _startPlayback();
  }

  Future<void> _startPlayback() async {
    if (story == null) return;
    final l10n = AppLocalizations.of(context);

    if (_audioFilePath != null) {
      await _audioPlayer.play(DeviceFileSource(_audioFilePath!));
      if (mounted) setState(() { isPlaying = true; isPaused = false; });
      return;
    }

    setState(() => isLoadingAudio = true);

    try {
      final audioBytes = await AIStorytellerService.getStoryAudio(story!);
      if (audioBytes == null || !mounted) {
        if (mounted) {
          setState(() => isLoadingAudio = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.cameraAudioGenFailed)),
          );
        }
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/story_narration.mp3');
      await file.writeAsBytes(audioBytes);
      _audioFilePath = file.path;

      await _audioPlayer.play(DeviceFileSource(_audioFilePath!));
      if (mounted) setState(() { isPlaying = true; isPaused = false; isLoadingAudio = false; });
    } catch (e) {
      debugPrint("Audio playback error: $e");
      if (mounted) {
        setState(() => isLoadingAudio = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cameraAudioPlayFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final surface = theme.colorScheme.surface;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: surface,
          // BottomSheet radius — not scaled per design convention
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.zero,
          children: [
            ShimmerImage(
              url: widget.place.imagePath,
              height: 220.h,
              width: double.infinity,
              fit: BoxFit.cover,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              fallbackIcon: Icons.broken_image,
              fallbackBackgroundColor: Colors.grey[300],
            ),
            Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.place.title,
                    style: TextStyle(
                      fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                      fontSize: 26.sp,
                      color: onSurface,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: primary, size: 20.r),
                      SizedBox(width: 8.w),
                      Text(
                        l10n.cameraLandmarkIdentified,
                        style: TextStyle(
                          color: onSurface.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  // Weather advisory for this landmark
                  ValueListenableBuilder<WeatherContext?>(
                    valueListenable: WeatherController.weather,
                    builder: (_, weather, _) {
                      if (weather == null || !weather.isOutdoorAdvisory) {
                        return const SizedBox.shrink();
                      }
                      final color = weather.severityColor;
                      return GestureDetector(
                        onTap: () => WeatherForecastSheet.show(context),
                        child: Container(
                          margin: EdgeInsets.only(top: 10.h),
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.10),
                            border: Border.all(color: color.withValues(alpha: 0.30)),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Row(
                            children: [
                              Icon(weather.conditionIcon, color: color, size: 15.r),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  l10n.cameraTapForecast(weather.conditionLabel),
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 10.h),

                  // Description with Read More
                  if (story == null) ...[
                    Text(
                      showFullDescription
                          ? widget.place.description
                          : widget.place.description.length > 100
                              ? '${widget.place.description.substring(0, 100)}...'
                              : widget.place.description,
                      style: TextStyle(color: onSurface.withValues(alpha: 0.6)),
                    ),
                    if (widget.place.description.length > 100)
                      TextButton(
                        onPressed: () => setState(() => showFullDescription = !showFullDescription),
                        child: Text(
                          showFullDescription ? l10n.cameraReadLess : l10n.cameraReadMore,
                          style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ] else
                    Container(
                      height: 150.h,
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: primary.withValues(alpha: 0.30)),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          story!,
                          style: TextStyle(fontStyle: FontStyle.italic, color: onSurface),
                        ),
                      ),
                    ),
                  SizedBox(height: 20.h),

                  if (story == null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoadingStory
                            ? null
                            : () async {
                                setState(() => isLoadingStory = true);
                                final storyResult = await AIStorytellerService
                                    .getLandmarkStory(widget.place.title);
                                setState(() {
                                  story = storyResult;
                                  isLoadingStory = false;
                                });
                                if (storyResult.isNotEmpty) {
                                  RecommendationService.recordSignal(
                                    placeId: widget.place.id,
                                    placeName: widget.place.title,
                                    types: [widget.place.category],
                                    tags: widget.place.tags,
                                    signalType: widget.fromGallery ? 'like' : 'visit',
                                    source: 'camera',
                                  );
                                }
                              },
                        icon: isLoadingStory
                            ? SizedBox(
                                width: 20.r,
                                height: 20.r,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : Icon(Icons.auto_awesome, color: theme.colorScheme.onPrimary),
                        label: Text(isLoadingStory ? l10n.cameraConsulting : l10n.cameraTellStory),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isLoadingAudio ? null : _handleAudioButton,
                            icon: isLoadingAudio
                                ? SizedBox(
                                    width: 20.r,
                                    height: 20.r,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  )
                                : Icon(
                                    isPlaying
                                        ? Icons.pause
                                        : isPaused
                                            ? Icons.play_arrow
                                            : Icons.headphones,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                            label: Text(
                              isLoadingAudio
                                  ? l10n.cameraGenerating
                                  : isPlaying
                                      ? l10n.cameraPause
                                      : isPaused
                                          ? l10n.cameraResume
                                          : l10n.cameraListen,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                            ),
                          ),
                        ),
                        if (_audioFilePath != null) ...[
                          SizedBox(width: 10.w),
                          IconButton.filled(
                            onPressed: isLoadingAudio ? null : _handleReplay,
                            icon: const Icon(Icons.replay),
                            tooltip: l10n.cameraReplay,
                            style: IconButton.styleFrom(
                              backgroundColor: primary.withValues(alpha: 0.15),
                              foregroundColor: primary,
                              padding: EdgeInsets.all(12.r),
                            ),
                          ),
                        ],
                      ],
                    ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            MapFocusService.instance.tabSwitchNotifier.value = 2;
                            MapFocusService.instance.triggerFocus(widget.place);
                          },
                          icon: Icon(Icons.map_outlined, color: theme.colorScheme.secondary),
                          label: Text(
                            l10n.cameraShowOnMap,
                            style: TextStyle(color: theme.colorScheme.secondary),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            side: BorderSide(color: theme.colorScheme.secondary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.secondary,
                            foregroundColor: theme.colorScheme.onSecondary,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                          ),
                          child: Text(l10n.cameraDone, style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),

                  // ── You might also like nearby ─────────────────────────
                  if (_loadingNearby || _nearbySuggestions.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 16.r, color: primary),
                        SizedBox(width: 6.w),
                        Text(
                          l10n.cameraNearby,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: onSurface,
                            fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    SizedBox(
                      height: 130.h,
                      child: _loadingNearby
                          ? ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 3,
                              itemBuilder: (_, _) => Container(
                                width: 150.w,
                                margin: EdgeInsetsDirectional.only(end: 10.w),
                                decoration: BoxDecoration(
                                  color: onSurface.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _nearbySuggestions.length,
                              itemBuilder: (_, i) {
                                final p = _nearbySuggestions[i];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    MapFocusService.instance.triggerFocus(p);
                                  },
                                  child: Container(
                                    width: 150.w,
                                    margin: EdgeInsetsDirectional.only(end: 10.w),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12.r),
                                      color: onSurface.withValues(alpha: 0.05),
                                      border: Border.all(
                                          color: onSurface.withValues(alpha: 0.08)),
                                    ),
                                    clipBehavior: Clip.hardEdge,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          height: 80.h,
                                          width: double.infinity,
                                          child: p.imagePath.startsWith('http')
                                              ? ShimmerImage(
                                                  url: p.imagePath,
                                                  fit: BoxFit.cover,
                                                  fallbackBackgroundColor: primary
                                                      .withValues(alpha: 0.06),
                                                )
                                              : Image.asset(p.imagePath,
                                                  fit: BoxFit.cover),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.fromLTRB(
                                              8.w, 4.h, 8.w, 4.h),
                                          child: Text(
                                            p.title,
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600,
                                              color: onSurface,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
