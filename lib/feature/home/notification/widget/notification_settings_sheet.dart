import 'package:flutter/material.dart';

class NotificationSettingsSheet {
  static void open(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFBF7ED),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => const _SheetBody(),
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody();

  static const Color _text = Color(0xFF7C6A4D);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: _text.withOpacity(0.25),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "Notification Settings",
              style: TextStyle(
                color: _text,
                fontFamily: "Marcellus",
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Customize what you want to receive.",
              style: TextStyle(
                color: _text.withOpacity(0.7),
                fontFamily: "Marcellus",
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),

            const _SettingToggleTile(
              title: "Comments",
              subtitle: "Get notified when someone comments.",
              initialValue: true,
            ),
            SizedBox(height: 10),
            const _SettingToggleTile(
              title: "Likes",
              subtitle: "Get notified when someone likes your post.",
              initialValue: true,
            ),
            SizedBox(height: 10),
            const _SettingToggleTile(
              title: "Mentions",
              subtitle: "Get notified when someone mentions you.",
              initialValue: false,
            ),
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC79A00),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 6,
                ),
                child: const Text(
                  "Done",
                  style: TextStyle(
                    fontFamily: "Marcellus",
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingToggleTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool initialValue;

  const _SettingToggleTile({
    required this.title,
    required this.subtitle,
    required this.initialValue,
  });

  @override
  State<_SettingToggleTile> createState() => _SettingToggleTileState();
}

class _SettingToggleTileState extends State<_SettingToggleTile> {
  late bool _value = widget.initialValue;

  static const Color _text = Color(0xFF7C6A4D);
  static const Color _chip = Color(0xFF4D5420);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9EE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _chip.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: _text,
                    fontFamily: "Marcellus",
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    color: _text.withOpacity(0.65),
                    fontFamily: "Marcellus",
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _value,
            activeColor: _chip,
            onChanged: (v) => setState(() => _value = v),
          ),
        ],
      ),
    );
  }
}
