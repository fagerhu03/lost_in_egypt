import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/entities/community_post.dart';
import '../model/community_post_model.dart';
import '../../../../../../core/utils/image_utils.dart';

class FirebaseCommunityRepository {
  final CollectionReference _postsRef = FirebaseFirestore.instance.collection(
    'community_posts',
  );
  final CollectionReference _usersRef = FirebaseFirestore.instance.collection(
    'users',
  );
  final CollectionReference _reportsRef = FirebaseFirestore.instance.collection(
    'reports',
  );
  final CollectionReference _notificationsRef = FirebaseFirestore.instance
      .collection('notifications');

  // ✅ NEW: Track pagination cursor
  DocumentSnapshot? _lastDocument;
  static const int _pageSize = 20; // Load 20 posts per page

  // 1. GET POSTS - ✅ WITH PAGINATION
  Stream<List<CommunityPost>> getPostsStream({String sortBy = 'newest'}) {
    Query query = _postsRef;
    if (sortBy == 'popular') {
      query = query.orderBy('likesCount', descending: true);
    } else if (sortBy == 'most_discussed') {
      query = query.orderBy('commentsCount', descending: true);
    } else {
      query = query.orderBy('timestamp', descending: true);
    }

    // ✅ ADD LIMIT: Load only 20 posts initially
    return query.limit(_pageSize).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CommunityPostModel.fromSnapshot(doc))
          .toList();
    });
  }

  // ✅ NEW: Load more posts (pagination)
  Future<List<CommunityPost>> loadMorePosts({String sortBy = 'newest'}) async {
    if (_lastDocument == null) return [];

    Query query = _postsRef;
    if (sortBy == 'popular') {
      query = query.orderBy('likesCount', descending: true);
    } else if (sortBy == 'most_discussed') {
      query = query.orderBy('commentsCount', descending: true);
    } else {
      query = query.orderBy('timestamp', descending: true);
    }

    final snapshot = await query
        .startAfterDocument(_lastDocument!)
        .limit(_pageSize)
        .get();

    if (snapshot.docs.isNotEmpty) {
      _lastDocument = snapshot.docs.last;
    }

    return snapshot.docs
        .map((doc) => CommunityPostModel.fromSnapshot(doc))
        .toList();
  }

  // ✅ NEW: Reset pagination cursor
  void resetPagination() {
    _lastDocument = null;
  }

  // 2. GET PLACES (For tagging locations)
  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    // Simple implementation: Fetch all places and filter locally (Firestore doesn't do substring search natively)
    // For production, use Algolia or Typesense.
    final snapshot = await FirebaseFirestore.instance
        .collection('places')
        .get();
    final lowerQuery = query.toLowerCase();

    return snapshot.docs
        .where(
          (doc) => (doc.data()['title'] as String).toLowerCase().contains(
            lowerQuery,
          ),
        )
        .map(
          (doc) => {
            'id': doc.id,
            'title': doc.data()['title'],
            'image': doc.data()['imagePath'],
          },
        )
        .take(5)
        .toList();
  }

  // 3. ADD POST (With Location + Category)
  Future<void> addPost(
    String content,
    List<File> localImages, {
    String? locationName,
    String? locationId,
    double? locationLat,
    double? locationLng,
    String category = '',
    String? taggedEventId,
    String? taggedEventName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDetails = await _getUserDetails();
    List<String> imageUrls = await _uploadImages(localImages);

    await _postsRef.add({
      'userId': user.uid,
      'userName': userDetails['name'],
      'userUsername': userDetails['username'] ?? '',
      'userFlag': userDetails['flag'] ?? '🇪🇬',
      'userAvatar': userDetails['avatar'],
      'isVerifiedGuide': userDetails['isVerifiedGuide'] ?? false,
      'isAdmin': userDetails['isAdmin'] ?? false,
      'content': content,
      'images': imageUrls,
      'locationName': locationName,
      'locationId': locationId,
      if (locationLat != null) 'locationLat': locationLat,
      if (locationLng != null) 'locationLng': locationLng,
      'category': category,
      if (taggedEventId != null) 'taggedEventId': taggedEventId,
      if (taggedEventName != null) 'taggedEventName': taggedEventName,
      'likes': [],
      'dislikes': [],
      'savedBy': [],
      'likesCount': 0,
      'commentsCount': 0,
      'views': 0,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // 4. EDIT POST
  Future<void> editPost(String postId, String newContent) async {
    await _postsRef.doc(postId).update({
      'content': newContent,
      'isEdited': true, // Optional flag
    });
  }

  // 5. REPORT POST
  Future<void> reportPost(String postId, String reason) async {
    final user = FirebaseAuth.instance.currentUser;
    await _reportsRef.add({
      'postId': postId,
      'reporterId': user?.uid ?? 'anonymous',
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // 6. TOGGLE SAVE (Bookmark)
  Future<void> toggleSavePost(String postId, bool isSaved) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (isSaved) {
      // Is currently saved, so Unsave (remove)
      await _postsRef.doc(postId).update({
        'savedBy': FieldValue.arrayRemove([user.uid]),
      });
    } else {
      // Not saved, so Save (add)
      await _postsRef.doc(postId).update({
        'savedBy': FieldValue.arrayUnion([user.uid]),
      });
    }
  }

  // --- Keep Existing Helper Methods (getUserDetails, deletePost, comments, uploadImages) ---
  // Just ensuring they exist in your file as before.
  Future<Map<String, dynamic>> _getUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    String name = "Traveler";
    String username = "";
    String avatar = "";
    String flag = '🇪🇬';
    bool isGuide = false;
    bool isAdmin = false;
    if (user != null) {
      final userDoc = await _usersRef.doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        String first = data['firstName'] ?? "";
        String last = data['lastName'] ?? "";
        if (first.isNotEmpty || last.isNotEmpty) name = "$first $last".trim();
        username = data['username'] ?? "";
        avatar = data['profileImageUrl'] ?? "";
        isGuide = data['isVerifiedGuide'] ?? false;
        isAdmin = data['role'] == 'admin';
        // Prefer directly stored flag emoji; fall back to extracting from nationality string
        final storedFlag = data['nationalityFlag'] as String?;
        if (storedFlag != null && storedFlag.isNotEmpty) {
          flag = storedFlag;
        } else {
          final nat = (data['nationality'] ?? '').toString();
          flag = _extractFlag(nat);
        }
      }
    }
    return {'name': name, 'username': username, 'avatar': avatar, 'flag': flag, 'isVerifiedGuide': isGuide, 'isAdmin': isAdmin};
  }

  // Convert ISO country code (2 letters) to regional indicator emoji flag
  String _countryCodeToEmoji(String code) {
    final upper = code.toUpperCase();
    if (upper.length != 2) return '🏳️';
    final int first = upper.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final int second = upper.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCodes([first, second]);
  }

  /// Extracts a flag emoji from a nationality string.
  ///
  /// country_picker stores nationality as "🇺🇸 United States" — the flag emoji
  /// is always the first 4 UTF-16 code units (two regional-indicator surrogates,
  /// each with high surrogate 0xD83C). We extract it directly instead of trying
  /// to re-derive it from the country name.
  String _extractFlag(String nat) {
    if (nat.isEmpty) return '🇪🇬';

    // Regional indicator surrogate pairs always have high surrogate 0xD83C.
    // A flag emoji = 4 UTF-16 code units. Extract if present at position 0.
    if (nat.length >= 4 && nat.codeUnitAt(0) == 0xD83C) {
      return nat.substring(0, 4);
    }

    // Plain 2-letter ISO code (legacy)
    if (nat.length == 2) return _countryCodeToEmoji(nat);

    // Legacy name-based fallback for plain-text nationalities
    final lower = nat.toLowerCase();
    if (lower.contains('egypt')) return '🇪🇬';
    if (lower.contains('alger')) return '🇩🇿';
    if (lower.contains('morocco')) return '🇲🇦';
    if (lower.contains('tunisia')) return '🇹🇳';
    if (lower.contains('libya')) return '🇱🇾';
    if (lower.contains('sudan')) return '🇸🇩';
    if (lower.contains('saudi')) return '🇸🇦';
    if (lower.contains('united states') || lower.contains('usa')) return '🇺🇸';
    if (lower.contains('united kingdom') || lower.contains('britain')) return '🇬🇧';
    if (lower.contains('france')) return '🇫🇷';
    if (lower.contains('germany')) return '🇩🇪';
    if (lower.contains('canada')) return '🇨🇦';

    return '🇪🇬';
  }

  /// Refreshes user posts to ensure their `userFlag` matches current profile
  Future<void> refreshUserPostsFlag(String uid) async {
    if (uid.isEmpty) return;
    final userDoc = await _usersRef.doc(uid).get();
    if (!userDoc.exists) return;
    final data = userDoc.data() as Map<String, dynamic>;
    final storedFlag = data['nationalityFlag'] as String?;
    final flag = (storedFlag != null && storedFlag.isNotEmpty)
        ? storedFlag
        : _extractFlag((data['nationality'] ?? '').toString());

    final snapshot = await _postsRef.where('userId', isEqualTo: uid).get();
    if (snapshot.docs.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      final current = (doc.data() as Map<String, dynamic>)['userFlag'] ?? '';
      if (current != flag) batch.update(doc.reference, {'userFlag': flag});
    }
    await batch.commit();
  }

  Future<void> pinPost(String postId, {required bool pin}) async {
    await _postsRef.doc(postId).update({'isPinned': pin});
  }

  /// Toggle an emoji reaction on a post. Pass [emoji] = null to remove the
  /// current user's reaction entirely.
  Future<void> reactToPost(String postId, String emoji) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;
    final docRef = _postsRef.doc(postId);
    final doc = await docRef.get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final reactionsRaw = data['reactions'];
    String? currentReaction;
    if (reactionsRaw is Map) {
      for (final entry in reactionsRaw.entries) {
        if (entry.value is List && (entry.value as List).contains(uid)) {
          currentReaction = entry.key as String;
          break;
        }
      }
    }

    final Map<String, dynamic> updates = {};
    if (currentReaction == emoji) {
      // Toggling off the same reaction
      updates['reactions.$emoji'] = FieldValue.arrayRemove([uid]);
    } else {
      if (currentReaction != null) {
        updates['reactions.$currentReaction'] = FieldValue.arrayRemove([uid]);
      }
      updates['reactions.$emoji'] = FieldValue.arrayUnion([uid]);
    }
    await docRef.update(updates);
  }

  Future<void> deletePost(String postId) async {
    await _postsRef.doc(postId).delete();
  }

  Future<void> togglePostLike(String postId, bool isLike) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;
    final docRef = _postsRef.doc(postId);
    final doc = await docRef.get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final likes = List<String>.from(data['likes'] ?? []);
    final dislikes = List<String>.from(data['dislikes'] ?? []);

    if (isLike) {
      if (likes.contains(uid)) {
        await docRef.update({
          'likes': FieldValue.arrayRemove([uid]),
          'likesCount': FieldValue.increment(-1),
        });
      } else {
        await docRef.update({
          'likes': FieldValue.arrayUnion([uid]),
          'dislikes': FieldValue.arrayRemove([uid]),
          'likesCount': FieldValue.increment(1),
        });
        
        // Notify post owner of the like
        final postOwnerId = data['userId'];
        if (postOwnerId != null && postOwnerId != uid) {
          final userDetails = await _getUserDetails();
          final senderDisplayName = (userDetails['username'] as String).isNotEmpty
              ? '@${userDetails['username']}'
              : userDetails['name'] as String;
          await FirebaseFirestore.instance
              .collection('users')
              .doc(postOwnerId)
              .collection('notifications')
              .add({
            'recipientId': postOwnerId,
            'senderId': uid,
            'senderName': senderDisplayName,
            'senderAvatar': userDetails['avatar'],
            'title': 'New Like',
            'deepLinkTargetId': postId,
            'type': 'like_post', 
            'message': 'liked your post.',
            'isRead': false,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }
    } else {
      if (dislikes.contains(uid)) {
        await docRef.update({
          'dislikes': FieldValue.arrayRemove([uid]),
        });
      } else {
        await docRef.update({
          'dislikes': FieldValue.arrayUnion([uid]),
          'likes': FieldValue.arrayRemove([uid]),
          'likesCount': FieldValue.increment(likes.contains(uid) ? -1 : 0),
        });
      }
    }
  }

  Future<void> addComment(String postId, String text, {String? replyToId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Get Post Owner first (to notify them)
    final postDoc = await _postsRef.doc(postId).get();
    if (!postDoc.exists) return;
    final postOwnerId = postDoc['userId'];

    final userDetails = await _getUserDetails();

    // Add Comment
    final newDoc = await _postsRef.doc(postId).collection('comments').add({
      'userId': user.uid,
      'userName': userDetails['name'],
      'userUsername': userDetails['username'] ?? '',
      'userAvatar': userDetails['avatar'],
      'userFlag': userDetails['flag'] ?? '🇪🇬',
      'replyToId': replyToId,
      'text': text,
      'likes': [],
      'dislikes': [],
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _postsRef.doc(postId).update({
      'commentsCount': FieldValue.increment(1),
    });

    // ⭐ TRIGGER NOTIFICATION (If not commenting on own post)
    if (postOwnerId != user.uid) {
      final isReply = replyToId != null;
      final msg = isReply
          ? 'replied in your post: "${text.length > 30 ? text.substring(0, 30) + "..." : text}"'
          : 'commented on your post: "${text.length > 30 ? text.substring(0, 30) + "..." : text}"';
      final commentSenderDisplay = (userDetails['username'] as String).isNotEmpty
          ? '@${userDetails['username']}'
          : userDetails['name'] as String;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(postOwnerId)
          .collection('notifications')
          .add({
        'recipientId': postOwnerId,
        'senderId': user.uid,
        'senderName': commentSenderDisplay,
        'senderAvatar': userDetails['avatar'],
        'title': isReply ? 'New Reply' : 'New Comment',
        'deepLinkTargetId': '${postId}_${newDoc.id}',
        'type': 'comment', 
        'message': msg,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> editComment(String postId, String commentId, String newText) async {
    await _postsRef.doc(postId).collection('comments').doc(commentId).update({
      'text': newText,
      'isEdited': true,
    });
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _postsRef.doc(postId).collection('comments').doc(commentId).delete();
    await _postsRef.doc(postId).update({
      'commentsCount': FieldValue.increment(-1),
    });
  }

  Future<void> toggleCommentLike(
    String postId,
    String commentId,
    bool isLike,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    final docRef = _postsRef.doc(postId).collection('comments').doc(commentId);

    // 1. Transaction ensures we read the latest state before writing
    return FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final List likes = List.from(data['likes'] ?? []);
      final List dislikes = List.from(data['dislikes'] ?? []);

      if (isLike) {
        // TOGGLE LIKE
        if (likes.contains(uid)) {
          // Already liked -> UNLIKE
          transaction.update(docRef, {
            'likes': FieldValue.arrayRemove([uid]),
          });
        } else {
          // Not liked -> LIKE (and remove dislike if exists)
          transaction.update(docRef, {
            'likes': FieldValue.arrayUnion([uid]),
            'dislikes': FieldValue.arrayRemove([uid]),
          });
          
          // Notify comment owner
          final commentOwnerId = data['userId'];
          if (commentOwnerId != null && commentOwnerId != uid) {
            _getUserDetails().then((userDetails) {
              final likeNotifDisplay = (userDetails['username'] as String).isNotEmpty
                  ? '@${userDetails['username']}'
                  : userDetails['name'] as String;
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(commentOwnerId)
                  .collection('notifications')
                  .add({
                'recipientId': commentOwnerId,
                'senderId': uid,
                'senderName': likeNotifDisplay,
                'senderAvatar': userDetails['avatar'],
                'title': 'New Like',
                'deepLinkTargetId': '${postId}_${commentId}',
                'type': 'like_comment', 
                'message': 'liked your comment.',
                'isRead': false,
                'timestamp': FieldValue.serverTimestamp(),
              });
            });
          }
        }
      } else {
        // TOGGLE DISLIKE
        if (dislikes.contains(uid)) {
          // Already disliked -> UNDISLIKE
          transaction.update(docRef, {
            'dislikes': FieldValue.arrayRemove([uid]),
          });
        } else {
          // Not disliked -> DISLIKE (and remove like if exists)
          transaction.update(docRef, {
            'dislikes': FieldValue.arrayUnion([uid]),
            'likes': FieldValue.arrayRemove([uid]),
          });
        }
      }
    });
  }

  Future<List<String>> _uploadImages(List<File> images) async {
    List<String> urls = [];
    for (var image in images) {
      final file = await ImageUtils.compressImage(image) ?? image;
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = FirebaseStorage.instance.ref().child(
        'post_images/$fileName',
      );
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String url = await snapshot.ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  // GET NOTIFICATIONS STREAM
  Stream<QuerySnapshot> getNotificationsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return _notificationsRef
        .where('recipientId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // GET UNREAD NOTIFICATIONS COUNT
  Stream<int> getUnreadCountStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);

    return _notificationsRef
        .where('recipientId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // MARK NOTIFICATION AS READ
  Future<void> markNotificationAsRead(String notificationId) async {
    await _notificationsRef.doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllNotificationsAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Get all unread notifications
    final snapshot = await _notificationsRef
        .where('recipientId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) return;

    // 2. Batch update (Much faster than updating one by one)
    final batch = FirebaseFirestore.instance.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // DELETE A SINGLE NOTIFICATION
  Future<void> deleteNotification(String notificationId) async {
    await _notificationsRef.doc(notificationId).delete();
  }
}
