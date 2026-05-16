import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  Future<void> _launch(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open link")),
        );
      }
    }
  }

  void _copyEmail(BuildContext context, String email) {
    Clipboard.setData(ClipboardData(text: email));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$email copied to clipboard"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;

    const supportEmail = "support@lostinegypt.app";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Contact Us", style: TextStyle(fontFamily: 'Marcellus')),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: onSurface,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const SizedBox(height: 16),
          Center(
            child: Icon(Icons.support_agent_rounded, size: 72, color: primary),
          ),
          const SizedBox(height: 16),
          Text(
            "We're here to help",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontFamily: 'Marcellus',
              color: onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Reach out through any of the channels below and we'll get back to you as soon as possible.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: onSurface.withValues(alpha: 0.65), height: 1.5),
          ),
          const SizedBox(height: 32),

          _ContactTile(
            icon: Icons.email_outlined,
            title: "Email Support",
            subtitle: supportEmail,
            surface: surface,
            onSurface: onSurface,
            primary: primary,
            onTap: () => _launch("mailto:$supportEmail", context),
            onLongPress: () => _copyEmail(context, supportEmail),
          ),
          const SizedBox(height: 12),
          _ContactTile(
            icon: Icons.chat_bubble_outline_rounded,
            title: "WhatsApp",
            subtitle: "Chat with us directly",
            surface: surface,
            onSurface: onSurface,
            primary: const Color(0xFF25D366),
            onTap: () => _launch("https://wa.me/201000000000", context),
          ),
          const SizedBox(height: 12),
          _ContactTile(
            icon: Icons.camera_alt_outlined,
            title: "Instagram",
            subtitle: "@lostinegypt.app",
            surface: surface,
            onSurface: onSurface,
            primary: const Color(0xFFE1306C),
            onTap: () => _launch("https://instagram.com/lostinegypt.app", context),
          ),
          const SizedBox(height: 32),
          Divider(color: onSurface.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            "Response times",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: 'Marcellus',
              color: onSurface,
            ),
          ),
          const SizedBox(height: 8),
          _ResponseRow(label: "Email", time: "Within 24 hours", onSurface: onSurface),
          _ResponseRow(label: "WhatsApp", time: "Within a few hours", onSurface: onSurface),
          _ResponseRow(label: "Instagram DMs", time: "1–2 business days", onSurface: onSurface),
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: gold.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: 'Marcellus',
                          color: onSurface,
                        )),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                          fontSize: 13,
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: onSurface.withValues(alpha: 0.7))),
          Text(time,
              style: TextStyle(
                fontSize: 14,
                color: onSurface,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}
