class CommunityPost {
  final String id;
  final String userId;
  final String userName;
  final String userFlag;
  final String userAvatar;
  final String timeAgo;
  final String content;
  final int likes;
  final int dislikes;
  final int comments;
  final List<String> images;
  final String? locationName; // e.g., "Pyramids of Giza"
  final String? locationId;   // To navigate there
  final bool isLikedByMe;
  final bool isDislikedByMe;
  final bool isSavedByMe;     // For bookmarks
  final bool isVerifiedGuide;

  const CommunityPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userFlag,
    this.userAvatar = "",
    required this.timeAgo,
    required this.content,
    required this.likes,
    required this.dislikes,
    required this.comments,
    this.images = const [],
    this.locationName,
    this.locationId,
    this.isLikedByMe = false,
    this.isDislikedByMe = false,
    this.isSavedByMe = false,
    this.isVerifiedGuide = false,
  });
}