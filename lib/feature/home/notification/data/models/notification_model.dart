import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.recipientId,
    required super.title,
    required super.message,
    required super.type,
    required super.isRead,
    required super.timestamp,
    super.senderId,
    super.senderName,
    super.senderAvatar,
    super.deepLinkTargetId,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      recipientId: map['recipientId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Someone',
      senderAvatar: map['senderAvatar'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? map['body'] ?? '',
      type: map['type'] ?? 'info',
      deepLinkTargetId: map['deepLinkTargetId'],
      isRead: map['isRead'] ?? false,
      timestamp: map['timestamp'] != null 
          ? (map['timestamp'] as Timestamp).toDate() 
          : (map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'title': title,
      'message': message,
      'type': type,
      'deepLinkTargetId': deepLinkTargetId,
      'isRead': isRead,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
