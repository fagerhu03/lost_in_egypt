import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/community_post.dart';

class CommunityPostModel extends CommunityPost {
  const CommunityPostModel({
    required super.id,
    required super.userId,
    required super.userName,
    required super.userFlag,
    required super.userAvatar,
    required super.timeAgo,
    required super.content,
    required super.likes,
    required super.dislikes,
    required super.comments,
    required super.images,
    super.locationName,
    super.locationId,
    required super.isLikedByMe,
    required super.isDislikedByMe,
    required super.isSavedByMe,
    required super.isVerifiedGuide,
    required this.timestamp,
  });

  final DateTime timestamp;

  factory CommunityPostModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";

    final DateTime date = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    
    // Time Logic
    final Duration diff = DateTime.now().difference(date);
    String timeLabel = "${diff.inHours}h ago";
    if (diff.inHours < 1) timeLabel = "${diff.inMinutes}m ago";
    if (diff.inDays > 0) timeLabel = "${diff.inDays}d ago";

    // Arrays
    final List likesList = (data['likes'] is List) ? data['likes'] : [];
    final List dislikesList = (data['dislikes'] is List) ? data['dislikes'] : [];
    final List savedList = (data['savedBy'] is List) ? data['savedBy'] : [];

    // Debug Logging
    if (data['userId'] == null || data['userId'] == '') {
      print("⚠️ CommunityPostModel: userId is NULL or empty for post ${doc.id}");
    }

    return CommunityPostModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Traveler',
      userFlag: data['userFlag'] ?? '🇪🇬',
      userAvatar: data['userAvatar'] ?? '',
      timeAgo: timeLabel,
      content: data['content'] ?? '',
      
      likes: likesList.length,
      dislikes: dislikesList.length,
      
      locationName: data['locationName'],
      locationId: data['locationId'],
      
      isLikedByMe: likesList.contains(currentUid),
      isDislikedByMe: dislikesList.contains(currentUid),
      isSavedByMe: savedList.contains(currentUid),
      isVerifiedGuide: data['isVerifiedGuide'] ?? false,

      comments: data['commentsCount'] ?? 0,
      images: List<String>.from(data['images'] ?? []), 
      timestamp: date,
    );
  }
}