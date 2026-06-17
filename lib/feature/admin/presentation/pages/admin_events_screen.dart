import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:lost_in_egypt/core/constants/event_categories.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';
import 'admin_event_editor_screen.dart';

/// Admin panel for managing events stored in Firestore.
/// Admins can create, edit, toggle visibility, and delete events.
class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  String _filterSource = 'all'; // 'all', 'admin', 'eventbrite', 'curated'

  Stream<QuerySnapshot> get _stream {
    var query = FirebaseFirestore.instance
        .collection('events')
        .orderBy('importance', descending: true);

    if (_filterSource != 'all') {
      query = query.where('source', isEqualTo: _filterSource);
    }

    return query.limit(50).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final surface = theme.colorScheme.surface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        title: Text(
          'Manage Events',
          style: TextStyle(
            color: onSurface,
            fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        foregroundColor: onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download_outlined),
            tooltip: 'Import via Link',
            onPressed: () => _showLinkImportDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Create Event',
            onPressed: () => _navigateToEditor(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Source filter chips
          SizedBox(
            height: 48.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              children: [
                _filterChip('All', 'all', primary, onSurface, surface),
                _filterChip('Admin', 'admin', primary, onSurface, surface),
                _filterChip('Eventbrite', 'eventbrite', primary, onSurface, surface),
                _filterChip('Curated', 'curated', primary, onSurface, surface),
              ],
            ),
          ),
          // Events list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: primary),
                  );
                }

                final docs = snap.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_note, size: 64.r,
                            color: primary.withValues(alpha: 0.2)),
                        SizedBox(height: 16.h),
                        Text(
                          'No events found',
                          style: TextStyle(
                            color: onSurface.withValues(alpha: 0.5),
                            fontSize: 16.sp,
                            fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                          ),
                        ),
                        SizedBox(height: 8.h),
                        ElevatedButton.icon(
                          onPressed: () => _navigateToEditor(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Create First Event'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final event = EventModel.fromMap(data, docs[i].id);
                    return _AdminEventTile(
                      event: event,
                      docId: docs[i].id,
                      primary: primary,
                      onSurface: onSurface,
                      surface: surface,
                      onEdit: () => _navigateToEditor(context, event: event, docId: docs[i].id),
                      onDelete: () => _confirmDelete(context, docs[i].id, event.title),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditor(context),
        backgroundColor: primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _filterChip(String label, String value, Color primary, Color onSurface, Color surface) {
    final isSelected = _filterSource == value;
    return Padding(
      padding: EdgeInsetsDirectional.only(end: 8.w),
      child: GestureDetector(
        onTap: () => setState(() => _filterSource = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: isSelected ? primary : surface,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isSelected ? primary : onSurface.withValues(alpha: 0.15),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : onSurface.withValues(alpha: 0.7),
              fontSize: 12.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToEditor(BuildContext context, {EventModel? event, String? docId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminEventEditorScreen(event: event, docId: docId),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event?'),
        content: Text('Are you sure you want to delete "$title"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('events').doc(docId).delete();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"$title" deleted')),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }

  void _showLinkImportDialog(BuildContext context) {
    final urlCtrl = TextEditingController();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cloud_download, color: primary),
            SizedBox(width: 8.w),
            const Text('Import via Link'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste an Eventbrite or Passboard event URL to import it automatically.',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 13.sp,
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: urlCtrl,
              decoration: InputDecoration(
                hintText: 'https://...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                prefixIcon: const Icon(Icons.link),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final url = urlCtrl.text.trim();
              if (url.isEmpty) return;
              
              String functionName = '';
              if (url.contains('eventbrite.com') || url.contains('eventbrite.co')) {
                functionName = 'importEventbriteEvent';
              } else if (url.contains('passboard.net')) {
                functionName = 'importPassboardEvent';
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Unsupported link. Use Eventbrite or Passboard.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              Navigator.pop(ctx);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Importing event...')),
              );

              try {
                final callable = FirebaseFunctions.instance.httpsCallable(functionName);
                final result = await callable.call({'eventUrl': url});
                final data = result.data as Map<String, dynamic>;

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(data['message'] ?? 'Event imported!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Import failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
}

class _AdminEventTile extends StatelessWidget {
  final EventModel event;
  final String docId;
  final Color primary;
  final Color onSurface;
  final Color surface;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AdminEventTile({
    required this.event,
    required this.docId,
    required this.primary,
    required this.onSurface,
    required this.surface,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cat = EventCategories.fromId(event.eventCategory);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(12.r),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: SizedBox(
                    width: 64.r,
                    height: 64.r,
                    child: event.imagePath.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: event.imagePath,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => _placeholder(),
                          )
                        : event.imagePath.isNotEmpty
                            ? Image.asset(event.imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _placeholder())
                            : _placeholder(),
                  ),
                ),
                SizedBox(width: 12.w),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Marcellus', fontFamilyFallback: const ['Cairo'],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 6.w,
                              runSpacing: 4.h,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    cat.label,
                                    style: TextStyle(
                                      color: primary,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: _sourceColor(event.source).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    event.source.toUpperCase(),
                                    style: TextStyle(
                                      color: _sourceColor(event.source),
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          if (event.venueName.isNotEmpty || event.city.isNotEmpty)
                            Flexible(
                              child: Text(
                                event.venueName.isNotEmpty ? event.venueName : event.city,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: onSurface.withValues(alpha: 0.4),
                                  fontSize: 11.sp,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                // Actions
                Column(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined, size: 20.r, color: primary),
                      onPressed: onEdit,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 32.r, minHeight: 32.r),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 20.r, color: Colors.red.shade400),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 32.r, minHeight: 32.r),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: primary.withValues(alpha: 0.08),
      child: Icon(Icons.event, size: 24.r, color: primary.withValues(alpha: 0.3)),
    );
  }

  Color _sourceColor(String source) {
    switch (source) {
      case 'admin':
        return Colors.blue;
      case 'eventbrite':
        return Colors.orange;
      case 'curated':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
