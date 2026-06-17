import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';
import 'package:lost_in_egypt/core/services/currency_controller.dart';
import 'package:lost_in_egypt/core/services/currency_service.dart';
import 'package:lost_in_egypt/core/services/locale_controller.dart';
import 'package:lost_in_egypt/core/services/recommendation_service.dart';
import 'package:lost_in_egypt/theme/theme_controller.dart';
import 'package:lost_in_egypt/feature/auth/data/models/user.dart';
import 'package:lost_in_egypt/feature/home/tabs/more/data/settings_repository.dart';
import '../../account/domain/badge_constants.dart';
import '../../camera/widgets/badge_unlock_dialog.dart';
import '../../account/widgets/scarab_overlay.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  final SettingsRepository _repository = SettingsRepository();
  UserModel? _currentUser;
  bool _isLoading = true;
  int _versionTapCount = 0;
  int _themeTapCount = 0;
  DateTime _lastThemeTap = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await _repository.fetchCurrentUser();
      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _onVersionTapped() {
    _versionTapCount++;
    if (_versionTapCount == 5) {
      if (_currentUser != null &&
          !_currentUser!.visitedLandmarks.contains('easter_egg_pharaoh')) {
        final newLandmarks =
            List<String>.from(_currentUser!.visitedLandmarks)
              ..add('easter_egg_pharaoh');
        _updateSetting('visitedLandmarks', newLandmarks);
        final badge = BadgeConstants.allBadges
            .firstWhere((b) => b.id == 'easter_egg_pharaoh');
        BadgeUnlockDialog.show(context, badge);
      }
      _versionTapCount = 0;
    }
  }

  static const List<String> _currencies = [
    'EGP', 'USD', 'EUR', 'GBP', 'SAR', 'AED', 'JOD',
    'QAR', 'KWD', 'OMR', 'BHD', 'JPY', 'INR', 'AUD', 'CAD', 'CHF',
  ];

  void _showCurrencyPicker() {
    final theme = Theme.of(context);
    final current = _currentUser?.preferredCurrency ?? 'EGP';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        // BottomSheet radius — not scaled per design convention
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ListView(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        children: _currencies
            .map((code) => ListTile(
                  title: Text(
                    code,
                    style: TextStyle(
                      fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                      fontSize: 16.sp,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  trailing: code == current
                      ? Icon(Icons.check, color: theme.colorScheme.primary)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    _updateSetting('currency', code);
                  },
                ))
            .toList(),
      ),
    );
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    if (_currentUser == null) return;

    final updatedUser = _currentUser!.copyWith(
      isNotificationsEnabled: key == 'notif' ? value : null,
      isDarkMode: key == 'theme' ? value : null,
      language: key == 'lang' ? value : null,
      preferredCurrency: key == 'currency' ? value : null,
      visitedLandmarks: key == 'visitedLandmarks' ? value : null,
      notifBookings: key == 'notif.bookings' ? value : null,
      notifCommunity: key == 'notif.community' ? value : null,
      notifReviews: key == 'notif.reviews' ? value : null,
      notifGuideUpdates: key == 'notif.guideUpdates' ? value : null,
      notifDailyDiscovery: key == 'notif.dailyDiscovery' ? value : null,
    );

    if (key == 'currency') {
      CurrencyController.setCurrency(value as String);
      CurrencyService.instance.invalidateCache();
    }

    if (key == 'lang') {
      // Flip the app locale live (RTL handled automatically for Arabic).
      LocaleController.setLanguage(value as String);
    }

    if (mounted) setState(() => _currentUser = updatedUser);
    await _repository.updateSetting(updatedUser, key, value);
  }

  Future<void> _resetTasteSignals() async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.settingsResetTasteSignalsTitle,
            style: const TextStyle(fontFamily: 'Marcellus', fontFamilyFallback: ['Cairo'])),
        content: Text(l.settingsResetTasteSignalsBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.commonCancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.commonReset,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await RecommendationService.resetTasteVector();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.settingsTasteSignalsReset),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.settingsTasteSignalsResetError),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final textColor = theme.colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;
    final patternOpacity = isDark ? 0.1 : 0.4;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: patternOpacity,
              child: Image.asset(
                "assets/pattern_comp.png",
                fit: BoxFit.cover,
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back_ios_new,
                            size: 20.r, color: textColor),
                      ),
                      Text(
                        l.settingsTitle,
                        style: TextStyle(
                          fontSize: 30.sp,
                          fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                          color: textColor.withValues(alpha: 0.75),
                        ),
                      ),
                      SizedBox(width: 24.w),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                              color: theme.colorScheme.primary),
                        )
                      : ListView(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          children: [
                            // Language
                            _buildTile(
                              icon: Icons.language_rounded,
                              title: l.settingsSelectLanguage,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    (_currentUser?.language ?? "English") ==
                                            "Arabic"
                                        ? l.languageArabic
                                        : l.languageEnglish,
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                  SizedBox(width: 2.w),
                                  Icon(Icons.keyboard_arrow_down_rounded,
                                      color: theme.colorScheme.primary,
                                      size: 20.r),
                                ],
                              ),
                              onTap: _currentUser == null
                                  ? null
                                  : () {
                                      _updateSetting(
                                        'lang',
                                        (_currentUser?.language ?? "English") ==
                                                "English"
                                            ? "Arabic"
                                            : "English",
                                      );
                                    },
                            ),
                            SizedBox(height: 16.h),

                            // Currency
                            _buildTile(
                              icon: Icons.currency_exchange_rounded,
                              title: l.settingsDisplayCurrency,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _currentUser?.preferredCurrency ?? 'EGP',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                  SizedBox(width: 2.w),
                                  Icon(Icons.keyboard_arrow_down_rounded,
                                      color: theme.colorScheme.primary,
                                      size: 20.r),
                                ],
                              ),
                              onTap: _currentUser == null
                                  ? null
                                  : _showCurrencyPicker,
                            ),
                            SizedBox(height: 16.h),

                            // Theme toggle
                            _buildTile(
                              icon: Icons.palette_outlined,
                              title: l.settingsTheme,
                              trailing: ValueListenableBuilder<ThemeMode>(
                                valueListenable: ThemeController.mode,
                                builder: (context, mode, _) {
                                  final isDarkNow = mode == ThemeMode.dark;
                                  return GestureDetector(
                                    onTap: () async {
                                      final newValue = !isDarkNow;
                                      final now = DateTime.now();
                                      if (now
                                              .difference(_lastThemeTap)
                                              .inMilliseconds <
                                          800) {
                                        _themeTapCount++;
                                        if (_themeTapCount >= 4) {
                                          _themeTapCount = 0;
                                          ScarabOverlay.show(context);
                                        }
                                      } else {
                                        _themeTapCount = 1;
                                      }
                                      _lastThemeTap = now;
                                      ThemeController.setDark(newValue);
                                      if (_currentUser != null) {
                                        await _updateSetting('theme', newValue);
                                      }
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      width: 60.w,
                                      height: 32.h,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        borderRadius:
                                            BorderRadius.circular(20.r),
                                        border: Border.all(
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            left: 6.w,
                                            top: 6.h,
                                            child: Icon(Icons.wb_sunny,
                                                size: 18.r,
                                                color: Colors.white),
                                          ),
                                          Positioned(
                                            right: 6.w,
                                            top: 6.h,
                                            child: Icon(
                                                Icons.nightlight_round,
                                                size: 18.r,
                                                color: Colors.white),
                                          ),
                                          AnimatedAlign(
                                            alignment: isDarkNow
                                                ? Alignment.centerRight
                                                : Alignment.centerLeft,
                                            duration: const Duration(
                                                milliseconds: 300),
                                            child: Container(
                                              margin: EdgeInsets.symmetric(
                                                  horizontal: 2.w),
                                              width: 26.r,
                                              height: 26.r,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 32.h),

                            // Debug Reset Button
                            _buildTile(
                              icon: Icons.warning_amber_rounded,
                              title: l.settingsResetBadges,
                              trailing: const SizedBox.shrink(),
                              iconColor: Colors.red,
                              iconBgColor: Colors.red.withValues(alpha: 0.12),
                              borderColor:
                                  Colors.red.withValues(alpha: 0.25),
                              onTap: _currentUser == null
                                  ? null
                                  : () {
                                      _updateSetting(
                                          'visitedLandmarks', <String>[]);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              l.settingsBadgesResetSuccess),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    },
                            ),
                            SizedBox(height: 12.h),

                            // Debug Reset Taste Vector
                            _buildTile(
                              icon: Icons.psychology_outlined,
                              title: l.settingsResetTasteSignals,
                              trailing: const SizedBox.shrink(),
                              iconColor: Colors.red,
                              iconBgColor: Colors.red.withValues(alpha: 0.12),
                              borderColor:
                                  Colors.red.withValues(alpha: 0.25),
                              onTap: _currentUser == null
                                  ? null
                                  : _resetTasteSignals,
                            ),
                            SizedBox(height: 32.h),

                            // Version / Easter Egg Trigger
                            Center(
                              child: GestureDetector(
                                onTap: _onVersionTapped,
                                child: Padding(
                                  padding: EdgeInsets.all(16.r),
                                  child: Text(
                                    l.settingsVersion('1.0.0'),
                                    style: TextStyle(
                                      color: textColor.withValues(alpha: 0.5),
                                      fontFamily: "Marcellus", fontFamilyFallback: const ['Cairo'],
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 32.h),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
    Color? iconColor,
    Color? iconBgColor,
    Color? borderColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final surface = theme.colorScheme.surface;

    final resolvedIconColor = iconColor ?? primary;
    final resolvedIconBg =
        iconBgColor ?? primary.withValues(alpha: isDark ? 0.2 : 0.12);
    final resolvedBorder =
        borderColor ?? primary.withValues(alpha: isDark ? 0.2 : 0.15);

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(16.r),
      clipBehavior: Clip.hardEdge,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          height: 64.h,
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: resolvedBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 38.r,
                height: 38.r,
                decoration: BoxDecoration(
                  color: resolvedIconBg,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: resolvedIconColor, size: 20.r),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: iconColor ?? onSurface.withValues(alpha: 0.88),
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
