import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lost_in_egypt/l10n/app_localizations.dart';

enum ReportType {
  user,
  guide,
  tour,
  post,
  comment
}

class ReportModel {
  final String id;
  final String reporterId;
  final ReportType reportedItemType;
  final String reportedItemId;
  final String? reportedItemOwnerId; // To easily ban/warn the owner
  final String reason;
  final String? description;
  final DateTime timestamp;
  final String status; // pending, dismissed, resolved

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.reportedItemType,
    required this.reportedItemId,
    this.reportedItemOwnerId,
    required this.reason,
    this.description,
    required this.timestamp,
    this.status = 'pending',
  });

  factory ReportModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      reporterId: data['reporterId'] ?? '',
      reportedItemType: _parseReportType(data['reportedItemType'] ?? ''),
      reportedItemId: data['reportedItemId'] ?? '',
      reportedItemOwnerId: data['reportedItemOwnerId'],
      reason: data['reason'] ?? 'Unknown',
      description: data['description'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'reportedItemType': reportedItemType.name,
      'reportedItemId': reportedItemId,
      'reportedItemOwnerId': reportedItemOwnerId,
      'reason': reason,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
      'status': status,
    };
  }

  static ReportType _parseReportType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'user':
        return ReportType.user;
      case 'guide':
        return ReportType.guide;
      case 'tour':
        return ReportType.tour;
      case 'post':
        return ReportType.post;
      case 'comment':
        return ReportType.comment;
      default:
        return ReportType.post; // Fallback
    }
  }

  // Predefined reasons per type
  static List<String> getReasonsForType(ReportType type) {
    switch (type) {
      case ReportType.user:
      case ReportType.guide:
        return [
          'Impersonation',
          'Fake Account',
          'Harassment or Bullying',
          'Inappropriate Profile Content',
          'Scam or Fraud',
          'Other'
        ];
      case ReportType.post:
      case ReportType.comment:
        return [
          'Spam or Ads',
          'Hate Speech',
          'False Information',
          'Explicit Content',
          'Harassment',
          'Other'
        ];
      case ReportType.tour:
        return [
          'Scam or Fraud',
          'Unsafe Location/Activity',
          'Inaccurate Description',
          'Fake Reviews',
          'Overpriced/Hidden Fees',
          'Other'
        ];
    }
  }
}

/// Localized display label for a report reason. The `reason` argument is the
/// English canonical value returned by [ReportModel.getReasonsForType] — that
/// value is what gets persisted to Firestore and read by admins (who may be in
/// any locale), so it stays English; only the radio-tile display is localized.
/// Mirrors the value-stays-English / display-localized resolver pattern.
String reportReasonLabel(AppLocalizations l10n, String reason) {
  switch (reason) {
    case 'Impersonation':
      return l10n.reportReasonImpersonation;
    case 'Fake Account':
      return l10n.reportReasonFakeAccount;
    case 'Harassment or Bullying':
      return l10n.reportReasonHarassmentBullying;
    case 'Inappropriate Profile Content':
      return l10n.reportReasonInappropriateProfile;
    case 'Scam or Fraud':
      return l10n.reportReasonScamFraud;
    case 'Other':
      return l10n.reportReasonOther;
    case 'Spam or Ads':
      return l10n.reportReasonSpamAds;
    case 'Hate Speech':
      return l10n.reportReasonHateSpeech;
    case 'False Information':
      return l10n.reportReasonFalseInfo;
    case 'Explicit Content':
      return l10n.reportReasonExplicitContent;
    case 'Harassment':
      return l10n.reportReasonHarassment;
    case 'Unsafe Location/Activity':
      return l10n.reportReasonUnsafe;
    case 'Inaccurate Description':
      return l10n.reportReasonInaccurate;
    case 'Fake Reviews':
      return l10n.reportReasonFakeReviews;
    case 'Overpriced/Hidden Fees':
      return l10n.reportReasonOverpriced;
    default:
      return reason;
  }
}
