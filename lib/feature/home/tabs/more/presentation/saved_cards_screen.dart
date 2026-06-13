import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lost_in_egypt/core/di/service_locator.dart';

class SavedCardsScreen extends StatefulWidget {
  const SavedCardsScreen({super.key});

  @override
  State<SavedCardsScreen> createState() => _SavedCardsScreenState();
}

class _SavedCardsScreenState extends State<SavedCardsScreen> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = sl<FirebaseAuth>().currentUser;
  }

  CollectionReference get _cardsRef =>
      sl<FirebaseFirestore>().collection('users').doc(_user!.uid).collection('savedCards');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Cards'),
        centerTitle: true,
      ),
      body: _user == null
          ? const Center(child: Text('Please log in'))
          : StreamBuilder<QuerySnapshot>(
              stream: _cardsRef.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.credit_card_off, size: 80.r, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                        SizedBox(height: 16.h),
                        Text(
                          'No saved cards yet',
                          style: TextStyle(fontSize: 18.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Cards are saved automatically after\nyour first successful payment.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.35)),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.all(20.r),
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final lastFour = data['lastFour'] ?? '••••';
                    final brand = data['brand'] ?? 'Card';
                    final isDefault = data['isDefault'] == true;

                    return Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF1E293B), const Color(0xFF334155)]
                              : [const Color(0xFF6366F1), const Color(0xFF818CF8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Brand icon
                              Row(
                                children: [
                                  Icon(
                                    brand.toLowerCase().contains('visa') ? Icons.credit_card : Icons.credit_card,
                                    color: Colors.white,
                                    size: 28.r,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    brand.toUpperCase(),
                                    style: TextStyle(color: Colors.white70, fontSize: 14.sp, fontWeight: FontWeight.w600, letterSpacing: 1),
                                  ),
                                ],
                              ),
                              if (isDefault)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text('DEFAULT', style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            '•••• •••• •••• $lastFour',
                            style: TextStyle(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.w500, letterSpacing: 3),
                          ),
                          SizedBox(height: 16.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                data['cardholderName'] ?? '',
                                style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                              ),
                              Row(
                                children: [
                                  if (!isDefault)
                                    _cardAction(Icons.star_border, 'Default', () => _setDefault(docs[index].id, docs)),
                                  SizedBox(width: 8.w),
                                  _cardAction(Icons.delete_outline, 'Remove', () => _deleteCard(docs[index].id)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _cardAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white60, size: 16.r),
            SizedBox(width: 4.w),
            Text(label, style: TextStyle(color: Colors.white60, fontSize: 12.sp)),
          ],
        ),
      ),
    );
  }

  Future<void> _setDefault(String cardId, List<QueryDocumentSnapshot> docs) async {
    final batch = sl<FirebaseFirestore>().batch();
    for (final doc in docs) {
      batch.update(doc.reference, {'isDefault': doc.id == cardId});
    }
    await batch.commit();
  }

  Future<void> _deleteCard(String cardId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Card'),
        content: const Text('This card will be removed from your saved payment methods.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _cardsRef.doc(cardId).delete();
    }
  }
}
