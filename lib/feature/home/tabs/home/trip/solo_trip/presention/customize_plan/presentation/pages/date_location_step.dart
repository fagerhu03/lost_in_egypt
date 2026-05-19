import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../../../../../../../core/utils/map_style_helper.dart';
import '../../../../../../../../../../theme/theme.dart';
import '../manager/trip_planner_controller.dart';
import '../widgets/quiz_scaffold.dart';

class DateLocationStep extends StatefulWidget {
  final TripPlannerController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const DateLocationStep({
    super.key,
    required this.controller,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<DateLocationStep> createState() => _DateLocationStepState();
}

class _DateLocationStepState extends State<DateLocationStep> {
  GoogleMapController? _miniMapController;
  String? _mapStyle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    MapStyleHelper.getStyle(context).then((style) {
      if (mounted) setState(() => _mapStyle = style);
    });
  }

  @override
  void dispose() {
    _miniMapController?.dispose();
    super.dispose();
  }

  static String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _pickDate(BuildContext context, {required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;
    if (isFrom) {
      widget.controller.updateFromDate(picked);
    } else {
      widget.controller.updateToDate(picked);
    }
  }

  Future<void> _openMapPicker(BuildContext context) async {
    final result = await Navigator.pushNamed(context, '/map_picker');
    if (result == null || result is! Map<String, dynamic>) return;
    widget.controller.updateLocation(result['name'] as String? ?? '');
    widget.controller.updateLocationCoords(
      result['lat'] as double,
      result['lng'] as double,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.darkPrimaryButton;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final fieldBg = isDark ? const Color(0xFF0B1D26) : Colors.white;
    final borderColor = textColor.withValues(alpha: 0.12);

    final from = widget.controller.plan.fromDate;
    final to = widget.controller.plan.toDate;
    final locationName = widget.controller.plan.location;
    final lat = widget.controller.plan.locationLat;
    final lng = widget.controller.plan.locationLng;

    final int? nights =
        (from != null && to != null && to.isAfter(from))
            ? to.difference(from).inDays
            : null;

    return QuizScaffold(
      title: 'Choose your dates & location',
      stepIndex: 0,
      onNext: widget.onNext,
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── From date ────────────────────────────────────────────────────
          _DateField(
            label: 'From',
            value: from != null ? _fmtDate(from) : null,
            hint: 'Start date',
            fieldBg: fieldBg,
            borderColor: borderColor,
            textColor: textColor,
            primary: primary,
            onTap: () => _pickDate(context, isFrom: true),
          ),

          // ── Nights indicator ─────────────────────────────────────────────
          if (nights != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$nights ${nights == 1 ? 'night' : 'nights'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 10),

          // ── To date ──────────────────────────────────────────────────────
          _DateField(
            label: 'To',
            value: to != null ? _fmtDate(to) : null,
            hint: 'End date',
            fieldBg: fieldBg,
            borderColor: borderColor,
            textColor: textColor,
            primary: primary,
            onTap: () => _pickDate(context, isFrom: false),
          ),

          const SizedBox(height: 16),

          // ── Location picker ──────────────────────────────────────────────
          GestureDetector(
            onTap: () => _openMapPicker(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: fieldBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: locationName != null && locationName.isNotEmpty
                      ? primary.withValues(alpha: 0.4)
                      : borderColor,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: locationName != null && locationName.isNotEmpty
                        ? primary
                        : textColor.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      locationName != null && locationName.isNotEmpty
                          ? locationName
                          : 'Where are you starting from?',
                      style: TextStyle(
                        fontSize: 14,
                        color: locationName != null && locationName.isNotEmpty
                            ? textColor
                            : textColor.withValues(alpha: 0.4),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.map_outlined,
                    size: 16,
                    color: primary.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),

          // ── Mini map preview ─────────────────────────────────────────────
          if (lat != null && lng != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 150,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(lat, lng),
                    zoom: 14,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('start'),
                      position: LatLng(lat, lng),
                    ),
                  },
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  mapToolbarEnabled: false,
                  scrollGesturesEnabled: false,
                  zoomGesturesEnabled: false,
                  rotateGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  style: _mapStyle,
                  onMapCreated: (controller) {
                    _miniMapController = controller;
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String? value;
  final String hint;
  final Color fieldBg;
  final Color borderColor;
  final Color textColor;
  final Color primary;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.hint,
    required this.fieldBg,
    required this.borderColor,
    required this.textColor,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: fieldBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasValue ? primary.withValues(alpha: 0.4) : borderColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: hasValue ? primary : textColor.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value ?? hint,
                style: TextStyle(
                  fontSize: 14,
                  color: hasValue ? textColor : textColor.withValues(alpha: 0.4),
                ),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: hasValue ? primary : textColor.withValues(alpha: 0.35),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
