import 'package:flutter/material.dart';
import 'package:lost_in_egypt/core/models/solo_plan.dart';
import 'package:lost_in_egypt/core/services/solo_plan_service.dart';
import '../../../../../../../theme/theme.dart';
import 'active_tour_screen.dart';

class MyPlansScreen extends StatelessWidget {
  const MyPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor = isDark ? AppColors.darkText : AppColors.lightBox;
    final gold = AppColors.lightPrimaryButton;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          leading: IconButton(
            icon:
                Icon(Icons.chevron_left_rounded, color: textColor, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'My Plans',
            style: TextStyle(
              fontFamily: 'Marcellus',
              color: textColor,
              fontSize: 20,
            ),
          ),
          bottom: TabBar(
            labelColor: gold,
            unselectedLabelColor: textColor.withValues(alpha: 0.5),
            indicatorColor: gold,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Saved'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: StreamBuilder<List<SavedPlan>>(
          stream: SoloPlanService.instance.streamPlans(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                    color: gold, strokeWidth: 2),
              );
            }

            if (snap.hasError) {
              return Center(
                child: Text(
                  'Could not load plans',
                  style: TextStyle(color: textColor.withValues(alpha: 0.5)),
                ),
              );
            }

            final plans = snap.data ?? [];

            if (plans.isEmpty) {
              return _EmptyState(textColor: textColor, gold: gold);
            }

            final saved =
                plans.where((p) => p.status == SoloPlanStatus.saved).toList();
            final completed = plans
                .where((p) => p.status == SoloPlanStatus.completed)
                .toList();

            return TabBarView(
              children: [
                _PlanList(
                    plans: plans,
                    textColor: textColor,
                    gold: gold,
                    isDark: isDark),
                _PlanList(
                    plans: saved,
                    textColor: textColor,
                    gold: gold,
                    isDark: isDark),
                _PlanList(
                    plans: completed,
                    textColor: textColor,
                    gold: gold,
                    isDark: isDark),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Plan list ─────────────────────────────────────────────────────────────────

class _PlanList extends StatelessWidget {
  final List<SavedPlan> plans;
  final Color textColor;
  final Color gold;
  final bool isDark;

  const _PlanList({
    required this.plans,
    required this.textColor,
    required this.gold,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return _EmptyState(textColor: textColor, gold: gold);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: plans.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _PlanCard(
        plan: plans[i],
        textColor: textColor,
        gold: gold,
        isDark: isDark,
      ),
    );
  }
}

// ── Plan card ─────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final SavedPlan plan;
  final Color textColor;
  final Color gold;
  final bool isDark;

  const _PlanCard({
    required this.plan,
    required this.textColor,
    required this.gold,
    required this.isDark,
  });

  String get _statusLabel {
    return switch (plan.status) {
      SoloPlanStatus.active => 'Active',
      SoloPlanStatus.saved => 'Saved',
      SoloPlanStatus.completed => 'Completed',
    };
  }

  Color _statusColor(BuildContext context) {
    return switch (plan.status) {
      SoloPlanStatus.active => gold,
      SoloPlanStatus.saved =>
        isDark ? AppColors.darkText.withValues(alpha: 0.5) : Colors.grey,
      SoloPlanStatus.completed => Colors.green.shade600,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cardColor =
        isDark ? AppColors.darkPatternOverlay : const Color(0xFFFFFEF0);
    final isActive = plan.status == SoloPlanStatus.active;

    return GestureDetector(
      onTap: isActive
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ActiveTourScreen(plan: plan)),
              )
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: isActive
              ? Border.all(color: gold, width: 1.5)
              : Border.all(color: Colors.transparent),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: gold.withValues(alpha: 0.15),
                    blurRadius: 12,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      fontFamily: 'Marcellus',
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(context).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(context),
                    ),
                  ),
                ),
              ],
            ),
            if (plan.tagline.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                plan.tagline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: textColor.withValues(alpha: 0.55),
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: plan.progress,
                minHeight: 6,
                backgroundColor: gold.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(
                  plan.status == SoloPlanStatus.completed
                      ? Colors.green.shade600
                      : gold,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.place_outlined,
                    size: 14, color: textColor.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text(
                  plan.areas.join(', '),
                  style: TextStyle(
                      fontSize: 12,
                      color: textColor.withValues(alpha: 0.5)),
                ),
                const Spacer(),
                Text(
                  '${plan.completedStops}/${plan.totalStops} stops',
                  style: TextStyle(
                    fontSize: 12,
                    color: plan.status == SoloPlanStatus.completed
                        ? Colors.green.shade600
                        : gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            if (isActive) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  // Delete active tour
                  OutlinedButton(
                    onPressed: () => _deletePlan(context, isActive: true),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Icon(Icons.delete_outline_rounded,
                        color: Colors.red.shade700, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ActiveTourScreen(plan: plan)),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded,
                          size: 16, color: Colors.white),
                      label: const Text(
                        'Continue Tour',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (plan.status == SoloPlanStatus.saved) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _deletePlan(context, isActive: false),
                      style: OutlinedButton.styleFrom(
                        side:
                            BorderSide(color: Colors.red.withValues(alpha: 0.4)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        'Delete',
                        style: TextStyle(
                            color: Colors.red.shade700, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _startTour(context),
                      icon: const Icon(Icons.play_arrow_rounded,
                          size: 16, color: Colors.white),
                      label: const Text(
                        'Start Tour',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _startTour(BuildContext context) async {
    try {
      await SoloPlanService.instance.startTour(plan.id);
      final started = plan.copyWith(
        status: SoloPlanStatus.active,
        startedAt: DateTime.now(),
      );
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ActiveTourScreen(plan: started)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not start tour. Try again.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _deletePlan(BuildContext context, {bool isActive = false}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete plan?'),
        content: Text(
          isActive
              ? 'This tour is in progress. Deleting it will discard all your progress and cannot be undone.'
              : 'This cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await SoloPlanService.instance.deletePlan(plan.id);
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final Color textColor;
  final Color gold;

  const _EmptyState({required this.textColor, required this.gold});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_outlined, size: 56, color: gold.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'No plans yet',
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Marcellus',
              color: textColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Save a curated trip or create your own\nto see it here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: textColor.withValues(alpha: 0.4),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.explore_outlined,
                size: 18, color: Colors.white),
            label: const Text(
              'Browse Trips',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: gold,
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
