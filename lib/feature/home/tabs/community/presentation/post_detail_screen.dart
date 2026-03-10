import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/entities/community_post.dart';
import '../data/model/community_post_model.dart';
import './community_post_card.dart';
import '../data/repositories/firebase_community_repository.dart';

class PostDetailScreen extends StatefulWidget {
  final CommunityPost post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseCommunityRepository _repository = FirebaseCommunityRepository();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";
  final FocusNode _focusNode = FocusNode();

  late Stream<DocumentSnapshot> _postStream;
  late Stream<QuerySnapshot> _commentsStream;

  @override
  void initState() {
    super.initState();
    _postStream = FirebaseFirestore.instance
        .collection('community_posts')
        .doc(widget.post.id)
        .snapshots();
    _commentsStream = FirebaseFirestore.instance
        .collection('community_posts')
        .doc(widget.post.id)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  void _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    
    _commentController.clear();
    _focusNode.unfocus();
    
    try {
      print('🚀 Submitting comment: $text');
      await _repository.addComment(widget.post.id, text);
      print('✅ Comment added successfully!');
    } catch (e, stacktrace) {
      print('❌ ERROR adding comment: $e');
      print(stacktrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    }
  }

  void _handleReply(String userName) {
    final tag = "@$userName ";
    final currentText = _commentController.text;
    _commentController.text = "$tag$currentText";
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );
    _focusNode.requestFocus();
  }

