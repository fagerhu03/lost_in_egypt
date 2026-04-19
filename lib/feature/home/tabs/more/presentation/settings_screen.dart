import 'package:flutter/material.dart';
import 'package:lost_in_egypt/core/services/currency_controller.dart';
import 'package:lost_in_egypt/core/services/currency_service.dart';
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
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    try {
      final user = await _repository.fetchCurrentUser();
      if (!mounted) return;

      setState(() {
        _currentUser = user;
        _isLoading = false;
      });

      // IMPORTANT:
      // Do NOT apply theme here.
      // Theme is applied once in AuthGate (startup).
      // Otherwise, opening settings can change the app theme unexpectedly.
      //
      // ThemeController.setDark(user?.isDarkMode ?? false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _onVersionTapped() {
    _versionTapCount++;
    if (_versionTapCount == 5) {
      if (_currentUser != null && !_currentUser!.visitedLandmarks.contains('easter_egg_pharaoh')) {
        final newLandmarks = List<String>.from(_currentUser!.visitedLandmarks)..add('easter_egg_pharaoh');
        _updateSetting('visitedLandmarks', newLandmarks);
        
        final badge = BadgeConstants.allBadges.firstWhere((b) => b.id == 'easter_egg_pharaoh');
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: _currencies.map((code) => ListTile(
          title: Text(code, style: TextStyle(fontFamily: 'Marcellus', fontSize: 16, color: theme.colorScheme.onSurface)),
          trailing: code == current ? Icon(Icons.check, color: theme.colorScheme.primary) : null,
          onTap: () {
            Navigator.pop(context);
            _updateSetting('currency', code);
          },
        )).toList(),
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
    );

    if (key == 'currency') {
      CurrencyController.setCurrency(value as String);
      CurrencyService.instance.invalidateCache();
    }

    if (mounted) {
      setState(() {
        _currentUser = updatedUser;
      });
    }

    await _repository.updateSetting(updatedUser, key, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          size: 20,
                          color: textColor,
                        ),
                      ),
                      Text(
                        "Settings",
                        style: TextStyle(
                          fontSize: 30,
                          fontFamily: "Marcellus",
                          color: textColor.withOpacity(0.75),
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            // Language
                            _buildTile(
                              icon: Icons.language_rounded,
                              title: "Select Language",
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _currentUser?.language ?? "English",
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(Icons.keyboard_arrow_down_rounded,
                                      color: theme.colorScheme.primary, size: 20),
                                ],
                              ),
                              onTap: _currentUser == null
                                  ? null
                                  : () {
                                      _updateSetting(
                                        'lang',
                                        (_currentUser?.language ?? "English") == "English"
                                            ? "Arabic"
                                            : "English",
                                      );
                                    },
                            ),
                            const SizedBox(height: 16),

                            // Currency
                            _buildTile(
                              icon: Icons.currency_exchange_rounded,
                              title: "Display Currency",
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _currentUser?.preferredCurrency ?? 'EGP',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(Icons.keyboard_arrow_down_rounded,
                                      color: theme.colorScheme.primary, size: 20),
                                ],
                              ),
                              onTap: _currentUser == null ? null : _showCurrencyPicker,
                            ),
                            const SizedBox(height: 16),

                            // Notification master switch
                            _buildTile(
                              icon: Icons.notifications_outlined,
                              title: "Notifications",
                              trailing: Switch(
                                value: _currentUser?.isNotificationsEnabled ?? true,
                                onChanged: _currentUser == null
                                    ? null
                                    : (v) => _updateSetting('notif', v),
                                activeColor: Colors.white,
                                activeTrackColor: theme.colorScheme.primary,
                                inactiveThumbColor: theme.colorScheme.primary,
                                inactiveTrackColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Notification sub-preferences
                            ...[
                              (Icons.confirmation_number_rounded, 'Bookings & Tours', 'notif.bookings',
                                  _currentUser?.notifBookings ?? true),
                              (Icons.people_alt_rounded, 'Community', 'notif.community',
                                  _currentUser?.notifCommunity ?? true),
                              (Icons.star_rounded, 'Reviews', 'notif.reviews',
                                  _currentUser?.notifReviews ?? true),
                              (Icons.verified_user_rounded, 'Guide Updates', 'notif.guideUpdates',
                                  _currentUser?.notifGuideUpdates ?? true),
                            ].map((entry) {
                              final (icon, title, key, value) = entry;
                              final masterOn = _currentUser?.isNotificationsEnabled ?? true;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8, left: 12),
                                child: Opacity(
                                  opacity: masterOn ? 1.0 : 0.4,
                                  child: _buildTile(
                                    icon: icon,
                                    title: title,
                                    trailing: Switch(
                                      value: value,
                                      onChanged: masterOn && _currentUser != null
                                          ? (v) => _updateSetting(key, v)
                                          : null,
                                      activeColor: Colors.white,
                                      activeTrackColor: theme.colorScheme.primary,
                                      inactiveThumbColor: theme.colorScheme.primary,
                                      inactiveTrackColor: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 8),

                            // Theme
                            _buildTile(
                              icon: Icons.palette_outlined,
                              title: "Theme",
                              trailing: ValueListenableBuilder<ThemeMode>(
                                valueListenable: ThemeController.mode,
                                builder: (context, mode, _) {
                                  final isDarkNow = mode == ThemeMode.dark;
                                  return GestureDetector(
                                    onTap: () async {
                                      final newValue = !isDarkNow;
                                      final now = DateTime.now();
                                      if (now.difference(_lastThemeTap).inMilliseconds < 800) {
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
                                      duration: const Duration(milliseconds: 300),
                                      width: 60,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          const Positioned(
                                            left: 6, top: 6,
                                            child: Icon(Icons.wb_sunny, size: 18, color: Colors.white),
                                          ),
                                          const Positioned(
                                            right: 6, top: 6,
                                            child: Icon(Icons.nightlight_round, size: 18, color: Colors.white),
                                          ),
                                          AnimatedAlign(
                                            alignment: isDarkNow
                                                ? Alignment.centerRight
                                                : Alignment.centerLeft,
                                            duration: const Duration(milliseconds: 300),
                                            child: Container(
                                              margin: const EdgeInsets.symmetric(horizontal: 2),
                                              width: 26,
                                              height: 26,
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
                            const SizedBox(height: 32),

                            // Debug Reset Button
                            _buildTile(
                              icon: Icons.warning_amber_rounded,
                              title: "Reset Badges (Debug)",
                              trailing: const SizedBox.shrink(),
                              iconColor: Colors.red,
                              iconBgColor: Colors.red.withOpacity(0.12),
                              borderColor: Colors.red.withOpacity(0.25),
                              onTap: _currentUser == null
                                  ? null
                                  : () {
                                      _updateSetting('visitedLandmarks', <String>[]);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Badges successfully reset!"),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    },
                            ),
                            const SizedBox(height: 32),
                            
                            // Version / Easter Egg Trigger
                            Center(
                              child: GestureDetector(
                                onTap: _onVersionTapped,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    "Version 1.0.0",
                                    style: TextStyle(
                                      color: textColor.withValues(alpha: 0.5),
                                      fontFamily: "Marcellus",
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
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

  /// Unified tile matching the app-wide icon + title + trailing design.
  /// Pass [iconColor] / [iconBgColor] to override for special (e.g. red debug) tiles.
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
    final resolvedIconBg = iconBgColor ?? primary.withOpacity(isDark ? 0.2 : 0.12);
    final resolvedBorder = borderColor ?? primary.withOpacity(isDark ? 0.2 : 0.15);

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.hardEdge,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: resolvedBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: resolvedIconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: resolvedIconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: iconColor != null
                        ? iconColor
                        : onSurface.withOpacity(0.88),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Marcellus',
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