import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/core/constants/trip_options.dart';
import 'package:lost_in_egypt/core/models/solo_plan.dart';
import 'package:lost_in_egypt/core/services/solo_plan_service.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';
import '../../../../../../../theme/theme.dart';
import 'active_tour_screen.dart';

class MyPlansScreen extends StatelessWidget {
  const MyPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                Icon(Icons.chevron_left_rounded, color: textColor, size: 28.r),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            l10n.accountMyPlans,
            style: TextStyle(
              fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
              color: textColor,
              fontSize: 20.sp,
            ),
          ),
          bottom: TabBar(
            labelColor: gold,
            unselectedLabelColor: textColor.withValues(alpha: 0.5),
            indicatorColor: gold,
            tabs: [
              Tab(text: l10n.soloTabAll),
              Tab(text: l10n.soloStatusSaved),
              Tab(text: l10n.soloStatusCompleted),
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
                  l10n.soloCouldNotLoadPlans,
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
      padding: EdgeInsets.all(16.r),
      itemCount: plans.length,
      separatorBuilder: (_, _) => SizedBox(height: 12.h),
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

  String _statusLabel(AppLocalizations l10n) {
    return switch (plan.status) {
      SoloPlanStatus.active => l10n.soloStatusActive,
      SoloPlanStatus.saved => l10n.soloStatusSaved,
      SoloPlanStatus.completed => l10n.soloStatusCompleted,
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
    final l10n = AppLocalizations.of(context);
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
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18.r),
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
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _statusColor(context).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    _statusLabel(l10n),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(context),
                    ),
                  ),
                ),
              ],
            ),
            if (plan.tagline.isNotEmpty) ...[
              SizedBox(height: 4.h),
              Text(
                plan.tagline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: textColor.withValues(alpha: 0.55),
                ),
              ),
            ],
            SizedBox(height: 12.h),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: LinearProgressIndicator(
                value: plan.progress,
                minHeight: 6.h,
                backgroundColor: gold.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(
                  plan.status == SoloPlanStatus.completed
                      ? Colors.green.shade600
                      : gold,
                ),
              ),
            ),
            SizedBox(height: 8.h),

            Row(
              children: [
                Icon(Icons.place_outlined,
                    size: 14.r, color: textColor.withValues(alpha: 0.5)),
                SizedBox(width: 4.w),
                Text(
                  plan.areas.map((a) => tripAreaLabel(l10n, a)).join(', '),
                  style: TextStyle(
                      fontSize: 12.sp,
                      color: textColor.withValues(alpha: 0.5)),
                ),
                const Spacer(),
                Text(
                  l10n.soloPlanStopsProgress(plan.completedStops, plan.totalStops),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: plan.status == SoloPlanStatus.completed
                        ? Colors.green.shade600
                        : gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            if (isActive) ...[
              SizedBox(height: 12.h),
              Row(
                children: [
                  // Delete active tour
                  OutlinedButton(
                    onPressed: () => _deletePlan(context, isActive: true),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.withValues(alpha: 0.4)),
                      padding: EdgeInsets.symmetric(
                          vertical: 10.h, horizontal: 12.w),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: Icon(Icons.delete_outline_rounded,
                        color: Colors.red.shade700, size: 18.r),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ActiveTourScreen(plan: plan)),
                      ),
                      icon: Icon(Icons.play_arrow_rounded,
                          size: 16.r, color: Colors.white),
                      label: Text(
                        l10n.soloContinueTour,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (plan.status == SoloPlanStatus.saved) ...[
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _deletePlan(context, isActive: false),
                      style: OutlinedButton.styleFrom(
                        side:
                            BorderSide(color: Colors.red.withValues(alpha: 0.4)),
                        padding:
                            EdgeInsets.symmetric(vertical: 8.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r)),
                      ),
                      child: Text(
                        l10n.commonDelete,
                        style: TextStyle(
                            color: Colors.red.shade700, fontSize: 13.sp),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _startTour(context),
                      icon: Icon(Icons.play_arrow_rounded,
                          size: 16.r, color: Colors.white),
                      label: Text(
                        l10n.soloStartTour,
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.sp),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        padding:
                            EdgeInsets.symmetric(vertical: 8.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r)),
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
    final l10n = AppLocalizations.of(context);
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
          content: Text(l10n.soloCouldNotStart),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _deletePlan(BuildContext context, {bool isActive = false}) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.soloDeletePlanTitle),
        content: Text(
          isActive ? l10n.soloDeleteActiveBody : l10n.soloDeleteBody,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.commonCancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.commonDelete,
                  style: const TextStyle(color: Colors.red))),
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
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_outlined, size: 56.r, color: gold.withValues(alpha: 0.4)),
          SizedBox(height: 16.h),
          Text(
            l10n.soloNoPlansYet,
            style: TextStyle(
              fontSize: 18.sp,
              fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
              color: textColor.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            l10n.soloNoPlansSub,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: textColor.withValues(alpha: 0.4),
              height: 1.5,
            ),
          ),
          SizedBox(height: 22.h),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.explore_outlined,
                size: 18.r, color: Colors.white),
            label: Text(
              l10n.soloBrowseTrips,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: gold,
              padding:
                  EdgeInsets.symmetric(horizontal: 22.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
