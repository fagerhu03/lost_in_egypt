import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_data_source.dart';
import '../models/notification_model.dart';
import 'package:uuid/uuid.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsDataSource dataSource;
  final Uuid uuid = const Uuid();

  NotificationsRepositoryImpl({required this.dataSource});

  @override
  Stream<List<NotificationEntity>> getNotifications(String userId) {
    return dataSource.getNotifications(userId);
  }

  @override
  Stream<int> getUnreadCount(String userId) {
    return dataSource.getUnreadCount(userId);
  }

  @override
  Future<Either<Failure, void>> markAllAsRead(String userId) async {
    try {
      await dataSource.markAllAsRead(userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String notificationId) async {
    try {
      await dataSource.markAsRead(notificationId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendNotification(NotificationEntity notification) async {
    try {
      final model = NotificationModel(
        id: notification.id.isEmpty ? uuid.v4() : notification.id,
        recipientId: notification.recipientId,
        senderId: notification.senderId,
        senderName: notification.senderName,
        senderAvatar: notification.senderAvatar,
        title: notification.title,
        message: notification.message,
        type: notification.type,
        deepLinkTargetId: notification.deepLinkTargetId,
        isRead: notification.isRead,
        timestamp: notification.timestamp,
      );

      await dataSource.sendNotification(model);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(String notificationId) async {
    try {
      await dataSource.deleteNotification(notificationId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
