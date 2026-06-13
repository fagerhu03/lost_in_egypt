import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:lost_in_egypt/feature/home/tabs/map/data/places_api_service.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/datasources/map_focus_service.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Emergency dial numbers — ordered by importance to tourists
// isFeatured = full-width, large chip; subtitle = context line
// ─────────────────────────────────────────────────────────────────────────────
const _dialNumbers = [
  // Priority 1 — most useful for tourists; always full-width
  _DialNumber(
    label: "Tourist Police",
    number: "126",
    color: Color(0xFF1565C0),
    isFeatured: true,
    subtitle: "English-speaking operators · Available 24/7",
  ),
  // Priority 2 — critical emergencies; side by side
  _DialNumber(label: "Ambulance", number: "123", color: Color(0xFFB71C1C)),
  _DialNumber(label: "Police",    number: "122", color: Color(0xFF283593)),
  // Priority 3 — specialist services; side by side
  _DialNumber(label: "Fire Brigade",  number: "180", color: Color(0xFFE65100)),
  _DialNumber(label: "Gas Emergency", number: "129", color: Color(0xFFF9A825)),
];

// ─────────────────────────────────────────────────────────────────────────────
// Help categories — maps a user-friendly label to Places API type strings
// ─────────────────────────────────────────────────────────────────────────────
const _categories = [
  _HelpCategory(
    label: "Police",
    icon: Icons.local_police_rounded,
    color: Color(0xFF1565C0),
    placeTypes: ["police"],
  ),
  _HelpCategory(
    label: "Hospital",
    icon: Icons.local_hospital_rounded,
    color: Color(0xFFB71C1C),
    placeTypes: ["hospital"],
  ),
  _HelpCategory(
    label: "Fire Station",
    icon: Icons.local_fire_department_rounded,
    color: Color(0xFFE65100),
    placeTypes: ["fire_station"],
  ),
];

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  final _placesService = GetIt.instance<PlacesApiService>();

  Position? _position;
  bool _locating = false;
  bool _searching = false;

  int _selectedCategory = 0;
  List<_NearbyResult> _results = [];
  String? _searchError;

  // ── Location ───────────────────────────────────────────────────────────────

  Future<void> _findHelp() async {
    setState(() {
      _locating = true;
      _searchError = null;
    });

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locating = false;
          _searchError =
              "Please enable location in your device settings to find nearby help.";
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _position = pos;
        _locating = false;
      });

      await _searchNearby();
    } catch (e) {
      setState(() {
        _locating = false;
        _searchError = "Make sure location services are enabled and try again.";
      });
    }
  }

  Future<void> _searchNearby() async {
    if (_position == null) return;
    setState(() {
      _searching = true;
      _results = [];
      _searchError = null;
    });

    try {
      final category = _categories[_selectedCategory];
      final raw = await _placesService.nearbySearch(
        lat: _position!.latitude,
        lng: _position!.longitude,
        includedTypes: category.placeTypes,
        radiusMeters: 10000, // 10 km
        maxResultCount: 5,
      );

      final results = raw.map((p) {
        final loc = p['location'] as Map<String, dynamic>?;
        final lat = (loc?['latitude'] as num?)?.toDouble() ?? 0.0;
        final lng = (loc?['longitude'] as num?)?.toDouble() ?? 0.0;
        final dist = Geolocator.distanceBetween(
          _position!.latitude,
          _position!.longitude,
          lat,
          lng,
        );
        return _NearbyResult(
          id: p['id'] as String? ?? '',
          name: (p['displayName'] as Map?)?['text'] as String? ?? 'Unknown',
          address: p['formattedAddress'] as String? ?? '',
          phone: p['internationalPhoneNumber'] as String?,
          lat: lat,
          lng: lng,
          distanceMeters: dist,
        );
      }).toList()
        ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

      setState(() {
        _results = results;
        _searching = false;
        if (results.isEmpty) {
          _searchError = "No ${_categories[_selectedCategory].label.toLowerCase()} "
              "stations found within 10 km. Try moving to a different area.";
        }
      });
    } catch (e) {
      setState(() {
        _searching = false;
        _searchError = "Search failed — check your connection and try again.";
      });
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _call(String number, BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open dialler")),
        );
      }
    }
  }

  void _openOnMap(_NearbyResult result) {
    final item = PlaceModel(
      id: result.id.isEmpty ? 'sos_${result.lat}_${result.lng}' : result.id,
      title: result.name,
      category: _categories[_selectedCategory].label,
      coordinate: GeoPoint(result.lat, result.lng),
      imagePath: '',
      locationAddress: result.address,
      rating: 0,
      price: 0,
      duration: '',
      weather: '',
      description: '',
    );

    // Pop back to HomeWrapper, then trigger map focus
    Navigator.popUntil(context, (r) => r.isFirst);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MapFocusService.instance.triggerFocus(item);
    });
  }

  // ── Dial grid ──────────────────────────────────────────────────────────────
  // Featured chips are always full-width; standard chips fill 2-column rows.

  List<Widget> _buildDialGrid(BuildContext context) {
    final featured  = _dialNumbers.where((d) => d.isFeatured).toList();
    final standard  = _dialNumbers.where((d) => !d.isFeatured).toList();
    final widgets   = <Widget>[];

    // Full-width featured chips first
    for (final dial in featured) {
      widgets.add(Padding(
        padding: EdgeInsets.only(bottom: 10.h),
        child: _DialChip(
          dialNumber: dial,
          onTap: () => _call(dial.number, context),
        ),
      ));
    }

    // Standard chips in 2-column rows
    for (int i = 0; i < standard.length; i += 2) {
      final isLast = i + 1 >= standard.length;
      widgets.add(Padding(
        padding: EdgeInsets.only(bottom: 10.h),
        child: isLast
            ? _DialChip(
                dialNumber: standard[i],
                onTap: () => _call(standard[i].number, context),
              )
            : Row(
                children: [
                  Expanded(
                    child: _DialChip(
                      dialNumber: standard[i],
                      onTap: () => _call(standard[i].number, context),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _DialChip(
                      dialNumber: standard[i + 1],
                      onTap: () => _call(standard[i + 1].number, context),
                    ),
                  ),
                ],
              ),
      ));
    }

    return widgets;
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final surface = theme.colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        title: const Text("SOS — Emergency", style: TextStyle(fontFamily: 'Marcellus')),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: onSurface,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 40.h),
        children: [
          // ── Find Nearest Help ──────────────────────────────────────────────
          _SectionHeader(label: "Find Nearest Help", onSurface: onSurface),
          SizedBox(height: 10.h),

          // Category tabs
          Row(
            children: List.generate(_categories.length, (i) {
              final cat = _categories[i];
              final selected = _selectedCategory == i;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < _categories.length - 1 ? 8.w : 0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategory = i);
                      if (_position != null) _searchNearby();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      decoration: BoxDecoration(
                        color: selected
                            ? cat.color
                            : cat.color.withValues(alpha: isDark ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        children: [
                          Icon(cat.icon,
                              color: selected ? Colors.white : cat.color, size: 20.r),
                          SizedBox(height: 4.h),
                          Text(
                            cat.label,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : cat.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          SizedBox(height: 12.h),

          // Find / Retry button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_locating || _searching) ? null : _findHelp,
              icon: (_locating || _searching)
                  ? SizedBox(
                      width: 18.w,
                      height: 18.h,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(Icons.my_location_rounded, size: 20.r),
              label: Text(
                _position == null
                    ? "Find Nearest ${_categories[_selectedCategory].label}"
                    : "Refresh — ${_categories[_selectedCategory].label}",
                style: TextStyle(fontFamily: 'Marcellus', fontSize: 15.sp),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _categories[_selectedCategory].color,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r)),
              ),
            ),
          ),

          // Location status
          if (_position != null) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.location_on_rounded,
                    size: 14.r,
                    color: Colors.green.shade600),
                SizedBox(width: 4.w),
                Text(
                  "Using your current location",
                  style: TextStyle(
                      fontSize: 12.sp, color: onSurface.withValues(alpha: 0.55)),
                ),
              ],
            ),
          ],

          // Error state
          if (_searchError != null) ...[
            SizedBox(height: 12.h),
            _ErrorBanner(message: _searchError!, onSurface: onSurface),
          ],

          // Results
          if (_results.isNotEmpty) ...[
            SizedBox(height: 16.h),
            ..._results.map((r) => Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: _NearbyCard(
                    result: r,
                    categoryColor: _categories[_selectedCategory].color,
                    categoryIcon: _categories[_selectedCategory].icon,
                    isDark: isDark,
                    onSurface: onSurface,
                    surface: surface,
                    onCall: r.phone != null
                        ? () => _call(r.phone!, context)
                        : null,
                    onMap: () => _openOnMap(r),
                  ),
                )),
          ],

          SizedBox(height: 24.h),

          // ── Emergency Dial Numbers ─────────────────────────────────────────
          _SectionHeader(label: "Emergency Numbers", onSurface: onSurface),
          SizedBox(height: 12.h),

          // 2-column rows, last chip full-width
          ..._buildDialGrid(context),

          SizedBox(height: 12.h),
          Text(
            "These are Egypt's official emergency numbers. "
            "Tourist Police (126) has English-speaking operators.",
            style: TextStyle(
              fontSize: 11.sp,
              color: onSurface.withValues(alpha: 0.5),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────

class _HelpCategory {
  final String label;
  final IconData icon;
  final Color color;
  final List<String> placeTypes;
  const _HelpCategory({
    required this.label,
    required this.icon,
    required this.color,
    required this.placeTypes,
  });
}

class _DialNumber {
  final String label;
  final String number;
  final Color color;
  /// When true, this chip renders full-width with larger text.
  final bool isFeatured;
  /// Optional context line shown below the label on featured chips.
  final String? subtitle;
  const _DialNumber({
    required this.label,
    required this.number,
    required this.color,
    this.isFeatured = false,
    this.subtitle,
  });
}

class _NearbyResult {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final double lat;
  final double lng;
  final double distanceMeters;

  const _NearbyResult({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.lat,
    required this.lng,
    required this.distanceMeters,
  });

  String get distanceLabel {
    if (distanceMeters < 1000) {
      return "${distanceMeters.round()} m";
    }
    return "${(distanceMeters / 1000).toStringAsFixed(1)} km";
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color onSurface;
  const _SectionHeader({required this.label, required this.onSurface});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: TextStyle(
          fontSize: 16.sp,
          fontFamily: 'Marcellus',
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
      );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final Color onSurface;
  const _ErrorBanner({required this.message, required this.onSurface});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 18.r),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 13.sp, color: Colors.orange, height: 1.4),
              ),
            ),
          ],
        ),
      );
}

