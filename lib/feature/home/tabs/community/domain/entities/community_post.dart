class CommunityPost {
  final String id;
  final String userId;
  final String userName;
  final String userUsername; // @handle
  final String userFlag;
  final String userAvatar;
  final String timeAgo;
  final String content;
  final int likes;
  final int dislikes;
  final int comments;
  final List<String> images;
  final String? locationName; // e.g., "Pyramids of Giza"
  final String? locationId;   // Google Places ID or Firestore place ID
  final double? locationLat;  // For map navigation
  final double? locationLng;
  final bool isLikedByMe;
  final bool isDislikedByMe;
  final bool isSavedByMe;     // For bookmarks
  final bool isVerifiedGuide;
  final bool isAdmin;
  final bool isPinned;
  final String category; // 'photos' | 'questions' | 'guides' | 'landmarks' | 'tips' | ''
  final int views;
  // Emoji reactions: e.g. {'😮': 3, '😄': 1}
  final Map<String, int> reactionCounts;
  // Which emoji this user reacted with, or null
  final String? myReaction;
  // Tagged event (from Event Details -> Post to Community)
  final String? taggedEventId;
  final String? taggedEventName;

  const CommunityPost({
    required this.id,
    required this.userId,
    required this.userName,
    this.userUsername = '',
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
    this.locationLat,
    this.locationLng,
    this.isLikedByMe = false,
    this.isDislikedByMe = false,
    this.isSavedByMe = false,
    this.isVerifiedGuide = false,
    this.isAdmin = false,
    this.isPinned = false,
    this.category = '',
    this.views = 0,
    this.reactionCounts = const {},
    this.myReaction,
    this.taggedEventId,
    this.taggedEventName,
  });
}
