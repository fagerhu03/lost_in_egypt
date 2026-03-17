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

  @override
  Future<void> updateReportStatus(String reportId, String newStatus) async {
    await _firestore.collection('reports').doc(reportId).update({
      'status': newStatus,
    });
  }

  @override
  Future<void> deleteReportedContent(ReportModel report) async {
    // Determine which collection to delete from based on the report type
    switch (report.reportedItemType) {
      case ReportType.post:
        await _firestore.collection('community_posts').doc(report.reportedItemId).delete();
        break;
      case ReportType.comment:
        // Complex because we need the postId to delete a nested comment.
        // We'll need to figure out the postId. If reportedItemId doesn't include it, we have to search or restructure.
        // For now, let's assume if it's a comment, reportedItemId might be "postId_commentId" or we need to handle it differently.
        // As a safeguard, we will only log an error here if the format isn't post_comment
        final parts = report.reportedItemId.split('_');
        if (parts.length >= 2) {
          final postId = parts[0];
          final commentId = parts[1];
          await _firestore
              .collection('community_posts')
              .doc(postId)
              .collection('comments')
              .doc(commentId)
              .delete();
        } else {
            throw Exception("Comment ID format invalid for deletion. Expected postId_commentId. Got: ${report.reportedItemId}");
        }
        break;
      case ReportType.tour:
        await _firestore.collection('tours').doc(report.reportedItemId).delete();
        break;
      case ReportType.user:
      case ReportType.guide:
        // Usually we don't 'delete' users directly here, but we could ban them.
        throw UnimplementedError('Cannot delete user profile directly through this method yet.');
    }
  }
}
