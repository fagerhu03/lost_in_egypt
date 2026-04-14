import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/reports_repository.dart';
import '../models/report_model.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> submitReport(ReportModel report) async {
    await _firestore.collection('reports').add(report.toMap());
  }

  @override
  Future<List<ReportModel>> getReports({String? status}) async {
    Query query = _firestore.collection('reports');
    
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    query = query.orderBy('timestamp', descending: true);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => ReportModel.fromSnapshot(doc)).toList();
  }

  static const _validStatuses = {'pending', 'dismissed', 'resolved'};

  @override
  Future<void> updateReportStatus(String reportId, String newStatus) async {
    if (!_validStatuses.contains(newStatus)) {
      throw ArgumentError('Invalid report status "$newStatus". Must be one of: ${_validStatuses.join(', ')}');
    }
    await _firestore.collection('reports').doc(reportId).update({
      'status': newStatus,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteReportedContent(ReportModel report) async {
    switch (report.reportedItemType) {
      case ReportType.post:
        await _firestore.collection('community_posts').doc(report.reportedItemId).delete();
        break;
      case ReportType.comment:
        // reportedItemId must be in "postId_commentId" format.
        final separatorIndex = report.reportedItemId.indexOf('_');
        if (separatorIndex <= 0 || separatorIndex == report.reportedItemId.length - 1) {
          throw Exception(
            'Comment ID format invalid. Expected "postId_commentId", got: "${report.reportedItemId}"',
          );
        }
        final postId = report.reportedItemId.substring(0, separatorIndex);
        final commentId = report.reportedItemId.substring(separatorIndex + 1);
        await _firestore
            .collection('community_posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId)
            .delete();
        break;
      case ReportType.tour:
        await _firestore.collection('tours').doc(report.reportedItemId).delete();
        break;
      case ReportType.user:
      case ReportType.guide:
        await _banUser(report.reportedItemId);
        break;
    }
  }

  Future<void> _banUser(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'banned': true,
      'bannedAt': FieldValue.serverTimestamp(),
    });
  }
}
