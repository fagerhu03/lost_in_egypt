import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/core/services/recommendation_service.dart';

// 4 highest-signal questions from quiz_schema.json
const _kQuestions = [
  _Question(
    id: 'q1_era',
    prompt: 'Which eras of Egypt excite you most?',
    subtitle: 'Pick all that speak to you',
    maxSelect: 3,
    options: [
      _Option(id: 'era_pharaonic', label: 'Pharaonic / Ancient', icon: '🏺',
          types: ['archaeological_site', 'monument'], tags: ['ancient', 'pharaonic', 'historical']),
      _Option(id: 'era_islamic', label: 'Islamic Era', icon: '🕌',
          types: ['mosque', 'historical_landmark'], tags: ['islamic', 'religious', 'cultural']),
      _Option(id: 'era_coptic', label: 'Coptic Christian', icon: '✝️',
          types: ['church', 'historical_landmark'], tags: ['coptic', 'religious', 'cultural']),
      _Option(id: 'era_modern', label: 'Modern Egypt', icon: '🏙️',
          types: ['art_gallery', 'tourist_attraction'], tags: ['modern']),
    ],
  ),
  _Question(
    id: 'q2_activities',
    prompt: 'What do you love doing on trips?',
    subtitle: 'Choose as many as you like',
    maxSelect: 6,
    options: [
      _Option(id: 'act_museums', label: 'Museums & galleries', icon: '🖼️',
          types: ['museum', 'art_gallery'], tags: ['cultural', 'historical']),
      _Option(id: 'act_markets', label: 'Markets & bazaars', icon: '🛍️',
          types: ['market', 'shopping_mall'], tags: ['shopping', 'cultural']),
      _Option(id: 'act_food', label: 'Eating everything', icon: '🍽️',
          types: ['restaurant', 'cafe'], tags: ['food']),
      _Option(id: 'act_nature', label: 'Nature & outdoors', icon: '🌿',
          types: ['park', 'beach'], tags: ['natural', 'relaxation']),
      _Option(id: 'act_nightlife', label: 'Nightlife', icon: '🌙',
          types: ['night_club'], tags: ['entertainment', 'modern']),
      _Option(id: 'act_family', label: 'Family-friendly', icon: '👨‍👩‍👧',
          types: ['zoo', 'amusement_park', 'aquarium'], tags: ['family', 'entertainment']),
    ],
  ),
  _Question(
    id: 'q3_pace',
    prompt: "What's your travel style?",
    subtitle: 'Choose one',
    maxSelect: 1,
    options: [
      _Option(id: 'pace_chill', label: 'Chill & relaxing', icon: '🌴',
          types: ['park', 'spa', 'beach'], tags: ['relaxation']),
      _Option(id: 'pace_balanced', label: 'Balanced mix', icon: '⚖️',
          types: ['tourist_attraction'], tags: ['cultural']),
      _Option(id: 'pace_adventure', label: 'Pack every hour', icon: '🎒',
          types: ['tourist_attraction', 'historical_landmark'], tags: ['adventure', 'historical']),
    ],
  ),
  _Question(
    id: 'q7_depth',
    prompt: 'How deep into history do you want to go?',
    subtitle: 'Choose one',
    maxSelect: 1,
    options: [
      _Option(id: 'depth_surface', label: 'Highlights only', icon: '📸',
          types: ['tourist_attraction'], tags: []),
      _Option(id: 'depth_medium', label: 'A bit of context', icon: '📖',
          types: ['museum', 'historical_landmark'], tags: ['historical', 'cultural']),
      _Option(id: 'depth_deep', label: 'I want the full story', icon: '🏛️',
          types: ['museum', 'archaeological_site', 'monument'], tags: ['historical', 'ancient', 'cultural']),
    ],
  ),
];

class _Question {
  final String id;
  final String prompt;
  final String subtitle;
  final int maxSelect;
  final List<_Option> options;
  const _Question({
    required this.id,
    required this.prompt,
    required this.subtitle,
    required this.maxSelect,
    required this.options,
  });
}

class _Option {
  final String id;
  final String label;
  final String icon;
  final List<String> types;
  final List<String> tags;
  const _Option({
    required this.id,
    required this.label,
    required this.icon,
    required this.types,
    required this.tags,
  });
}

class TasteQuizScreen extends StatefulWidget {
  final VoidCallback onDone;

  const TasteQuizScreen({super.key, required this.onDone});

  @override
  State<TasteQuizScreen> createState() => _TasteQuizScreenState();
}

