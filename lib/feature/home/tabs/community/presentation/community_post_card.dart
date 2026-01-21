import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/entities/community_post.dart';
import '../data/repositories/firebase_community_repository.dart';

class CommunityPostCard extends StatefulWidget {
  final CommunityPost post;
  final VoidCallback? onCommentTap;
  final bool isDetail;

  const CommunityPostCard({
    super.key, 
    required this.post, 
    this.onCommentTap,
    this.isDetail = false,
  });

  @override
  State<CommunityPostCard> createState() => _CommunityPostCardState();
}

class _CommunityPostCardState extends State<CommunityPostCard> {
  int _currentImageIndex = 0;
  final FirebaseCommunityRepository _repo = FirebaseCommunityRepository();

  // --- ACTIONS ---

  void _deletePost() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Post"),
        content: const Text("Are you sure? This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _repo.deletePost(widget.post.id);
              if (widget.isDetail && mounted) Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editPost() {
    final TextEditingController editController = TextEditingController(text: widget.post.content);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Post"),
        content: TextField(
          controller: editController,
          maxLines: 4,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              if (editController.text.trim().isNotEmpty) {
                await _repo.editPost(widget.post.id, editController.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _reportPost() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Report Post"),
        content: const Text("Is this content offensive or spam?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              _repo.reportPost(widget.post.id, "User Report");
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Report sent. Thank you.")));
            },
            child: const Text("Report", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";
    final bool isOwner = widget.post.userId == currentUid;
    
    final textDark = const Color(0xFF4A3D2E);
    final textMid = const Color(0xFF7A6A55);
    final activeColor = const Color(0xFFE6A44A);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEF0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFFEF0)),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: const Color(0xFF2E1F16),
                backgroundImage: (widget.post.userAvatar.isNotEmpty) 
                    ? NetworkImage(widget.post.userAvatar) 
                    : null,
                child: widget.post.userAvatar.isEmpty 
                    ? const Icon(Icons.person, size: 20, color: Color(0xFFE6A44A)) 
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.post.userName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: textDark, fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(widget.post.userFlag, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(widget.post.timeAgo, style: TextStyle(color: textMid, fontSize: 12)),
                  ],
                ),
              ),
              
              // ⭐ MENU (Delete, Edit, Report)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz_rounded, color: textMid),
                // 👇 THIS IS THE FIX: Ensure all 3 map to functions
                onSelected: (value) {
                  if (value == 'delete') _deletePost();
                  if (value == 'edit') _editPost();
                  if (value == 'report') _reportPost();
                },
                itemBuilder: (context) => [
                  if (isOwner) ...[
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text("Edit")]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text("Delete", style: TextStyle(color: Colors.red))]),
                    ),
                  ],
                  if (!isOwner)
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(children: [Icon(Icons.flag, color: Colors.orange, size: 18), SizedBox(width: 8), Text("Report")]),
                    ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 10),

          // Content
          Text(
            widget.post.content, 
            style: TextStyle(
              color: textDark, 
              fontWeight: FontWeight.w600,
              fontSize: 15,
              fontFamily: "Mako", // Using the font you requested
              height: 1.4,
            ),
          ),

          // Location Chip
          if (widget.post.locationName != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      widget.post.locationName!,
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

          // Images
          if (widget.post.images.isNotEmpty) ...[
            const SizedBox(height: 10),
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: widget.isDetail ? 400 : 220, 
                    width: double.infinity,
                    color: widget.isDetail ? Colors.black.withOpacity(0.03) : Colors.transparent,
                    child: PageView.builder(
                      itemCount: widget.post.images.length,
                      onPageChanged: (index) => setState(() => _currentImageIndex = index),
                      itemBuilder: (context, index) => Image.network(
                        widget.post.images[index], 
                        fit: widget.isDetail ? BoxFit.contain : BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.error)),
                      ),
                    ),
                  ),
                ),
                if (widget.post.images.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(widget.post.images.length, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 6,
                          width: _currentImageIndex == index ? 12 : 6,
                          decoration: BoxDecoration(
                            color: _currentImageIndex == index ? activeColor : Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 10),

          // Actions
          Row(
            children: [
              _ActionButton(
                icon: widget.post.isLikedByMe ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                value: widget.post.likes,
                color: widget.post.isLikedByMe ? activeColor : textMid,
                onTap: () => _repo.togglePostLike(widget.post.id, true),
              ),
              const SizedBox(width: 14),
              
              _ActionButton(
                icon: widget.post.isDislikedByMe ? Icons.thumb_down : Icons.thumb_down_alt_outlined,
                value: widget.post.dislikes,
                color: widget.post.isDislikedByMe ? Colors.red.shade400 : textMid,
                onTap: () => _repo.togglePostLike(widget.post.id, false),
              ),
              const SizedBox(width: 14),
              
              _ActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                value: widget.post.comments,
                color: textMid,
                onTap: widget.onCommentTap,
              ),
              
              const Spacer(),
              
              InkWell(
                onTap: () => _repo.toggleSavePost(widget.post.id, widget.post.isSavedByMe),
                child: Icon(
                  widget.post.isSavedByMe ? Icons.bookmark : Icons.bookmark_border,
                  color: widget.post.isSavedByMe ? activeColor : textMid,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, required this.value, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
          Text("$value", style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
        ],
      ),
    );
  }
}