  void _deleteComment(String commentId) {
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final surface = theme.colorScheme.surface;
        final onSurface = theme.colorScheme.onSurface;

        return AlertDialog(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          title: Text("Delete Comment", style: TextStyle(color: onSurface)),
          content: Text(
            "Are you sure you want to delete this comment?",
            style: TextStyle(color: onSurface.withOpacity(0.8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Cancel",
                style: TextStyle(color: onSurface.withOpacity(0.7)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _repository.deleteComment(widget.post.id, commentId);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = theme.scaffoldBackgroundColor;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    final dividerColor = onSurface.withOpacity(0.12);
    final borderColor =
    (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.10 : 0.06);

    final cardShadow = BoxShadow(
      color: isDark
          ? Colors.white.withOpacity(0.12)
          : Colors.black.withOpacity(0.12),
      blurRadius: 18,
      spreadRadius: 2,
      offset: const Offset(0, 10),
    );

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(color: onSurface),
        title: Text("Thread", style: TextStyle(color: onSurface)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // MAIN POST (live updates)
                StreamBuilder<DocumentSnapshot>(
                  stream: _postStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return CommunityPostCard(post: widget.post, isDetail: true);
                    }
                    final livePost =
                    CommunityPostModel.fromSnapshot(snapshot.data!);
                    return CommunityPostCard(post: livePost, isDetail: true);
                  },
                ),

                const SizedBox(height: 14),
                Divider(color: dividerColor, height: 24),

                Text(
                  "Comments",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: onSurface.withOpacity(0.75),
                  ),
                ),
                const SizedBox(height: 10),

                // COMMENTS LIST
                StreamBuilder<QuerySnapshot>(
                  stream: _commentsStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(color: primary),
                      );
                    }

                    final rawComments = snapshot.data!.docs;

                    if (rawComments.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          "No comments yet.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: onSurface.withOpacity(0.55)),
                        ),
                      );
                    }

                    final List<QueryDocumentSnapshot> regularComments = [];
                    final List<QueryDocumentSnapshot> replies = [];

                    for (var doc in rawComments) {
                      final data = doc.data() as Map<String, dynamic>;
                      final text = (data['text'] ?? "") as String;
                      if (text.startsWith("@")) {
                        replies.add(doc);
                      } else {
                        regularComments.add(doc);
                      }
                    }

                    final List<QueryDocumentSnapshot> orderedComments = [];
                    for (var parent in regularComments) {
                      orderedComments.add(parent);
                      final parentData = parent.data() as Map<String, dynamic>;
                      final parentName = parentData['userName'] as String?;
                      if (parentName != null) {
                        final String replyPrefix = "@\$parentName ";
                        final repliesToThis = replies.where((r) {
                          final rData = r.data() as Map<String, dynamic>;
                          final rText = (rData['text'] ?? "") as String;
                          return rText.startsWith(replyPrefix);
                        }).toList();
                        orderedComments.addAll(repliesToThis);
                      }
                    }

                    // Add any orphaned replies
                    final handledReplies = orderedComments.where((c) => replies.contains(c)).toList();
                    for (var r in replies) {
                      if (!handledReplies.contains(r)) orderedComments.add(r);
                    }

                    return Column(
                      children: orderedComments.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final commentId = doc.id;
                        final ownerId = (data['userId'] ?? "") as String;

                        final List likes =
                        (data['likes'] is List) ? (data['likes'] as List) : [];
                        final List dislikes = (data['dislikes'] is List)
                            ? (data['dislikes'] as List)
                            : [];

                        final isLiked = likes.contains(_currentUid);
                        final isDisliked = dislikes.contains(_currentUid);

                        final text = (data['text'] ?? "") as String;
                        final isReply = text.startsWith("@");

                        return Container(
                          margin: EdgeInsets.only(
                            bottom: 12,
                            left: isReply ? 20 : 0,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                            boxShadow: [cardShadow],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: onSurface.withOpacity(0.08),
                                    backgroundImage: (data['userAvatar'] != null &&
                                        data['userAvatar'] != "")
                                        ? NetworkImage(data['userAvatar'])
                                        : null,
                                    child: (data['userAvatar'] == null ||
                                        data['userAvatar'] == "")
                                        ? Icon(Icons.person,
                                        size: 14, color: primary)
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    (data['userName'] ?? 'User') as String,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    (data['userFlag'] ?? '🇪🇬') as String,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const Spacer(),

                                  if (ownerId == _currentUid)
                                    PopupMenuButton<String>(
                                      icon: Icon(
                                        Icons.more_vert,
                                        size: 18,
                                        color: onSurface.withOpacity(0.55),
                                      ),
                                      color: surface,
                                      surfaceTintColor: Colors.transparent,
                                      onSelected: (value) {
                                        if (value == 'delete') {
                                          _deleteComment(commentId);
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete,
                                                  color: Colors.red, size: 18),
                                              SizedBox(width: 8),
                                              Text("Delete",
                                                  style: TextStyle(
                                                      color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              Text(
                                text,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: onSurface.withOpacity(0.92),
                                ),
                              ),
                              const SizedBox(height: 10),

                              Row(
                                children: [
                                  // LIKE
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _repository.toggleCommentLike(
                                          widget.post.id, commentId, true),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4, horizontal: 4),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isLiked
                                                  ? Icons.thumb_up
                                                  : Icons.thumb_up_outlined,
                                              size: 16,
                                              color: isLiked
                                                  ? primary
                                                  : onSurface.withOpacity(0.45),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "${likes.length}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isLiked
                                                    ? primary
                                                    : onSurface.withOpacity(0.45),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 16),

                                  // DISLIKE
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _repository.toggleCommentLike(
                                          widget.post.id, commentId, false),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4, horizontal: 4),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isDisliked
                                                  ? Icons.thumb_down
                                                  : Icons.thumb_down_outlined,
                                              size: 16,
                                              color: isDisliked
                                                  ? Colors.red.shade400
                                                  : onSurface.withOpacity(0.45),
                                            ),
                                            const SizedBox(width: 4),
                                            if (dislikes.isNotEmpty)
                                              Text(
                                                "${dislikes.length}",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDisliked
                                                      ? Colors.red.shade400
                                                      : onSurface.withOpacity(0.45),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 16),

                                  // REPLY
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _handleReply(
                                          (data['userName'] ?? "User") as String),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Text(
                                          "Reply",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),

          // COMMENT INPUT
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: surface,
              border: Border(top: BorderSide(color: dividerColor)),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.06),
                  blurRadius: 14,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _focusNode,
                    style: TextStyle(color: onSurface),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitComment(),
                    decoration: InputDecoration(
                      hintText: "Write a comment...",
                      hintStyle: TextStyle(color: onSurface.withOpacity(0.45)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send_rounded, color: primary),
                  onPressed: _submitComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}