import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lost_in_egypt/theme/theme.dart';

class AdminLanguageRequestsScreen extends StatelessWidget {
  const AdminLanguageRequestsScreen({Key? key}) : super(key: key);

  Future<void> _handleRequest(
      BuildContext context, DocumentSnapshot doc, bool isApproved) async {
    final data = doc.data() as Map<String, dynamic>;
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
              final data = doc.data() as Map<String, dynamic>;
              final userId = data['userId'] ?? 'Unknown User';
              final language = data['requestedLanguage'] ?? 'Unknown Language';

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
                        'Requested Language: \$language',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Optionally, wrap User ID in a FutureBuilder to fetch user's name if desired
                      Text(
                        'User ID: \$userId',
                        style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                      ),
                      const SizedBox(height: 16),
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
      ),
    );
  }
}
