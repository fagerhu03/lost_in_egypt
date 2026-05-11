import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:lost_in_egypt/core/models/solo_plan.dart';
import 'package:lost_in_egypt/core/services/solo_plan_service.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/trip/solo_trip/presention/active_tour_screen.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/datasources/map_focus_service.dart';
import 'package:lost_in_egypt/feature/home/tabs/map/data/places_api_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart' show Share;

import '../../../../../../../../../../theme/theme.dart';
import '../../domain/entities/trip_plan_entity.dart';
import 'package:lost_in_egypt/core/services/recommendation_service.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class _Stop {
  final String name;
  final String placeType;
  final double estimatedHours;
  final String reason;
  final String notes;
  final double? lat;
  final double? lng;

  const _Stop({
    required this.name,
    required this.placeType,
    required this.estimatedHours,
    required this.reason,
    required this.notes,
    this.lat,
    this.lng,
  });

  factory _Stop.fromMap(Map<String, dynamic> m) => _Stop(
        name: m['name'] as String? ?? 'Unknown place',
        placeType: m['placeType'] as String? ?? 'tourist_attraction',
        estimatedHours: (m['estimatedHours'] as num?)?.toDouble() ?? 1.0,
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
        reason: m['reason'] as String? ?? '',
        notes: m['notes'] as String? ?? '',
      );

  _Stop copyWith({double? lat, double? lng}) => _Stop(
        name: name,
        placeType: placeType,
        estimatedHours: estimatedHours,
        reason: reason,
        notes: notes,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
      );
}

class _Transit {
  final String from;
  final String to;
  final String mode;
  final String duration;
  final String approxCost;
  final String tip;

  const _Transit({
    required this.from,
    required this.to,
    required this.mode,
    required this.duration,
    required this.approxCost,
    required this.tip,
  });

  factory _Transit.fromMap(Map<String, dynamic> m) => _Transit(
        from: m['from'] as String? ?? '',
        to: m['to'] as String? ?? '',
        mode: m['mode'] as String? ?? '',
        duration: m['duration'] as String? ?? '',
        approxCost: m['approxCost'] as String? ?? '',
        tip: m['tip'] as String? ?? '',
      );
}

class _Day {
  final int day;
  final String label;
  final List<_Stop> stops;
  final _Transit? transit;

  const _Day({
    required this.day,
    required this.label,
    required this.stops,
    this.transit,
  });

  factory _Day.fromMap(Map<String, dynamic> m) => _Day(
        day: (m['day'] as num?)?.toInt() ?? 1,
        label: m['label'] as String? ?? 'Day',
        transit: m['transit'] is Map
            ? _Transit.fromMap(Map<String, dynamic>.from(m['transit'] as Map))
            : null,
        stops: (m['stops'] as List? ?? [])
            .map((s) => _Stop.fromMap(Map<String, dynamic>.from(s as Map)))
            .toList(),
      );
}

class _Plan {
  final String title;
  final String summary;
  final String estimatedBudget;
  final List<_Day> days;

  const _Plan({
    required this.title,
    required this.summary,
    required this.estimatedBudget,
    required this.days,
  });

