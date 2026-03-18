import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lost_in_egypt/theme/theme.dart';

class AdminLanguageRequestsScreen extends StatelessWidget {
  const AdminLanguageRequestsScreen({Key? key}) : super(key: key);

  Future<void> _handleRequest(
      BuildContext context, DocumentSnapshot doc, bool isApproved) async {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final userId = data['userId'];
    final language = data['requestedLanguage'];

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Update the request document
      batch.update(doc.reference, {
        'status': isApproved ? 'approved' : 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // If approved, add the language to the user's certifiedLanguages array
      if (isApproved && userId != null && language != null) {
        final userRef =
            FirebaseFirestore.instance.collection('users').doc(userId);
        batch.update(userRef, {
          'certifiedLanguages': FieldValue.arrayUnion([language])
        });
      }

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isApproved
              ? 'Language request approved!'
              : 'Language request rejected.'),
          backgroundColor: isApproved ? Colors.green : Colors.red,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update request: \$e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (ctx, error, stackTrace) => const Center(
                child: Icon(Icons.broken_image, color: Colors.white, size: 50),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Requests'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('admin_requests')
            .where('status', isEqualTo: 'pending')
            .where('type', isEqualTo: 'language_addition')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading requests.'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No pending language requests.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = (doc.data() as Map<String, dynamic>?) ?? {};
              final userId = data['userId']?.toString() ?? 'Unknown User';
              final language = data['requestedLanguage']?.toString() ?? 'Unknown Language';

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Card(
                      margin: EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  String userName = 'Unknown User';
                  String guideLicenseUrl = '';
                  String idCardUrl = '';

                  if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
                    final userData = (userSnapshot.data!.data() as Map<String, dynamic>?) ?? {};
                    String first = userData['firstName']?.toString() ?? '';
                    String last = userData['lastName']?.toString() ?? '';
                    userName = "$first $last".trim();
                    if (userName.isEmpty) userName = 'Unknown User';
                    
                    // Check guideDocuments map first (newer schema)
                    if (userData.containsKey('guideDocuments') && userData['guideDocuments'] != null && userData['guideDocuments'] is Map) {
                      final docsMap = userData['guideDocuments'] as Map;
                      guideLicenseUrl = docsMap['motaLicense']?.toString() ?? '';
                      idCardUrl = docsMap['syndicateCard']?.toString() ?? '';
                    }
                    
                    // Fallback to top-level fields (older schema or testing)
                    if (guideLicenseUrl.isEmpty) {
                      guideLicenseUrl = userData['motaLicense'] ?? userData['motaLicenseUrl'] ?? ''; 
                    }
                    if (idCardUrl.isEmpty) {
                      idCardUrl = userData['syndicateCard'] ?? userData['syndicateCardUrl'] ?? '';
                    }
                  }

                  return Card(
                    elevation: 2,
                    color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Requested Language: $language',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Guide: $userName',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'User ID: $userId',
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                          ),
                          const SizedBox(height: 16),
                          if (guideLicenseUrl.isNotEmpty || idCardUrl.isNotEmpty) ...[
                            const Text(
                              'Submitted Credentials:',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 120, // fixed height for images
                              child: Row(
                                children: [
                                  if (guideLicenseUrl.isNotEmpty)
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _showImageDialog(context, guideLicenseUrl),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(guideLicenseUrl, fit: BoxFit.cover),
                                        ),
                                      ),
                                    ),
                                  if (guideLicenseUrl.isNotEmpty && idCardUrl.isNotEmpty)
                                    const SizedBox(width: 8),
                                  if (idCardUrl.isNotEmpty)
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _showImageDialog(context, idCardUrl),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(idCardUrl, fit: BoxFit.cover),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _handleRequest(context, doc, false),
                                icon: const Icon(Icons.close, color: Colors.red),
                                label: const Text('Reject',
                                    style: TextStyle(color: Colors.red)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () => _handleRequest(context, doc, true),
                                icon: const Icon(Icons.check, color: Colors.white),
                                label: const Text('Approve',
                                    style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
