import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  Future<void> _launch(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).contactCouldNotOpen)),
        );
      }
    }
  }

  void _copyEmail(BuildContext context, String email) {
    Clipboard.setData(ClipboardData(text: email));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).contactEmailCopied(email)),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;

    const supportEmail = "support@lostinegypt.app";

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.contactTitle, style: const TextStyle(fontFamily: 'Marcellus', fontFamilyFallback: ['Cairo'])),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: onSurface,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
        children: [
          SizedBox(height: 16.h),
          Center(
            child: Icon(Icons.support_agent_rounded, size: 72.r, color: primary),
          ),
          SizedBox(height: 16.h),
          Text(
            l10n.contactHeadline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22.sp,
              fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
              color: onSurface,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            l10n.contactSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.sp, color: onSurface.withValues(alpha: 0.65), height: 1.5),
          ),
          SizedBox(height: 32.h),

          _ContactTile(
            icon: Icons.email_outlined,
            title: l10n.contactEmailSupport,
            subtitle: supportEmail,
            surface: surface,
            onSurface: onSurface,
            primary: primary,
            onTap: () => _launch("mailto:$supportEmail", context),
            onLongPress: () => _copyEmail(context, supportEmail),
          ),
          SizedBox(height: 12.h),
          _ContactTile(
            icon: Icons.chat_bubble_outline_rounded,
            title: l10n.contactWhatsApp,
            subtitle: l10n.contactWhatsAppSubtitle,
            surface: surface,
            onSurface: onSurface,
            primary: const Color(0xFF25D366),
            onTap: () => _launch("https://wa.me/201000000000", context),
          ),
          SizedBox(height: 12.h),
          _ContactTile(
            icon: Icons.camera_alt_outlined,
            title: l10n.contactInstagram,
            subtitle: "@lostinegypt.app",
            surface: surface,
            onSurface: onSurface,
            primary: const Color(0xFFE1306C),
            onTap: () => _launch("https://instagram.com/lostinegypt.app", context),
          ),
          SizedBox(height: 32.h),
          Divider(color: onSurface.withValues(alpha: 0.1)),
          SizedBox(height: 16.h),
          Text(
            l10n.contactResponseTimes,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
              color: onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          _ResponseRow(label: l10n.contactRespEmail, time: l10n.contactTimeEmail, onSurface: onSurface),
          _ResponseRow(label: l10n.contactWhatsApp, time: l10n.contactTimeWhatsApp, onSurface: onSurface),
          _ResponseRow(label: l10n.contactRespInstagram, time: l10n.contactTimeInstagram, onSurface: onSurface),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color surface;
  final Color onSurface;
  final Color primary;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.surface,
    required this.onSurface,
    required this.primary,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).colorScheme.primary;
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: gold.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 38.r,
                height: 38.r,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: primary, size: 20.r),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                          color: onSurface,
                        )),
                    SizedBox(height: 2.h),
                    Text(subtitle,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: onSurface.withValues(alpha: 0.6),
                        )),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: gold),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResponseRow extends StatelessWidget {
  final String label;
  final String time;
  final Color onSurface;
  const _ResponseRow({required this.label, required this.time, required this.onSurface});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14.sp, color: onSurface.withValues(alpha: 0.7))),
          Text(time,
              style: TextStyle(
                fontSize: 14.sp,
                color: onSurface,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}
