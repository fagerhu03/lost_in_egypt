import 'package:flutter/material.dart';

class YourPlanScreen extends StatelessWidget {
  const YourPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final bg = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text("Membership", style: TextStyle(fontFamily: 'Marcellus')),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: onSurface,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // Current plan card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1A3040), const Color(0xFF0B1D26)]
                    : [const Color(0xFFFFF8DC), const Color(0xFFFCFBE8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primary.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.workspace_premium_rounded, color: primary, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      "Explorer — Free",
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'Marcellus',
                        color: primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Active",
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "Your current plan — enjoy all the core features of Lost in Egypt at no cost.",
                  style: TextStyle(fontSize: 13, color: onSurface.withValues(alpha: 0.65), height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Text(
            "What's included",
            style: TextStyle(
              fontSize: 17,
              fontFamily: 'Marcellus',
              fontWeight: FontWeight.w700,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 14),

          ...[
            (Icons.camera_alt_outlined, "AI Landmark Discovery", "Identify unlimited landmarks with your camera"),
            (Icons.auto_stories_outlined, "AI Historical Stories", "Hear captivating stories about every landmark you find"),
            (Icons.map_outlined, "Interactive Map", "Explore 500+ Egyptian landmarks with GPS and routing"),
            (Icons.tour_outlined, "Browse & Book Tours", "Browse guided tours and book with certified guides"),
            (Icons.emoji_events_outlined, "Badges & Gamification", "Earn badges as you explore more of Egypt"),
            (Icons.people_outline, "Community Feed", "Share discoveries and connect with fellow travellers"),
            (Icons.translate_outlined, "Translator", "Translate text using your camera in real-time"),
            (Icons.currency_exchange_outlined, "Currency Converter", "Convert between 16 currencies instantly"),
            (Icons.notifications_outlined, "Booking Notifications", "Get notified about your tour confirmations"),
          ].map((e) => _FeatureRow(
                icon: e.$1,
                title: e.$2,
                subtitle: e.$3,
                primary: primary,
                surface: surface,
                onSurface: onSurface,
                isDark: isDark,
              )),

          const SizedBox(height: 28),
          Divider(color: onSurface.withValues(alpha: 0.1)),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.rocket_launch_outlined, color: primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      "Coming soon",
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Marcellus',
                        color: onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "We're working on premium features including offline mode, "
                  "exclusive guided experiences, and advanced trip planning tools. "
                  "Stay tuned — and the core app will always remain free.",
                  style: TextStyle(
                    fontSize: 13,
                    color: onSurface.withValues(alpha: 0.65),
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color primary;
  final Color surface;
  final Color onSurface;
  final bool isDark;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primary,
    required this.surface,
    required this.onSurface,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: onSurface)),
                Text(subtitle,
                    style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.6), height: 1.4)),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
        ],
      ),
    );
  }
}
