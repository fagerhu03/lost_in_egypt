import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:lost_in_egypt/core/widgets/shimmer_image.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/places_api_service.dart';

/// Renders a curated place's photo, re-resolving stale bundled URLs.
///
/// The Places photo references baked into `assets/cat_*.json` expire — their
/// media endpoint returns HTTP 400 "photo resource invalid" — so any surface
/// that renders those bundled places shows a broken image. For an http-backed
/// `imagePath` this widget re-resolves a live photo by [placeId] via
/// [PlacesApiService.getFreshPhotoUrl] (Firestore-cached, one shared lookup per
/// place). Local-asset paths are shown as-is; falls back to an icon when
/// offline or the place has no photo.
class PlacePhoto extends StatefulWidget {
  final String placeId;
  final String imagePath;
  final BoxFit fit;
  final Color fallbackBg;
  final Color fallbackIconColor;
  final double fallbackIconSize;
  final int maxWidth;

  const PlacePhoto({
    super.key,
    required this.placeId,
    required this.imagePath,
    required this.fallbackBg,
    required this.fallbackIconColor,
    this.fit = BoxFit.cover,
    this.fallbackIconSize = 36,
    this.maxWidth = 800,
  });

  @override
  State<PlacePhoto> createState() => _PlacePhotoState();
}

class _PlacePhotoState extends State<PlacePhoto> {
  String? _url;
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    if (widget.imagePath.startsWith('http')) {
      // Stale bundled Places URL → re-resolve a fresh one by Place ID.
      _resolving = true;
      _resolve();
    } else {
      _url = widget.imagePath; // local-asset placeholder
    }
  }

  /// The `cat_*.json` entries carry a synthetic `id` (`cat_mosque_0`), but the
  /// real Google Place ID is embedded in the (now-stale) photo URL path:
  /// `…/v1/places/{PLACE_ID}/photos/{REF}/media…`. Prefer that over [placeId].
  static final RegExp _placeIdInUrl = RegExp(r'/places/([^/]+)/photos/');

  Future<void> _resolve() async {
    String? fresh;
    try {
      final embedded = _placeIdInUrl.firstMatch(widget.imagePath)?.group(1);
      final pid = (embedded != null && embedded.isNotEmpty)
          ? embedded
          : widget.placeId;
      fresh = await GetIt.instance<PlacesApiService>()
          .getFreshPhotoUrl(pid, maxWidth: widget.maxWidth);
    } catch (_) {
      fresh = null;
    }
    if (!mounted) return;
    setState(() {
      _url = fresh;
      _resolving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_resolving) {
      return ColoredBox(color: widget.fallbackBg);
    }
    final url = _url;
    if (url == null || url.isEmpty) {
      return ColoredBox(
        color: widget.fallbackBg,
        child: Center(
          child: Icon(Icons.image_not_supported_outlined,
              color: widget.fallbackIconColor, size: widget.fallbackIconSize.r),
        ),
      );
    }
    if (url.startsWith('http')) {
      return ShimmerImage(
        url: url,
        fit: widget.fit,
        fallbackIcon: Icons.image_not_supported_outlined,
        fallbackBackgroundColor: widget.fallbackBg,
        fallbackIconColor: widget.fallbackIconColor,
        fallbackIconSize: widget.fallbackIconSize.r,
      );
    }
    return Image.asset(url, fit: widget.fit);
  }
}
