import 'package:flutter/material.dart';
import 'package:lost_in_egypt/theme/theme_controller.dart';
import 'package:lost_in_egypt/feature/auth/data/models/user.dart';
import 'package:lost_in_egypt/feature/home/tabs/more/data/settings_repository.dart';
import '../../account/domain/badge_constants.dart';
import '../../camera/widgets/badge_unlock_dialog.dart';
import '../../account/widgets/scarab_overlay.dart';
import 'saved_cards_screen.dart';

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

  Future<void> _updateSetting(String key, dynamic value) async {
    if (_currentUser == null) return;

    final updatedUser = _currentUser!.copyWith(
      isNotificationsEnabled: key == 'notif' ? value : null,
      isDarkMode: key == 'theme' ? value : null,
      language: key == 'lang' ? value : null,
      visitedLandmarks: key == 'visitedLandmarks' ? value : null,
    );

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
                              surfaceColor: surface,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Select Language",
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 16,
                                      fontFamily: "Marcellus",
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        _currentUser?.language ?? "English",
                                        style: TextStyle(
                                          color: textColor.withOpacity(0.7),
                                        ),
                                      ),
                                      Icon(
                                        Icons.keyboard_arrow_down,
                                        color: textColor,
                                      ),
                                    ],
                                  ),
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
                            const SizedBox(height: 16),

                            // Notification
                            _buildTile(
                              surfaceColor: surface,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Notification",
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.85),
                                      fontSize: 16,
                                      fontFamily: "Marcellus",
                                    ),
                                  ),
                                  Switch(
                                    value: _currentUser
                                            ?.isNotificationsEnabled ??
                                        true,
                                    onChanged: _currentUser == null
                                        ? null
                                        : (v) => _updateSetting('notif', v),
                                    activeColor: Colors.white,
                                    activeTrackColor:
                                        theme.colorScheme.primary,
                                    inactiveThumbColor:
                                        theme.colorScheme.primary,
                                    inactiveTrackColor: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Saved Card
                            _buildTile(
                              surfaceColor: surface,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Saved Cards",
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.85),
                                      fontSize: 16,
                                      fontFamily: "Marcellus",
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: textColor.withOpacity(0.4)),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedCardsScreen()));
                              },
                            ),
                            const SizedBox(height: 16),

                            // Theme (single source of truth: ThemeController.mode)
                            _buildTile(
                              surfaceColor: surface,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Theme",
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 16,
                                      fontFamily: "Marcellus",
                                    ),
                                  ),
                                  ValueListenableBuilder<ThemeMode>(
                                    valueListenable: ThemeController.mode,
                                    builder: (context, mode, _) {
                                      final isDarkNow =
                                          mode == ThemeMode.dark;

                                      return GestureDetector(
                                        onTap: () async {
                                          final newValue = !isDarkNow;

                                          // Easter Egg check: Scarab Swarm
                                          final now = DateTime.now();
                                          if (now.difference(_lastThemeTap).inMilliseconds < 800) {
                                            _themeTapCount++;
                                            if (_themeTapCount >= 4) {
                                              _themeTapCount = 0;
                                              ScarabOverlay.show(context);
                                            }
                                          } else {
                                            _themeTapCount = 1; // reset if too slow
                                          }
                                          _lastThemeTap = now;

                                          // 1) change theme instantly
                                          ThemeController.setDark(newValue);

                                          // 2) save to Firestore (if user exists)
                                          if (_currentUser != null) {
                                            await _updateSetting(
                                              'theme',
                                              newValue,
                                            );
                                          }
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                              milliseconds: 300),
                                          width: 60,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color:
                                                  textColor.withOpacity(0.4),
                                            ),
                                          ),
                                          child: Stack(
                                            children: [
                                              const Positioned(
                                                left: 6,
                                                top: 6,
                                                child: Icon(
                                                  Icons.wb_sunny,
                                                  size: 18,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const Positioned(
                                                right: 6,
                                                top: 6,
                                                child: Icon(
                                                  Icons.nightlight_round,
                                                  size: 18,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              AnimatedAlign(
                                                alignment: isDarkNow
                                                    ? Alignment.centerRight
                                                    : Alignment.centerLeft,
                                                duration: const Duration(
                                                    milliseconds: 300),
                                                child: Container(
                                                  margin: const EdgeInsets
                                                      .symmetric(horizontal: 2),
                                                  width: 26,
                                                  height: 26,
                                                  decoration:
                                                      const BoxDecoration(
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
                                ],
                              ),
                              ),
                            const SizedBox(height: 32),
                              
                            // Debug Reset Button
                            _buildTile(
                              surfaceColor: Colors.red.withValues(alpha: 0.1),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Colors.red),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "Reset Badges (Debug)",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 16,
                                      fontFamily: "Marcellus",
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
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

  Widget _buildTile({
    required Widget child,
    required Color surfaceColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.hardEdge,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}