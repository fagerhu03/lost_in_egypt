import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import '../data/model/community_post_model.dart';
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
          ? Center(child: Text('Sign in to view saved posts.', style: TextStyle(color: onSurface.withValues(alpha: 0.6))))
          : StreamBuilder<QuerySnapshot>(
              stream: GetIt.I<FirebaseFirestore>()
                  .collection('community_posts')
                  .where('savedBy', arrayContains: currentUid)
                  .limit(30)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.separated(
                    padding: EdgeInsets.all(12.r),
                    itemCount: 4,
                    separatorBuilder: (_, _) => SizedBox(height: 12.h),
                    itemBuilder: (_, _) => _buildSkeleton(surface, onSurface, isDark),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Something went wrong.', style: TextStyle(color: onSurface.withValues(alpha: 0.6))),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bookmark_border_rounded, size: 64.r, color: onSurface.withValues(alpha: 0.2)),
                        SizedBox(height: 16.h),
                        Text(
                          'No saved posts yet',
                          style: TextStyle(fontFamily: 'Marcellus', fontSize: 18.sp, color: onSurface.withValues(alpha: 0.5)),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Tap the bookmark icon on any post to save it here.',
                          style: TextStyle(fontSize: 13.sp, color: onSurface.withValues(alpha: 0.4)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final posts = docs.map((d) => CommunityPostModel.fromSnapshot(d)).toList()
                  ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 24.h),
                  itemCount: posts.length,
                  separatorBuilder: (_, _) => SizedBox(height: 12.h),
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
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            ShimmerLoadingWidget.circular(width: 38.r, height: 38.r),
            SizedBox(width: 10.w),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ShimmerLoadingWidget.rectangular(width: 120.w, height: 13.h),
              SizedBox(height: 5.h),
              ShimmerLoadingWidget.rectangular(width: 80.w, height: 10.h),
            ]),
          ]),
          SizedBox(height: 12.h),
          ShimmerLoadingWidget.rectangular(width: double.infinity, height: 13.h),
          SizedBox(height: 6.h),
          ShimmerLoadingWidget.rectangular(width: 200.w, height: 13.h),
        ],
      ),
    );
  }
}
