import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lost_in_egypt/core/models/weather_context.dart';
import 'package:lost_in_egypt/core/services/ai_storyteller_service.dart';
import 'package:lost_in_egypt/core/services/recommendation_service.dart';
import 'package:lost_in_egypt/core/services/weather_controller.dart';
import 'package:lost_in_egypt/core/widgets/weather_forecast_sheet.dart';
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

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() { isPlaying = false; isPaused = false; });
    });
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
            const SnackBar(content: Text('Could not generate audio. Please try again.')),
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
          const SnackBar(content: Text('Audio playback failed. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              child: SizedBox(
                height: 220.h,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: widget.place.imagePath,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (_, _, _) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.place.title,
                    style: TextStyle(
                      fontFamily: 'Marcellus',
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
                        'Landmark Identified',
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
                                  '${weather.conditionLabel} · Tap for forecast',
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
                          showFullDescription ? 'Read Less' : 'Read More',
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
                        label: Text(isLoadingStory ? 'Consulting history...' : 'Tell me a story'),
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
                                  ? 'Generating...'
                                  : isPlaying
                                      ? 'Pause'
                                      : isPaused
                                          ? 'Resume'
                                          : 'Listen',
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
                            tooltip: 'Replay from start',
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
                            'Show on Map',
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
                          child: const Text('Done', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
