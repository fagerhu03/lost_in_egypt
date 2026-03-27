import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import '../data/model/community_post_model.dart';
import '../domain/entities/community_post.dart';
import 'community_post_card.dart';
import 'post_detail_screen.dart';
import '../../../../../core/widgets/shimmer_loading_widget.dart';

class SavedPostsScreen extends StatelessWidget {
  const SavedPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final currentUid = GetIt.I<FirebaseAuth>().currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: onSurface),
        title: Text(
          'Saved Posts',
          style: TextStyle(
            fontFamily: 'Marcellus',
            color: onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: currentUid.isEmpty
          ? Center(child: Text('Sign in to view saved posts.', style: TextStyle(color: onSurface.withOpacity(0.6))))
          : StreamBuilder<QuerySnapshot>(
              stream: GetIt.I<FirebaseFirestore>()
                  .collection('community_posts')
                  .where('savedBy', arrayContains: currentUid)
                  .limit(30)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: 4,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, __) => _buildSkeleton(surface, onSurface, isDark),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Something went wrong.', style: TextStyle(color: onSurface.withOpacity(0.6))),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bookmark_border_rounded, size: 64, color: onSurface.withOpacity(0.2)),
                        const SizedBox(height: 16),
                        Text(
                          'No saved posts yet',
                          style: TextStyle(fontFamily: 'Marcellus', fontSize: 18, color: onSurface.withOpacity(0.5)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the bookmark icon on any post to save it here.',
                          style: TextStyle(fontSize: 13, color: onSurface.withOpacity(0.4)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final posts = docs.map((d) => CommunityPostModel.fromSnapshot(d)).toList()
                  ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  itemCount: posts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return CommunityPostCard(
                      key: ValueKey(post.id),
                      post: post,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildSkeleton(Color surface, Color onSurface, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const ShimmerLoadingWidget.circular(width: 38, height: 38),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const ShimmerLoadingWidget.rectangular(width: 120, height: 13),
              const SizedBox(height: 5),
              const ShimmerLoadingWidget.rectangular(width: 80, height: 10),
            ]),
          ]),
          const SizedBox(height: 12),
          const ShimmerLoadingWidget.rectangular(width: double.infinity, height: 13),
          const SizedBox(height: 6),
          const ShimmerLoadingWidget.rectangular(width: 200, height: 13),
        ],
      ),
    );
  }
}