class _NearbyCard extends StatelessWidget {
  final _NearbyResult result;
  final Color categoryColor;
  final IconData categoryIcon;
  final bool isDark;
  final Color onSurface;
  final Color surface;
  final VoidCallback? onCall;
  final VoidCallback onMap;

  const _NearbyCard({
    required this.result,
    required this.categoryColor,
    required this.categoryIcon,
    required this.isDark,
    required this.onSurface,
    required this.surface,
    required this.onCall,
    required this.onMap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: categoryColor.withValues(alpha: 0.2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42.r,
            height: 42.r,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(categoryIcon, color: categoryColor, size: 20.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.name,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                    fontFamily: 'Marcellus',
                  ),
                ),
                if (result.address.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    result.address,
                    style: TextStyle(
                        fontSize: 11.sp, color: onSurface.withValues(alpha: 0.55)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(Icons.near_me_rounded,
                        size: 12.r, color: categoryColor),
                    SizedBox(width: 4.w),
                    Text(
                      result.distanceLabel,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: categoryColor,
                      ),
                    ),
                    const Spacer(),
                    if (onCall != null)
                      _ActionButton(
                        icon: Icons.phone_rounded,
                        label: "Call",
                        color: categoryColor,
                        onTap: onCall!,
                      ),
                    SizedBox(width: 8.w),
                    _ActionButton(
                      icon: Icons.map_outlined,
                      label: "Map",
                      color: categoryColor,
                      onTap: onMap,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13.r, color: color),
              SizedBox(width: 4.w),
              Text(label,
                  style: TextStyle(
                      fontSize: 12.sp, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      );
}

class _DialChip extends StatelessWidget {
  final _DialNumber dialNumber;
  final VoidCallback onTap;

  const _DialChip({required this.dialNumber, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final featured = dialNumber.isFeatured;
    return Material(
      color: dialNumber.color,
      borderRadius: BorderRadius.circular(14.r),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white.withValues(alpha: 0.2),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: featured ? 18.h : 14.h,
          ),
          child: Row(
            children: [
              Container(
                width: featured ? 46.r : 36.r,
                height: featured ? 46.r : 36.r,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.phone_rounded,
                  color: Colors.white,
                  size: featured ? 22.r : 18.r,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          dialNumber.number,
                          style: TextStyle(
                            fontSize: featured ? 28.sp : 22.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Marcellus',
                            letterSpacing: 1.5,
                          ),
                        ),
                        if (featured) ...[
                          SizedBox(width: 10.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 7.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              'FOR TOURISTS',
                              style: TextStyle(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      dialNumber.label,
                      style: TextStyle(
                        fontSize: featured ? 13.sp : 11.sp,
                        fontWeight:
                            featured ? FontWeight.w600 : FontWeight.normal,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.2,
                      ),
                    ),
                    if (featured && dialNumber.subtitle != null) ...[
                      SizedBox(height: 3.h),
                      Text(
                        dialNumber.subtitle!,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.white.withValues(alpha: 0.72),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (featured)
                Icon(Icons.star_rounded, color: Colors.white70, size: 20.r),
            ],
          ),
        ),
      ),
    );
  }
}
