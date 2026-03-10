import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../entities/notification_entity.dart';

abstract class NotificationsRepository {
  /// Stream of unread and read notifications for a specific user
  Stream<List<NotificationEntity>> getNotifications(String userId);

  /// Get the number of unread notifications for a badge icon
  Stream<int> getUnreadCount(String userId);

  /// Used by the system to post new notifications
  Future<Either<Failure, void>> sendNotification(NotificationEntity notification);

  /// Used by the UI when a user taps a notification
  Future<Either<Failure, void>> markAsRead(String notificationId);

  /// Mark all notifications as read for a specific user
  Future<Either<Failure, void>> markAllAsRead(String userId);

  /// Delete a notification securely by ID
  Future<Either<Failure, void>> deleteNotification(String notificationId);
}
