import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/models/event_review_model.dart';
import '../../data/datasources/event_reviews_service.dart';
import '../../data/models/map_item_models.dart';

class AddEventReviewSheet extends StatefulWidget {
  final EventModel event;

  const AddEventReviewSheet({super.key, required this.event});

  static Future<void> show(BuildContext context, EventModel event) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEventReviewSheet(event: event),
    );
  }

  @override
  State<AddEventReviewSheet> createState() => _AddEventReviewSheetState();
}

class _AddEventReviewSheetState extends State<AddEventReviewSheet> {
  double _rating = 0.0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_rating == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Must be logged in to review');

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      final userName = userDoc.data()?['firstName'] ?? 'Explorer';
      final userImage = userDoc.data()?['profileImageUrl'] ?? '';

      final review = EventReviewModel(
        id: const Uuid().v4(),
        eventId: widget.event.id,
        userId: user.uid,
        rating: _rating,
        comment: _commentController.text.trim(),
        userName: userName,
        userImage: userImage,
        createdAt: DateTime.now(),
      );

      // We pass the local event's data as fallback so it can be upserted if missing
      await EventReviewsService.submitReview(review, widget.event.toMap());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF162529) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Write a Review',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                    color: textColor,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: textColor),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              'How was ${widget.event.title}?',
              style: TextStyle(
                fontSize: 16.sp,
                color: textColor.withValues(alpha: 0.8),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  iconSize: 40.r,
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1.0;
                    });
                  },
                );
              }),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share your experience (optional)',
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: textColor),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? SizedBox(
                        height: 24.r,
                        width: 24.r,
                        child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Submit',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
