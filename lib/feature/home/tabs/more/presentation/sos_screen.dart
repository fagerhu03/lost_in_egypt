import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:lost_in_egypt/feature/home/tabs/map/data/places_api_service.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/datasources/map_focus_service.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Emergency dial numbers — add / remove freely here
// ─────────────────────────────────────────────────────────────────────────────
const _dialNumbers = [
  _DialNumber(label: "Tourist Police", number: "126", color: Color(0xFF1565C0)),
  _DialNumber(label: "Ambulance",      number: "123", color: Color(0xFFB71C1C)),
  _DialNumber(label: "Police",         number: "122", color: Color(0xFF283593)),
  _DialNumber(label: "Fire Brigade",   number: "180", color: Color(0xFFE65100)),
  _DialNumber(label: "Gas Emergency",  number: "129", color: Color(0xFFF9A825)),
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
    placeTypes: ["hospital", "emergency_room"],
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
  String _locationStatus = "Tap to find nearest help";
  bool _locating = false;
  bool _searching = false;

  int _selectedCategory = 0;
  List<_NearbyResult> _results = [];
  String? _searchError;

  // ── Location ───────────────────────────────────────────────────────────────

  Future<void> _findHelp() async {
    setState(() {
      _locating = true;
      _locationStatus = "Getting your location…";
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
          _locationStatus = "Location permission denied";
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
        _locationStatus = "Location found";
      });

      await _searchNearby();
    } catch (e) {
      setState(() {
        _locating = false;
        _locationStatus = "Could not get location";
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

  List<Widget> _buildDialGrid(BuildContext context) {
    final widgets = <Widget>[];
    for (int i = 0; i < _dialNumbers.length; i += 2) {
      final isLast = i + 1 >= _dialNumbers.length;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: isLast
              ? _DialChip(
                  dialNumber: _dialNumbers[i],
                  onTap: () => _call(_dialNumbers[i].number, context),
                )
              : Row(
                  children: [
                    Expanded(
                      child: _DialChip(
                        dialNumber: _dialNumbers[i],
                        onTap: () => _call(_dialNumbers[i].number, context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DialChip(
                        dialNumber: _dialNumbers[i + 1],
                        onTap: () => _call(_dialNumbers[i + 1].number, context),
                      ),
                    ),
                  ],
                ),
        ),
      );
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
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        children: [
          // ── Find Nearest Help ──────────────────────────────────────────────
          _SectionHeader(label: "Find Nearest Help", onSurface: onSurface),
          const SizedBox(height: 10),

          // Category tabs
          Row(
            children: List.generate(_categories.length, (i) {
              final cat = _categories[i];
              final selected = _selectedCategory == i;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < _categories.length - 1 ? 8 : 0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategory = i);
                      if (_position != null) _searchNearby();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? cat.color
                            : cat.color.withOpacity(isDark ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(cat.icon,
                              color: selected ? Colors.white : cat.color, size: 20),
                          const SizedBox(height: 4),
                          Text(
                            cat.label,
                            style: TextStyle(
                              fontSize: 11,
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

          const SizedBox(height: 12),

          // Find / Retry button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_locating || _searching) ? null : _findHelp,
              icon: (_locating || _searching)
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.my_location_rounded, size: 20),
              label: Text(
                _position == null
                    ? "Find Nearest ${_categories[_selectedCategory].label}"
                    : "Refresh — ${_categories[_selectedCategory].label}",
                style: const TextStyle(fontFamily: 'Marcellus', fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _categories[_selectedCategory].color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          // Location status
          if (_position != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_rounded,
                    size: 14,
                    color: Colors.green.shade600),
                const SizedBox(width: 4),
                Text(
                  "Using your current location",
                  style: TextStyle(
                      fontSize: 12, color: onSurface.withOpacity(0.55)),
                ),
              ],
            ),
          ],

          // Error state
          if (_searchError != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: _searchError!, onSurface: onSurface),
          ],

          // Results
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 16),
            ..._results.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
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

          const SizedBox(height: 24),

          // ── Emergency Dial Numbers ─────────────────────────────────────────
          _SectionHeader(label: "Emergency Numbers", onSurface: onSurface),
          const SizedBox(height: 12),

          // 2-column rows, last chip full-width
          ..._buildDialGrid(context),

          const SizedBox(height: 12),
          Text(
            "These are Egypt's official emergency numbers. "
            "Tourist Police (126) has English-speaking operators.",
            style: TextStyle(
              fontSize: 11,
              color: onSurface.withOpacity(0.5),
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
  const _DialNumber({required this.label, required this.number, required this.color});
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
          fontSize: 16,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13, color: Colors.orange, height: 1.4),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: categoryColor.withOpacity(0.2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(categoryIcon, color: categoryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                    fontFamily: 'Marcellus',
                  ),
                ),
                if (result.address.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    result.address,
                    style: TextStyle(
                        fontSize: 11, color: onSurface.withOpacity(0.55)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.near_me_rounded,
                        size: 12, color: categoryColor),
                    const SizedBox(width: 4),
                    Text(
                      result.distanceLabel,
                      style: TextStyle(
                        fontSize: 12,
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
                    const SizedBox(width: 8),
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: color)),
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
    return Material(
      color: dialNumber.color,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dialNumber.number,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Marcellus',
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    dialNumber.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.85),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
