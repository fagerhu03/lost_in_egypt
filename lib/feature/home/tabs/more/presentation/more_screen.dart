import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lost_in_egypt/feature/home/tabs/navigator/widget/account_menu_button.dart';
import 'package:lost_in_egypt/feature/home/tabs/more/presentation/settings_screen.dart';
import 'package:lost_in_egypt/feature/home/tabs/more/presentation/currency_converter_screen.dart';
import 'package:lost_in_egypt/feature/home/tabs/more/presentation/translator_screen.dart';
import 'package:lost_in_egypt/feature/home/tabs/more/presentation/help_screen.dart';
import 'package:lost_in_egypt/feature/home/tabs/more/presentation/contact_us_screen.dart';
import 'package:lost_in_egypt/feature/home/tabs/more/presentation/sos_screen.dart';
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
      setState(() => _profileImageUrl = user.profileImageUrl);
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
                errorBuilder: (_, _, _) => Container(),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Column(
                children: [
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      SizedBox(width: 44.w),
                      Expanded(
                        child: Center(
                          child: Text(
                            "More",
                            style: TextStyle(
                              fontSize: 30.sp,
                              fontWeight: FontWeight.w500,
                              color: textColor.withValues(alpha: 0.75),
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
                  SizedBox(height: 18.h),

                  _MoreTile(
                    title: "Currency",
                    icon: Icons.currency_exchange_rounded,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CurrencyConverterScreen()),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  _MoreTile(
                    title: "Settings",
                    icon: Icons.settings_outlined,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      );
                      _loadUserProfile();
                    },
                  ),
                  SizedBox(height: 12.h),

                  _MoreTile(
                    title: "Help",
                    icon: Icons.help_outline_rounded,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HelpScreen()),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  _MoreTile(
                    title: "Translator",
                    icon: Icons.translate_rounded,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TranslatorScreen()),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  _MoreTile(
                    title: "Contact us",
                    icon: Icons.mail_outline_rounded,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ContactUsScreen()),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // SOS button
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SOSScreen()),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emergency_rounded,
                              color: Colors.white, size: 22.r),
                          SizedBox(width: 10.w),
                          Text(
                            "SOS — Emergency Numbers",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontFamily: 'Marcellus',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
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
  final IconData icon;
  final VoidCallback onTap;

  const _MoreTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final surface = theme.colorScheme.surface;

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(16.r),
      clipBehavior: Clip.hardEdge,
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Container(
          height: 64.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: primary.withValues(alpha: isDark ? 0.2 : 0.15),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Row(
            children: [
              Container(
                width: 38.r,
                height: 38.r,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: primary, size: 20.r),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.88),
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: "Marcellus",
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: primary.withValues(alpha: 0.6), size: 22.r),
            ],
          ),
        ),
      ),
    );
  }
}
