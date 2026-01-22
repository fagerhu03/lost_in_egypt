import 'package:flutter/material.dart';

class NotifCard extends StatelessWidget {
  final bool isRead;
  final String senderName;
  final String message;
  final String timeText;
  final String? avatarUrl;
  final VoidCallback onTap;

  const NotifCard({
    super.key,
    required this.isRead,
    required this.senderName,
    required this.message,
    required this.timeText,
    required this.avatarUrl,
    required this.onTap,
  });

  static const Color _card = Color(0xFFFBF7ED);
  static const Color _text = Color(0xFF7C6A4D);
  static const Color _chip = Color(0xFF4D5420);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
          ],
          border: Border.all(
            color: isRead ? Colors.transparent : const Color(0xFFC79A00).withOpacity(0.35),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _chip.withOpacity(0.12),
              ),
              child: ClipOval(
                child: avatarUrl != null
                    ? Image.network(avatarUrl!, fit: BoxFit.cover)
                    : Icon(Icons.person, color: _text.withOpacity(0.65)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    senderName,
                    style: const TextStyle(
                      fontFamily: "Marcellus",
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: TextStyle(
                      fontFamily: "Marcellus",
                      fontSize: 12,
                      color: Colors.black.withOpacity(0.65),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        timeText,
                        style: TextStyle(
                          fontFamily: "Marcellus",
                          fontSize: 11,
                          color: _text.withOpacity(0.70),
                        ),
                      ),
                      const Spacer(),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFC79A00),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
