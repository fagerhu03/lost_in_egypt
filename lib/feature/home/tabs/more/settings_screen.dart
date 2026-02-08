import 'package:flutter/material.dart';
import '../../../auth/data/models/user.dart';
import 'data/settings_repository.dart';

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
    // Refresh data when returning to this screen
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    try {
      final user = await _repository.fetchCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    if (_currentUser == null) return;

    // Optimistic Update locally
    final updatedUser = UserModel(
      id: _currentUser!.id,
      email: _currentUser!.email,
      firstName: _currentUser!.firstName,
      lastName: _currentUser!.lastName,
      birthDate: _currentUser!.birthDate,
      role: _currentUser!.role,
      profileImageUrl: _currentUser!.profileImageUrl,
      phoneNumber: _currentUser!.phoneNumber,
      nationality: _currentUser!.nationality,
      isNotificationsEnabled: key == 'notif'
          ? value
          : _currentUser!.isNotificationsEnabled,
      isDarkMode: key == 'theme' ? value : _currentUser!.isDarkMode,
      language: key == 'lang' ? value : _currentUser!.language,
      createdAt: _currentUser!.createdAt,
      phoneVerified: _currentUser!.phoneVerified,
      emailVerified: _currentUser!.emailVerified,
      instagramHandle: _currentUser!.instagramHandle,
      twitterHandle: _currentUser!.twitterHandle,
      bio: _currentUser!.bio,
      interests: _currentUser!.interests,
    );

    setState(() {
      _currentUser = updatedUser;
    });

    // Save to DB via Repository
    await _repository.updateSetting(_currentUser!, key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBE8),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
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
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 20,
                          color: Color(0xFF714611),
                        ),
                      ),
                      const Text(
                        "Settings",
                        style: TextStyle(
                          fontSize: 30,
                          fontFamily: "Marcellus",
                          color: Color(0x8C4D5420),
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // List
                Expanded(
                  child: _isLoading
                      ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFC79A00),
                    ),
                  )
                      : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildTile(
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Select Language",
                              style: TextStyle(
                                color: Color(0xFF714611),
                                fontSize: 16,
                                fontFamily: "Marcellus",
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  _currentUser?.language ?? "English",
                                  style: TextStyle(
                                    color: const Color(
                                      0xFF714611,
                                    ).withOpacity(0.7),
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Color(0xFF714611),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                          _updateSetting(
                            'lang',
                            _currentUser?.language == "English"
                                ? "Arabic"
                                : "English",
                          );
                        },
                      ),
                      const SizedBox(height: 16), // ✅ Gap

                      _buildTile(
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Notification",
                              style: TextStyle(
                                color: Color(0xFF7C6A4D),
                                fontSize: 16,
                                fontFamily: "Marcellus",
                              ),
                            ),
                            Switch(
                              value:
                              _currentUser?.isNotificationsEnabled ??
                                  true,
                              onChanged: (v) =>
                                  _updateSetting('notif', v),
                              activeColor: Colors.white,
                              activeTrackColor: const Color(0xFF5A3E18),
                              inactiveThumbColor: const Color(0xFF5A3E18),
                              inactiveTrackColor: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16), // ✅ Gap

                      _buildTile(
                        child: const Text(
                          "Saved Card",
                          style: TextStyle(
                            color: Color(0xFF7C6A4D),
                            fontSize: 16,
                            fontFamily: "Marcellus",
                          ),
                        ),
                      ),
                      const SizedBox(height: 16), // ✅ Gap

                      _buildTile(
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Theme",
                              style: TextStyle(
                                color: Color(0xFF714611),
                                fontSize: 16,
                                fontFamily: "Marcellus",
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _updateSetting(
                                'theme',
                                !(_currentUser?.isDarkMode ?? false),
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(
                                  milliseconds: 300,
                                ),
                                width: 60,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5A3E18),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF714611),
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
                                      alignment:
                                      (_currentUser?.isDarkMode ??
                                          false)
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      child: Container(
                                        margin:
                                        const EdgeInsets.symmetric(
                                          horizontal: 2,
                                        ),
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
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildTile({required Widget child, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFEF0), // ✅ UPDATED HERE
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
    );
  }
}