import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/entities/community_post.dart';
import '../data/model/community_post_model.dart'; // Needed for conversion
import './community_post_card.dart';
import '../data/repositories/firebase_community_repository.dart';

class PostDetailScreen extends StatefulWidget {
  final CommunityPost post; // Initial post data
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseCommunityRepository _repository = FirebaseCommunityRepository();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";
  final FocusNode _focusNode = FocusNode();

  void _submitComment() {
    if (_commentController.text.trim().isEmpty) return;
    _repository.addComment(widget.post.id, _commentController.text.trim());
    _commentController.clear();
    _focusNode.unfocus();
  }

  void _handleReply(String userName) {
    // Tag logic
    String currentText = _commentController.text;
    String tag = "@$userName ";
    _commentController.text = "$tag$currentText";
    _commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentController.text.length),
    );
    _focusNode.requestFocus();
  }

  void _deleteComment(String commentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Comment"),
        content: const Text("Are you sure you want to delete this comment?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _repository.deleteComment(widget.post.id, commentId);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF4A3D2E)),
        title: const Text("Thread", style: TextStyle(color: Color(0xFF4A3D2E))),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // 1. THE MAIN POST (Wrapped in Stream to update Likes live)
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('community_posts')
                      .doc(widget.post.id)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      // Fallback to passed data if loading or deleted
                      return CommunityPostCard(post: widget.post, isDetail: true);
                    }
                    // Convert live Firestore data to our Entity
                    final livePost = CommunityPostModel.fromSnapshot(
                      snapshot.data!,
                    );
                    return CommunityPostCard(post: livePost, isDetail: true);
                  },
                ),

                const Divider(height: 30),
                const Text(
                  "Comments",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7A6A55),
                  ),
                ),
                const SizedBox(height: 10),

                // 2. COMMENTS LIST
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('community_posts')
                      .doc(widget.post.id)
                      .collection('comments')
                      .orderBy('timestamp', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final comments = snapshot.data!.docs;

                    if (comments.isEmpty)
                      return const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          "No comments yet.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      );

                    return Column(
                      children: comments.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final commentId = doc.id;
                        final String ownerId = data['userId'] ?? "";

                        // Like/Dislike Arrays
                        final List likes = (data['likes'] is List)
                            ? data['likes']
                            : [];
                        final List dislikes = (data['dislikes'] is List)
                            ? data['dislikes']
                            : [];

                        final bool isLiked = likes.contains(_currentUid);
                        final bool isDisliked = dislikes.contains(_currentUid);

                        // Reply Detection (Visual Indent)
                        final bool isReply = (data['text'] as String? ?? "")
                            .startsWith("@");

                        return Container(
                          margin: EdgeInsets.only(
                            bottom: 12,
                            left: isReply
                                ? 20
                                : 0, // Indent if it looks like a reply
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEFE6D6)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: User Info + Menu
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: const Color(0xFFE6A44A),
                                    backgroundImage:
                                        (data['userAvatar'] != null &&
                                            data['userAvatar'] != "")
                                        ? NetworkImage(data['userAvatar'])
                                        : null,
                                    child:
                                        (data['userAvatar'] == null ||
                                            data['userAvatar'] == "")
                                        ? const Icon(
                                            Icons.person,
                                            size: 14,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    data['userName'] ?? 'User',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(data['userFlag'] ?? '🇪🇬', style: const TextStyle(fontSize: 12)),   
                                  const Spacer(),

                                  // ⭐ THREE DOTS MENU (Delete)
                                  if (ownerId == _currentUid)
                                    PopupMenuButton<String>(
                                      icon: const Icon(
                                        Icons.more_vert,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                      onSelected: (value) {
                                        if (value == 'delete')
                                          _deleteComment(commentId);
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                                size: 18,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                "Delete",
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              Text(
                                data['text'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF4A3D2E),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Actions Row
                              Row(
                                children: [
                                  // LIKE BUTTON
                                  GestureDetector(
                                    onTap: () => _repository.toggleCommentLike(widget.post.id, commentId, true),
                                    behavior: HitTestBehavior.opaque, // Ensures tap is caught
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isLiked ? Icons.thumb_up : Icons.thumb_up_outlined, 
                                            size: 16, 
                                            color: isLiked ? const Color(0xFFE6A44A) : Colors.grey
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "${likes.length}", 
                                            style: TextStyle(
                                              fontSize: 12, 
                                              color: isLiked ? const Color(0xFFE6A44A) : Colors.grey,
                                              fontWeight: FontWeight.bold
                                            )
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 16),
                                  
                                  // DISLIKE BUTTON
                                  GestureDetector(
                                    onTap: () => _repository.toggleCommentLike(widget.post.id, commentId, false),
                                    behavior: HitTestBehavior.opaque,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined, 
                                            size: 16, 
                                            color: isDisliked ? Colors.red.shade400 : Colors.grey
                                          ),
                                          const SizedBox(width: 4),
                                          // Only show number if > 0
                                          if (dislikes.isNotEmpty)
                                            Text(
                                              "${dislikes.length}", 
                                              style: TextStyle(
                                                fontSize: 12, 
                                                color: isDisliked ? Colors.red.shade400 : Colors.grey,
                                                fontWeight: FontWeight.bold
                                              )
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 16),

                                  // REPLY BUTTON
                                  GestureDetector(
                                    onTap: () => _handleReply(data['userName'] ?? "User"),
                                    behavior: HitTestBehavior.opaque,
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: const Text(
                                        "Reply", 
                                        style: TextStyle(
                                          fontSize: 12, 
                                          color: Color(0xFFE6A44A), 
                                          fontWeight: FontWeight.bold
                                        )
                                      ),
                                    ),
                                  ),
                                ],
                              )
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

          // 3. COMMENT INPUT
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEFE6D6))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _focusNode,
                    decoration: const InputDecoration(
                      hintText: "Write a comment...",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.send_rounded,
                    color: Color(0xFFE6A44A),
                  ),
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
