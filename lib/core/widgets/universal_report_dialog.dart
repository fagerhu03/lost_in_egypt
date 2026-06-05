import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../feature/admin/data/models/report_model.dart';
import '../../feature/admin/domain/repositories/reports_repository.dart';
import '../utils/error_handler.dart';

class UniversalReportDialog extends StatefulWidget {
  final ReportType reportType;
  final String reportedItemId;
  final String? reportedItemOwnerId;
  final ReportsRepository repository; // Pass the repository or use GetIt
  
  const UniversalReportDialog({
    super.key,
    required this.reportType,
    required this.reportedItemId,
    this.reportedItemOwnerId,
    required this.repository,
  });

  static Future<void> show(
    BuildContext context, {
    required ReportType reportType,
    required String reportedItemId,
    String? reportedItemOwnerId,
    required ReportsRepository repository,
  }) {
    return showDialog(
      context: context,
      builder: (_) => UniversalReportDialog(
        reportType: reportType,
        reportedItemId: reportedItemId,
        reportedItemOwnerId: reportedItemOwnerId,
        repository: repository,
      ),
    );
  }

  @override
  State<UniversalReportDialog> createState() => _UniversalReportDialogState();
}

class _UniversalReportDialogState extends State<UniversalReportDialog> {
  String? _selectedReason;
  late final List<String> _reasons;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _reasons = ReportModel.getReasonsForType(widget.reportType);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to submit a report.')),
      );
      return;
    }

    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason for reporting.')),
      );
      return;
    }

    final description = _descriptionController.text.trim();
    if (description.length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Description must be 500 characters or fewer.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final report = ReportModel(
        id: '', // Firestore will generate this
        reporterId: user.uid,
        reportedItemType: widget.reportType,
        reportedItemId: widget.reportedItemId,
        reportedItemOwnerId: widget.reportedItemOwnerId,
        reason: _selectedReason!,
        description: description,
        timestamp: DateTime.now(),
      );

      await widget.repository.submitReport(report);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully. Thank you.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.handleGenericError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _getDialogTitle() {
    switch (widget.reportType) {
      case ReportType.user:
      case ReportType.guide:
        return 'Report User';
      case ReportType.tour:
        return 'Report Tour';
      case ReportType.post:
        return 'Report Post';
      case ReportType.comment:
        return 'Report Comment';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getDialogTitle(),
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              'Why are you reporting this?',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8.h),

            // Use Flexible and SingleChildScrollView so it doesn't overflow
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioGroup<String>(
                      groupValue: _selectedReason,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedReason = val;
                          });
                        }
                      },
                      child: Column(
                        children: _reasons.map((reason) {
                          return RadioListTile<String>(
                            title: Text(reason, style: TextStyle(fontSize: 14.sp)),
                            value: reason,
                            contentPadding: EdgeInsets.zero,
                            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                            activeColor: const Color(0xFFC79A00), // App primary color roughly
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Additional details (optional)',
                        hintStyle: TextStyle(fontSize: 14.sp),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        contentPadding: EdgeInsets.all(12.r),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.h),

            // Submit Button
            SizedBox(
              height: 48.h,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC79A00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        height: 20.r,
                        width: 20.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Submit Report',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