class _TasteQuizScreenState extends State<TasteQuizScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _submitting = false;

  // Selected option IDs per question index
  final List<Set<String>> _selections =
      List.generate(_kQuestions.length, (_) => {});

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _canAdvance {
    final q = _kQuestions[_currentPage];
    return _selections[_currentPage].isNotEmpty || q.id == 'q6_art';
  }

  void _toggleOption(int qIdx, _Option opt) {
    final q = _kQuestions[qIdx];
    setState(() {
      if (_selections[qIdx].contains(opt.id)) {
        _selections[qIdx].remove(opt.id);
      } else {
        if (q.maxSelect == 1) _selections[qIdx].clear();
        _selections[qIdx].add(opt.id);
      }
    });
  }

  void _next() {
    if (_currentPage < _kQuestions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);

    final answers = <Map<String, dynamic>>[];
    for (int i = 0; i < _kQuestions.length; i++) {
      final q = _kQuestions[i];
      for (final optId in _selections[i]) {
        final opt = q.options.firstWhere((o) => o.id == optId);
        answers.add({
          'optionId': opt.id,
          'types': opt.types,
          'tags': opt.tags,
        });
      }
    }

    // Fire-and-forget safe — errors logged inside the service
    await RecommendationService.applyQuizAnswers(answers);
    RecommendationService.warmStart();

    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final total = _kQuestions.length;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        image: DecorationImage(
          image: const AssetImage('assets/pattern_comp.png'),
          fit: BoxFit.cover,
          opacity: isDark ? 0.15 : 0.35,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ─────────────────────────────────────────────────
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Step ${_currentPage + 1} of $total',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: onSurface.withValues(alpha: 0.45),
                            fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _submitting ? null : widget.onDone,
                          child: Text(
                            'Skip quiz',
                            style: TextStyle(
                              color: onSurface.withValues(alpha: 0.4),
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.r),
                      child: LinearProgressIndicator(
                        value: (_currentPage + 1) / total,
                        minHeight: 4.h,
                        backgroundColor: primary.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(primary),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Top branding ────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Column(
                  children: [
                    Icon(Icons.auto_awesome, color: primary, size: 26.r),
                    SizedBox(height: 6.h),
                    Text(
                      'Personalise Your Journey',
                      style: TextStyle(
                        fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                        color: onSurface,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Help us show you places you\'ll love',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Question pages ──────────────────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _kQuestions.length,
                  itemBuilder: (_, i) =>
                      _QuestionPage(
                        question: _kQuestions[i],
                        selected: _selections[i],
                        onToggle: (opt) => _toggleOption(i, opt),
                        primary: primary,
                        onSurface: onSurface,
                        isDark: isDark,
                      ),
                ),
              ),

              // ── Next / Finish button ────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                    24.w, 12.h, 24.w, MediaQuery.of(context).padding.bottom + 20.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 54.h,
                  child: ElevatedButton(
                    onPressed: (_canAdvance && !_submitting) ? _next : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      disabledBackgroundColor: primary.withValues(alpha: 0.35),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      elevation: 0,
                    ),
                    child: _submitting
                        ? SizedBox(
                            width: 22.r,
                            height: 22.r,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            _currentPage == _kQuestions.length - 1
                                ? 'Start Exploring'
                                : 'Next',
                            style: TextStyle(
                              fontSize: 17.sp,
                              fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Single question page ──────────────────────────────────────────────────────

class _QuestionPage extends StatelessWidget {
  final _Question question;
  final Set<String> selected;
  final void Function(_Option) onToggle;
  final Color primary;
  final Color onSurface;
  final bool isDark;

  const _QuestionPage({
    required this.question,
    required this.selected,
    required this.onToggle,
    required this.primary,
    required this.onSurface,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),
          Text(
            question.prompt,
            style: TextStyle(
              fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: onSurface,
              height: 1.3,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            question.subtitle,
            style: TextStyle(
              fontSize: 13.sp,
              color: onSurface.withValues(alpha: 0.45),
            ),
          ),
          SizedBox(height: 20.h),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: question.options.map((opt) {
                  final isSelected = selected.contains(opt.id);
                  return GestureDetector(
                    onTap: () => onToggle(opt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 14.h),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primary.withValues(alpha: 0.14)
                            : (isDark
                                ? onSurface.withValues(alpha: 0.06)
                                : Colors.white.withValues(alpha: 0.75)),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: isSelected
                              ? primary
                              : onSurface.withValues(alpha: 0.12),
                          width: isSelected ? 1.8 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.18),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(opt.icon, style: TextStyle(fontSize: 20.sp)),
                          SizedBox(width: 8.w),
                          Text(
                            opt.label,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? primary
                                  : onSurface.withValues(alpha: 0.75),
                              fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
