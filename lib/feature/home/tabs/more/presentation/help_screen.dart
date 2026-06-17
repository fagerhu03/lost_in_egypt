import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';

// ── Section model ─────────────────────────────────────────────────────────────
class _Section {
  final String title;
  final IconData icon;
  final List<_FAQ> faqs;
  const _Section({required this.title, required this.icon, required this.faqs});
}

class _FAQ {
  final String question;
  final String answer;
  const _FAQ({required this.question, required this.answer});
}

// ── Data ──────────────────────────────────────────────────────────────────────
List<_Section> _buildSections(AppLocalizations l10n) => [
  _Section(
    title: l10n.helpSecGettingStarted,
    icon: Icons.explore_outlined,
    faqs: [
      _FAQ(question: l10n.helpQDiscover, answer: l10n.helpADiscover),
      _FAQ(question: l10n.helpQBadges, answer: l10n.helpABadges),
      _FAQ(question: l10n.helpQGuide, answer: l10n.helpAGuide),
    ],
  ),
  _Section(
    title: l10n.helpSecMapPlaces,
    icon: Icons.map_outlined,
    faqs: [
      _FAQ(question: l10n.helpQSavePlaces, answer: l10n.helpASavePlaces),
      _FAQ(question: l10n.helpQRecognise, answer: l10n.helpARecognise),
    ],
  ),
  _Section(
    title: l10n.helpSecBookings,
    icon: Icons.confirmation_number_outlined,
    faqs: [
      _FAQ(question: l10n.helpQBook, answer: l10n.helpABook),
      _FAQ(question: l10n.helpQCancel, answer: l10n.helpACancel),
      _FAQ(question: l10n.helpQSecure, answer: l10n.helpASecure),
      _FAQ(question: l10n.helpQCurrency, answer: l10n.helpACurrency),
    ],
  ),
  _Section(
    title: l10n.helpSecCommunity,
    icon: Icons.people_outline_rounded,
    faqs: [
      _FAQ(question: l10n.helpQPost, answer: l10n.helpAPost),
      _FAQ(question: l10n.helpQReport, answer: l10n.helpAReport),
    ],
  ),
  _Section(
    title: l10n.helpSecAccount,
    icon: Icons.manage_accounts_outlined,
    faqs: [
      _FAQ(question: l10n.helpQUsername, answer: l10n.helpAUsername),
      _FAQ(question: l10n.helpQTheme, answer: l10n.helpATheme),
    ],
  ),
  _Section(
    title: l10n.helpSecOffline,
    icon: Icons.wifi_off_rounded,
    faqs: [
      _FAQ(question: l10n.helpQOfflineWhat, answer: l10n.helpAOfflineWhat),
      _FAQ(question: l10n.helpQOfflineNeed, answer: l10n.helpAOfflineNeed),
      _FAQ(question: l10n.helpQOfflineImprove, answer: l10n.helpAOfflineImprove),
    ],
  ),
  _Section(
    title: l10n.helpSecSafety,
    icon: Icons.shield_outlined,
    faqs: [
      _FAQ(question: l10n.helpQEmergency, answer: l10n.helpAEmergency),
    ],
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sections = _buildSections(l10n);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.helpFaqTitle, style: const TextStyle(fontFamily: 'Marcellus', fontFamilyFallback: ['Cairo'])),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: onSurface,
      ),
      body: ListView.builder(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 40.h),
        itemCount: sections.length,
        itemBuilder: (context, si) {
          final section = sections[si];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (si > 0) SizedBox(height: 24.h),
              // Section header
              Row(
                children: [
                  Container(
                    width: 34.r,
                    height: 34.r,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(section.icon, size: 18.r, color: primary),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    section.title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              ...section.faqs.asMap().entries.map((e) => Padding(
                    padding: EdgeInsets.only(bottom: e.key < section.faqs.length - 1 ? 8.h : 0),
                    child: _FaqTile(faq: e.value, primary: primary),
                  )),
            ],
          );
        },
      ),
    );
  }
}

// ── Tile ─────────────────────────────────────────────────────────────────────
class _FaqTile extends StatefulWidget {
  final _FAQ faq;
  final Color primary;
  const _FaqTile({required this.faq, required this.primary});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final gold = widget.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _expanded ? gold.withValues(alpha: 0.35) : gold.withValues(alpha: 0.12),
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.faq.question,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                        fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: gold,
                    size: 22.r,
                  ),
                ],
              ),
              if (_expanded) ...[
                SizedBox(height: 10.h),
                Text(
                  widget.faq.answer,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: onSurface.withValues(alpha: 0.75),
                    height: 1.6,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
