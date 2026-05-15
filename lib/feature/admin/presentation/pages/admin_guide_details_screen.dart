import 'package:flutter/material.dart';
import 'package:lost_in_egypt/feature/auth/domain/entities/user_entity.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
        insetPadding: const EdgeInsets.all(10),
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white, size: 50),
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
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: CachedNetworkImageProvider(applicant.profileImageUrl),
                    child: null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${applicant.firstName} ${applicant.lastName}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF714611)),
                  ),
                  const SizedBox(height: 8),
                  Text(applicant.email, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  if (applicant.phoneNumber.isNotEmpty)
                    Text('Phone: ${applicant.phoneNumber}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Details Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('MOTA License', applicant.motaLicenseNumber ?? 'N/A'),
                      const Divider(),
                      _buildDetailRow('Syndicate ID', applicant.syndicateNumber ?? 'N/A'),
                      const Divider(),
                      _buildDetailRow('Languages', applicant.certifiedLanguages.isNotEmpty ? applicant.certifiedLanguages.join(', ') : 'None listed'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Documents Grid
            if (docs.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Uploaded Documents',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF714611)),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
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
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: CachedNetworkImage(
                                  imageUrl: docUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                  errorWidget: (context, url, err) => const Icon(Icons.broken_image, color: Colors.grey),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                              child: Text(
                                label,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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