  factory _Plan.fromMap(Map<String, dynamic> m) => _Plan(
        title: m['title'] as String? ?? 'Your Egypt Trip',
        summary: m['summary'] as String? ?? '',
        estimatedBudget: m['estimatedBudget'] as String? ?? '',
        days: (m['days'] as List? ?? [])
            .map((d) => _Day.fromMap(Map<String, dynamic>.from(d as Map)))
            .toList(),
      );
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ResultScreen extends StatefulWidget {
  final TripPlanEntity plan;

  const ResultScreen({super.key, required this.plan});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  _Plan? _generatedPlan;
  String? _error;
  bool _loading = true;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _generate();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fn = FirebaseFunctions.instance.httpsCallable(
        'generateTripPlan',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      );
      final result = await fn.call({
        'plan': {
          'interests': widget.plan.interests,
          'areas': widget.plan.areas,
          'location': widget.plan.location ?? '',
          'fromDate': widget.plan.fromDate?.toIso8601String(),
          'toDate': widget.plan.toDate?.toIso8601String(),
          'tripTime': widget.plan.tripTimes.isEmpty ? 'Day' : widget.plan.tripTimes.join(' & '),
          'minBudget': widget.plan.minBudget,
          'maxBudget': widget.plan.maxBudget,
        },
      });
      final plan =
          _Plan.fromMap(Map<String, dynamic>.from(result.data as Map));
      if (mounted) setState(() { _generatedPlan = plan; _loading = false; });
      // Background-fill any missing coordinates so "View on Map" always works.
      _backfillMissingCoordinates(plan);
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message ?? 'Could not generate your plan.';
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Something went wrong. Please try again.';
          _loading = false;
        });
      }
    }
  }

  /// Some Groq responses omit `lat`/`lng` for individual stops. Look those up
  /// via Places API (Basic SKU = $0.017/call) so map pins land at the actual
  /// place instead of falling back to the user's start location. Runs all
  /// lookups in parallel.
  Future<void> _backfillMissingCoordinates(_Plan plan) async {
    final apiKey = dotenv.env['MAPS_API_KEY'] ?? '';
    if (apiKey.isEmpty) return;
    final api = PlacesApiService(apiKey: apiKey);

    final areaHint = widget.plan.areas.isNotEmpty
        ? widget.plan.areas.first
        : (widget.plan.location ?? '');

    // Collect every stop missing coordinates and fire the lookups in parallel.
    final pending = <Future<({_Stop stop, ({double lat, double lng})? loc})>>[];
    for (final day in plan.days) {
      for (final stop in day.stops) {
        if (stop.lat != null && stop.lng != null) continue;
        final query = areaHint.isNotEmpty
            ? '${stop.name}, $areaHint, Egypt'
            : '${stop.name}, Egypt';
        pending.add(api.findPlaceLocation(query).then((loc) => (stop: stop, loc: loc)));
      }
    }
    if (pending.isEmpty) return;
    final results = await Future.wait(pending);

    // Build a lookup keyed by stop identity, then rebuild the plan.
    final found = <_Stop, ({double lat, double lng})>{};
    for (final r in results) {
      if (r.loc != null) found[r.stop] = r.loc!;
    }
    if (found.isEmpty || !mounted) return;

    final newDays = plan.days
        .map((d) => _Day(
              day: d.day,
              label: d.label,
              transit: d.transit,
              stops: d.stops.map((s) {
                final loc = found[s];
                return loc == null ? s : s.copyWith(lat: loc.lat, lng: loc.lng);
              }).toList(),
            ))
        .toList();
    setState(() => _generatedPlan = _Plan(
          title: plan.title,
          summary: plan.summary,
          estimatedBudget: plan.estimatedBudget,
          days: newDays,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final gold = AppColors.lightPrimaryButton;

    return Scaffold(
      backgroundColor: bg,
      body: _loading
          ? _LoadingView(anim: _pulseAnim, gold: gold, isDark: isDark)
          : _error != null
              ? _ErrorView(
                  message: _error!,
                  onRetry: _generate,
                  gold: gold,
                  isDark: isDark,
                )
              : _PlanView(
                  plan: _generatedPlan!,
                  entity: widget.plan,
                  gold: gold,
                  isDark: isDark,
                ),
    );
  }
}

// ── Loading view ──────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  final Animation<double> anim;
  final Color gold;
  final bool isDark;

  const _LoadingView(
      {required this.anim, required this.gold, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.darkText : AppColors.lightBox;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: anim,
              builder: (_, _) => Opacity(
                opacity: anim.value,
                child: Icon(Icons.map_outlined, size: 64, color: gold),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Planning your trip…',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                fontFamily: 'Marcellus',
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Our AI guide is building a personalised day-by-day itinerary for you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textColor.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 160,
              child: LinearProgressIndicator(
                color: gold,
                backgroundColor: gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final Color gold;
  final bool isDark;

  const _ErrorView(
      {required this.message,
      required this.onRetry,
      required this.gold,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.darkText : AppColors.lightBox;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: Icon(Icons.chevron_left_rounded,
                    color: textColor, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_outlined, size: 56, color: gold),
                    const SizedBox(height: 20),
                    Text(
                      'Couldn\'t load your plan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Marcellus',
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withValues(alpha: 0.6),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Plan view ─────────────────────────────────────────────────────────────────

class _PlanView extends StatefulWidget {
  final _Plan plan;
  final TripPlanEntity entity;
  final Color gold;
  final bool isDark;

  const _PlanView(
      {required this.plan,
      required this.entity,
      required this.gold,
      required this.isDark});

  @override
  State<_PlanView> createState() => _PlanViewState();
}

class _PlanViewState extends State<_PlanView> {
  bool _saving = false;
  bool _isSaved = false;
  bool _viewingMap = false;
  bool _startingTour = false;
  bool _exporting = false;
  SavedPlan? _savedPlan;

  _Plan get plan => widget.plan;
  TripPlanEntity get entity => widget.entity;
  Color get gold => widget.gold;
  bool get isDark => widget.isDark;

  Future<void> _viewStopOnMap(BuildContext ctx, _Stop stop) async {
    // Refuse to fall back to the user's start location — that puts every
    // unlocated stop's pin on top of the wrong place. Tell the user instead.
    if (stop.lat == null || stop.lng == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text("Couldn't pin ${stop.name} on the map yet. Try again in a moment."),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    if (_viewingMap) return; // debounce double-taps while we save+start
    setState(() => _viewingMap = true);

    try {
      final activePlan = await _ensureSavedAndStarted();
      if (!ctx.mounted) return;

      // Build a synthetic PlaceModel from the AI stop. The map screen will
      // attempt to match this against an existing dataset pin (by name, then
      // proximity) and prefer the dataset's MapItem so the detail sheet
      // shows real photos / reviews / description from the bundled JSON.
      final model = PlaceModel(
        id: stop.name.toLowerCase().replaceAll(' ', '_'),
        title: stop.name,
        category: stop.placeType,
        coordinate: GeoPoint(stop.lat!, stop.lng!),
        imagePath: '',
        locationAddress: stop.name,
        rating: 0,
        price: 0,
        duration: '${stop.estimatedHours} hrs',
        weather: '',
        description: stop.notes,
      );
      if (!ctx.mounted) return;

      MapFocusService.instance.clearTourStop();
      if (activePlan != null) {
        MapFocusService.instance.triggerTourStop(model, activePlan);
      } else {
        MapFocusService.instance.triggerCameraFocus(model);
      }
      Navigator.of(ctx).popUntil((r) => r.isFirst);
    } finally {
      if (mounted) setState(() => _viewingMap = false);
    }
  }

  /// Persists the plan and flips it to "active" so [`triggerTourStop`] has a
  /// real plan to attach to. Reuses the cached reference on subsequent taps.
  /// Returns null only if the Firestore write failed.
  Future<SavedPlan?> _ensureSavedAndStarted() async {
    // Already started — reuse
    if (_savedPlan != null && _savedPlan!.status == SoloPlanStatus.active) {
      return _savedPlan;
    }
    try {
      // Already saved (manual Save button) but not started — just start it
      if (_savedPlan != null) {
        await SoloPlanService.instance.startTour(_savedPlan!.id);
        final updated = _savedPlan!.copyWith(
          status: SoloPlanStatus.active,
          startedAt: DateTime.now(),
        );
        if (mounted) setState(() => _savedPlan = updated);
        return updated;
      }
      // First time — save then start
      final days = _buildDaysForSave();
      final saved = await SoloPlanService.instance.saveCustomPlan(
        title: plan.title,
        tagline: plan.summary.length > 80
            ? '${plan.summary.substring(0, 77)}…'
            : plan.summary,
        days: days,
        estimatedBudget: plan.estimatedBudget,
        areas: entity.areas.isNotEmpty ? entity.areas : ['Egypt'],
      );
      await SoloPlanService.instance.startTour(saved.id);
      final activeSaved = saved.copyWith(
        status: SoloPlanStatus.active,
        startedAt: DateTime.now(),
      );
      if (mounted) {
        setState(() {
          _savedPlan = activeSaved;
          _isSaved = true;
        });
      }
      return activeSaved;
    } catch (_) {
      return null;
    }
  }

  List<SavedPlanDay> _buildDaysForSave() {
    return plan.days.asMap().entries.map((entry) {
      final day = entry.value;
      final stops = day.stops
          .map((s) => SavedPlanStop(
                name: s.name,
                placeType: s.placeType,
                estimatedDuration: '${s.estimatedHours} hrs',
                notes: s.notes.isEmpty ? null : s.notes,
                lat: s.lat,
                lng: s.lng,
              ))
          .toList();
      final transit = day.transit == null
          ? null
          : SavedPlanTransit(
              from: day.transit!.from,
              to: day.transit!.to,
              mode: day.transit!.mode,
              duration: day.transit!.duration,
              approxCost: day.transit!.approxCost,
              tip: day.transit!.tip,
            );
      return SavedPlanDay(
        dayNumber: entry.key + 1,
        label: day.label,
        stops: stops,
        transit: transit,
      );
    }).toList();
  }

  Future<void> _savePlan(BuildContext ctx) async {
    setState(() => _saving = true);
    try {
      final saved = await SoloPlanService.instance.saveCustomPlan(
        title: plan.title,
        tagline: plan.summary.length > 80
            ? '${plan.summary.substring(0, 77)}…'
            : plan.summary,
        days: _buildDaysForSave(),
        estimatedBudget: plan.estimatedBudget,
        areas: entity.areas.isNotEmpty ? entity.areas : ['Egypt'],
      );

      if (!ctx.mounted) return;
      setState(() {
        _isSaved = true;
        _savedPlan = saved;
      });
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: const Text('Plan saved! Find it in My Plans.'),
          backgroundColor: gold,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (_) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: const Text('Could not save plan. Try again.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _startTour(BuildContext ctx) async {
    if (_startingTour) return;
    setState(() => _startingTour = true);
    try {
      final activePlan = await _ensureSavedAndStarted();
      if (!ctx.mounted) return;
      if (activePlan == null) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: const Text('Could not start tour. Try again.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        return;
      }
      Navigator.push(
        ctx,
        MaterialPageRoute(builder: (_) => ActiveTourScreen(plan: activePlan)),
      );
    } finally {
      if (mounted) setState(() => _startingTour = false);
    }
  }

  Future<void> _exportPdf(BuildContext ctx) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final doc = pw.Document();
      final gold = PdfColor.fromHex('D6A00F');
      final darkText = PdfColor.fromHex('1A1A1A');

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context _) => [
            pw.Text(
              plan.title,
              style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: gold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              plan.summary,
              style: pw.TextStyle(fontSize: 12, color: darkText, lineSpacing: 3),
            ),
            pw.SizedBox(height: 12),
            if (plan.estimatedBudget.isNotEmpty)
              pw.Text('Estimated Budget: ${plan.estimatedBudget}',
                  style: pw.TextStyle(fontSize: 12, color: gold, fontWeight: pw.FontWeight.bold)),
            if (_dateRange.isNotEmpty)
              pw.Text('Dates: $_dateRange', style: pw.TextStyle(fontSize: 12, color: darkText)),
            pw.Divider(color: gold, height: 28),
            ...plan.days.expand((day) => [
              if (day.transit != null) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: gold),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Travel: ${day.transit!.from} → ${day.transit!.to}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: gold, fontSize: 12),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Mode: ${day.transit!.mode}', style: const pw.TextStyle(fontSize: 11)),
                      if (day.transit!.duration.isNotEmpty)
                        pw.Text('Duration: ${day.transit!.duration}', style: const pw.TextStyle(fontSize: 11)),
                      if (day.transit!.approxCost.isNotEmpty)
                        pw.Text('Cost: ${day.transit!.approxCost}', style: const pw.TextStyle(fontSize: 11)),
                      if (day.transit!.tip.isNotEmpty)
                        pw.Text('Tip: ${day.transit!.tip}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              ],
              pw.Text(
                day.label,
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: gold),
              ),
              pw.SizedBox(height: 6),
              ...day.stops.asMap().entries.map((e) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(children: [
                      pw.Text(
                        '${e.key + 1}. ${e.value.name}',
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: darkText),
                      ),
                      pw.Spacer(),
                      pw.Text(
                        '${e.value.estimatedHours} hr',
                        style: pw.TextStyle(fontSize: 11, color: gold),
                      ),
                    ]),
                    if (e.value.reason.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 3),
                        child: pw.Text(e.value.reason, style: const pw.TextStyle(fontSize: 11)),
                      ),
                    if (e.value.notes.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text(e.value.notes,
                            style: pw.TextStyle(fontSize: 11, color: PdfColor.fromHex('555555'))),
                      ),
                  ],
                ),
              )),
              pw.SizedBox(height: 12),
            ]),
          ],
        ),
      );

      final bytes = await doc.save();
      if (!ctx.mounted) return;
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${plan.title.replaceAll(' ', '_')}.pdf',
      );
    } catch (_) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: const Text('Could not export itinerary. Try again.'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _discardPlan(BuildContext ctx) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (d) => AlertDialog(
        title: const Text('Discard plan?'),
        content: const Text('This plan will not be saved. You can always generate a new one.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Keep')),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: Text('Discard', style: TextStyle(color: Colors.red.shade600)),
          ),
        ],
      ),
    );
    if (confirm != true || !ctx.mounted) return;
    final uniqueTypes = plan.days
        .expand((d) => d.stops)
        .map((s) => s.placeType)
        .toSet();
    for (final type in uniqueTypes) {
      RecommendationService.recordSignal(
        placeId: 'custom_${type.toLowerCase().replaceAll(' ', '_')}',
        placeName: plan.title,
        types: [type],
        signalType: 'dismiss',
        source: 'result_screen',
      );
    }
    Navigator.pop(ctx);
  }

  String get _dateRange {
    if (entity.fromDate == null && entity.toDate == null) return '';
    final fmt = DateFormat('MMM d');
    if (entity.fromDate != null && entity.toDate != null) {
      return '${fmt.format(entity.fromDate!)} – ${fmt.format(entity.toDate!)}';
    }
    if (entity.fromDate != null) return fmt.format(entity.fromDate!);
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.darkText : AppColors.lightBox;
    final cardColor =
        isDark ? AppColors.darkPatternOverlay : const Color(0xFFFFFEF0);
    final totalStops =
        plan.days.fold<int>(0, (acc, d) => acc + d.stops.length);

    return SafeArea(
      child: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left_rounded,
                      color: textColor, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                // Save Plan
                IconButton(
                  icon: _saving
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: gold),
                        )
                      : Icon(
                          _isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                          color: gold,
                          size: 22,
                        ),
                  tooltip: _isSaved ? 'Saved' : 'Save Plan',
                  onPressed: (_saving || _isSaved) ? null : () => _savePlan(context),
                ),
                IconButton(
                  icon: _exporting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: gold),
                        )
                      : Icon(Icons.picture_as_pdf_outlined, color: textColor, size: 22),
                  tooltip: 'Export PDF',
                  onPressed: _exporting ? null : () => _exportPdf(context),
                ),
                IconButton(
                  icon: Icon(Icons.share_outlined, color: textColor, size: 22),
                  onPressed: () => Share.share(
                    '${plan.title}\n\n${plan.summary}\n\nPlanned with Lost in Egypt 🌍',
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable body ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title block
                  Text(
                    plan.title,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Marcellus',
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    plan.summary,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withValues(alpha: 0.65),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_dateRange.isNotEmpty)
                        _StatChip(
                            icon: Icons.calendar_today_outlined,
                            label: _dateRange,
                            gold: gold),
                      _StatChip(
                          icon: Icons.place_outlined,
                          label: '$totalStops locations',
                          gold: gold),
                      if (plan.estimatedBudget.isNotEmpty)
                        _StatChip(
                            icon: Icons.wallet_outlined,
                            label: plan.estimatedBudget,
                            gold: gold),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Day sections — interleave a transit card above any day
                  // that travels to a different city than the previous one.
                  ...plan.days.expand(
                    (day) => [
                      if (day.transit != null)
                        _TransitCard(
                          transit: day.transit!,
                          cardColor: cardColor,
                          textColor: textColor,
                          gold: gold,
                        ),
                      _DayCard(
                        day: day,
                        cardColor: cardColor,
                        textColor: textColor,
                        gold: gold,
                        onViewOnMap: (stop) => _viewStopOnMap(context, stop),
                      ),
                    ],
                  ),

                  // ── Discard / Start Tour CTAs ─────────────────────────────
                  if (!_isSaved)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _discardPlan(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade600,
                            side: BorderSide(color: Colors.red.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Discard',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _startingTour ? null : () => _startTour(context),
                      icon: _startingTour
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(
                              _savedPlan?.status == SoloPlanStatus.active
                                  ? Icons.directions_walk_rounded
                                  : Icons.play_arrow_rounded,
                              size: 22,
                            ),
                      label: Text(
                        _savedPlan?.status == SoloPlanStatus.active
                            ? 'Continue Tour'
                            : 'Start Tour',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Marcellus',
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: gold.withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color gold;

  const _StatChip(
      {required this.icon, required this.label, required this.gold});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: gold),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: gold, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Transit card (inter-city travel between days) ─────────────────────────────

class _TransitCard extends StatelessWidget {
  final _Transit transit;
  final Color cardColor;
  final Color textColor;
  final Color gold;

  const _TransitCard({
    required this.transit,
    required this.cardColor,
    required this.textColor,
    required this.gold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: gold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: gold.withValues(alpha: 0.25),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.alt_route_rounded, size: 16, color: gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${transit.from}  →  ${transit.to}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: gold,
                    fontFamily: 'Marcellus',
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            transit.mode,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (transit.duration.isNotEmpty)
                _TransitChip(
                  icon: Icons.schedule_rounded,
                  label: transit.duration,
                  gold: gold,
                ),
              if (transit.approxCost.isNotEmpty)
                _TransitChip(
                  icon: Icons.payments_outlined,
                  label: transit.approxCost,
                  gold: gold,
                ),
            ],
          ),
          if (transit.tip.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded,
                    size: 14, color: textColor.withValues(alpha: 0.55)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    transit.tip,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TransitChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color gold;

  const _TransitChip({
    required this.icon,
    required this.label,
    required this.gold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: gold),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: gold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Day card ──────────────────────────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  final _Day day;
  final Color cardColor;
  final Color textColor;
  final Color gold;
  final void Function(_Stop) onViewOnMap;

  const _DayCard({
    required this.day,
    required this.cardColor,
    required this.textColor,
    required this.gold,
    required this.onViewOnMap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: gold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            day.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: gold,
              fontFamily: 'Marcellus',
            ),
          ),
        ),
        ...day.stops.asMap().entries.map((e) {
          final isLast = e.key == day.stops.length - 1;
          return _StopTile(
            stop: e.value,
            isLast: isLast,
            cardColor: cardColor,
            textColor: textColor,
            gold: gold,
            onViewOnMap: () => onViewOnMap(e.value),
          );
        }),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── Stop tile ─────────────────────────────────────────────────────────────────

class _StopTile extends StatelessWidget {
  final _Stop stop;
  final bool isLast;
  final Color cardColor;
  final Color textColor;
  final Color gold;
  final VoidCallback onViewOnMap;

  const _StopTile({
    required this.stop,
    required this.isLast,
    required this.cardColor,
    required this.textColor,
    required this.gold,
    required this.onViewOnMap,
  });

  @override
  Widget build(BuildContext context) {
    final hours = stop.estimatedHours == stop.estimatedHours.truncate()
        ? '${stop.estimatedHours.toInt()} hr'
        : '${stop.estimatedHours} hrs';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: gold, width: 1.5),
                  ),
                  child: Icon(_iconFor(stop.placeType), size: 15, color: gold),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: gold.withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            stop.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Marcellus',
                              color: textColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: gold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule_outlined,
                                  size: 11, color: gold),
                              const SizedBox(width: 3),
                              Text(hours,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: gold,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (stop.reason.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: gold.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: gold.withValues(alpha: 0.2), width: 1),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.auto_awesome_outlined,
                                size: 12, color: gold),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                stop.reason,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: gold,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (stop.notes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        stop.notes,
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor.withValues(alpha: 0.65),
                          height: 1.45,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: onViewOnMap,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.map_outlined, size: 14, color: gold),
                          const SizedBox(width: 4),
                          Text(
                            'View on Maps',
                            style: TextStyle(
                              fontSize: 13,
                              color: gold,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String type) {
    return switch (type) {
      'mosque' => Icons.mosque_outlined,
      'church' => Icons.church_outlined,
      'museum' => Icons.museum_outlined,
      'market' => Icons.store_mall_directory_outlined,
      'beach' => Icons.beach_access_outlined,
      'park' => Icons.park_outlined,
      'restaurant' || 'cafe' => Icons.restaurant_outlined,
      'archaeological_site' => Icons.explore_outlined,
      'monument' => Icons.account_balance_outlined,
      'historical_landmark' => Icons.location_city_outlined,
      _ => Icons.place_outlined,
    };
  }
}
