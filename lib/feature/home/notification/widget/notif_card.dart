import 'package:flutter/material.dart';

class NotifCard extends StatelessWidget {
  final bool isRead;
  final String senderName;
  final String message;
  final String timeText;
  final String? avatarUrl;
  final VoidCallback onTap;
  final VoidCallback onAvatarTap;

  const NotifCard({
    super.key,
    required this.isRead,
    required this.senderName,
    required this.message,
    required this.timeText,
    required this.avatarUrl,
    required this.onTap,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    final unreadBorderColor =
        isDark ? primary.withValues(alpha: 0.35) : const Color(0xFFC79A00).withValues(alpha: 0.35);

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isRead ? Colors.transparent : unreadBorderColor,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onAvatarTap,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary.withValues(alpha: 0.12),
                  ),
                  child: ClipOval(
                    child: avatarUrl != null
                        ? Image.network(avatarUrl!, fit: BoxFit.cover)
                        : Icon(Icons.person,
                            color: onSurface.withValues(alpha: 0.65)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      senderName,
                      style: TextStyle(
                        fontFamily: "Marcellus",
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: onSurface.withValues(alpha: 0.87),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: TextStyle(
                        fontFamily: "Marcellus",
                        fontSize: 12,
                        color: onSurface.withValues(alpha: 0.65),
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
                            color: onSurface.withValues(alpha: 0.50),
                          ),
                        ),
                        const Spacer(),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: primary,
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
      ),
    );
  }
}
