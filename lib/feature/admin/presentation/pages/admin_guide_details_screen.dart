import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lost_in_egypt/core/widgets/shimmer_avatar.dart';
import 'package:lost_in_egypt/core/widgets/shimmer_image.dart';
import 'package:lost_in_egypt/feature/auth/domain/entities/user_entity.dart';

class AdminGuideDetailsScreen extends StatelessWidget {
  final UserEntity applicant;
  final Function(UserEntity) onApprove;
  final Function(UserEntity) onReject;

  const AdminGuideDetailsScreen({
    super.key,
    required this.applicant,
    required this.onApprove,
    required this.onReject,
  });

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(10.r),
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => Icon(Icons.error, color: Colors.white, size: 50.r),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docs = applicant.guideDocuments;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Applicant Details'),
        backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFF714611),
        foregroundColor: isDark ? Colors.white : Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Info
            Container(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              padding: EdgeInsets.all(20.r),
              child: Column(
                children: [
                  ShimmerAvatar(
                    url: applicant.profileImageUrl,
                    radius: 50.r,
                    iconSize: 50.r,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    '${applicant.firstName} ${applicant.lastName}',
                    style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: const Color(0xFF714611)),
                  ),
                  SizedBox(height: 8.h),
                  Text(applicant.email, style: TextStyle(fontSize: 16.sp, color: Colors.grey)),
                  if (applicant.phoneNumber.isNotEmpty)
                    Text('Phone: ${applicant.phoneNumber}', style: TextStyle(fontSize: 16.sp, color: Colors.grey)),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Details Card
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Card(
                color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                child: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('MOTA License', applicant.motaLicenseNumber),
                      const Divider(),
                      _buildDetailRow('Syndicate ID', applicant.syndicateNumber),
                      const Divider(),
                      _buildDetailRow('Languages', applicant.certifiedLanguages.isNotEmpty ? applicant.certifiedLanguages.join(', ') : 'None listed'),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 24.h),

            // Documents Grid
            if (docs.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text(
                  'Uploaded Documents',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: const Color(0xFF714611)),
                ),
              ),
              SizedBox(height: 12.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 12.h,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    String docType = docs.keys.elementAt(index);
                    String docUrl = docs[docType]!;

                    // Prettify the key
                    String label = docType.replaceAll('_', ' ').toUpperCase();

                    return GestureDetector(
                      onTap: () => _showImageDialog(context, docUrl),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ShimmerImage(
                                url: docUrl,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                                fallbackIcon: Icons.broken_image,
                                fallbackIconColor: Colors.grey,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(8.r),
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                              child: Text(
                                label,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 40.h),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onReject(applicant);
                  },
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text('Reject', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onApprove(applicant);
                  },
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('Approve', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
