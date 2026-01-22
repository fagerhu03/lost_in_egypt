import 'package:flutter/material.dart';

class EmptyNotificationsView extends StatelessWidget {
  final VoidCallback onTapSettings;

  const EmptyNotificationsView({super.key, required this.onTapSettings});

  static const Color _text = Color(0xFF7C6A4D);
  static const Color _chip = Color(0xFF4D5420);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _chip.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.mail_outline, color: _chip.withOpacity(0.85), size: 34),
          ),
          const SizedBox(height: 12),
          const Text(
            "No notifications yet",
            style: TextStyle(
              color: Colors.black87,
              fontFamily: "Marcellus",
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Your notifications will appear here once\nyou start getting them.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black.withOpacity(0.55),
              fontFamily: "Marcellus",
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTapSettings,
            child: Text(
              "Notification Settings",
              style: TextStyle(
                color: _chip.withOpacity(0.95),
                fontFamily: "Marcellus",
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
