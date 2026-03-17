import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  final String id;
  final String recipientId;
  final String senderId; // if applicable
  final String senderName;
  final String senderAvatar;
  final String title;
  final String message;
  final String type; // 'like', 'comment', 'booking', 'admin', 'reminder'
  final String? deepLinkTargetId; // e.g. postId or tourId
  final bool isRead;
  final DateTime timestamp;

  const NotificationEntity({
    required this.id,
    required this.recipientId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.timestamp,
    this.senderId = '',
    this.senderName = 'Someone',
    this.senderAvatar = '',
    this.deepLinkTargetId,
  });

  @override
  List<Object?> get props => [
        id,
        recipientId,
        senderId,
        senderName,
        senderAvatar,
        title,
        message,
        type,
        deepLinkTargetId,
        isRead,
        timestamp,
      ];
}
