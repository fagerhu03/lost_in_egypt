import 'package:flutter/material.dart';
import 'package:lost_in_egypt/feature/home/tabs/navigator/widget/account_menu_button.dart';
import 'package:lost_in_egypt/feature/home/tabs/more/presentation/settings_screen.dart';
import 'package:lost_in_egypt/feature/home/tabs/more/presentation/currency_converter_screen.dart';
import 'package:lost_in_egypt/feature/home/tabs/more/presentation/translator_screen.dart';
import 'package:lost_in_egypt/feature/home/tabs/more/data/settings_repository.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  final SettingsRepository _repository = SettingsRepository();
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = await _repository.fetchCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _profileImageUrl = user.profileImageUrl;
      });
    }
  }

  Future<void> _handleSignOut() async {
    await _repository.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;
    final patternOpacity = isDark ? 0.1 : 0.4;

    final bg = theme.scaffoldBackgroundColor;
    final surface = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: bg,
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
                errorBuilder: (c, o, s) => Container(),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const SizedBox(width: 44),
                      Expanded(
                        child: Center(
                          child: Text(
                            "More",
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w500,
                              color: textColor.withOpacity(0.75),
                              fontFamily: "Marcellus",
                            ),
                          ),
                        ),
                      ),
                      AccountMenuButton(
                        profileImageUrl: _profileImageUrl,
                        onSignOut: _handleSignOut,
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  _MoreTile(
                    title: "Currency",
                    surfaceColor: surface,
                    textColor: textColor,
                    trailingColor: textColor.withOpacity(0.75),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CurrencyConverterScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  _MoreTile(
                    title: "Settings",
                    surfaceColor: surface,
                    textColor: textColor,
                    trailingColor: textColor.withOpacity(0.75),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                      _loadUserProfile();
                    },
                  ),
                  const SizedBox(height: 12),

                  _MoreTile(
                    title: "Help",
                    surfaceColor: surface,
                    textColor: textColor,
                    trailingColor: textColor.withOpacity(0.75),
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),

                  _MoreTile(
                    title: "Translator",
                    surfaceColor: surface,
                    textColor: textColor,
                    trailingColor: textColor.withOpacity(0.75),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TranslatorScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  _MoreTile(
                    title: "Contact us",
                    trailing: Icons.keyboard_arrow_down,
                    surfaceColor: surface,
                    textColor: textColor,
                    trailingColor: textColor.withOpacity(0.75),
                    onTap: () {},
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final String title;
  final IconData trailing;
  final VoidCallback onTap;

  // Theme-driven colors
  final Color surfaceColor;
  final Color textColor;
  final Color trailingColor;

  const _MoreTile({
    required this.title,
    required this.onTap,
    required this.surfaceColor,
    required this.textColor,
    required this.trailingColor,
    this.trailing = Icons.chevron_right,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          // ✅ LIGHT SHADOW IN DARK MODE
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: textColor.withOpacity(0.85),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: "Marcellus",
              ),
            ),
            const Spacer(),
            Icon(trailing, color: trailingColor),
          ],
        ),
      ),
    );
  }
}