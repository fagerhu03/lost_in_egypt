import '../../data/models/report_model.dart';

abstract class ReportsRepository {
  /// Submits a new report to the database
  Future<void> submitReport(ReportModel report);

  /// Fetches all reports, optionally filtered by status
  Future<List<ReportModel>> getReports({String? status});

  /// Updates the status of an existing report (e.g., to 'dismissed' or 'resolved')
  Future<void> updateReportStatus(String reportId, String newStatus);

  /// Helper to delete the underlying reported content
  Future<void> deleteReportedContent(ReportModel report);
}
