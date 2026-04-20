import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import 'package:lost_in_egypt/core/widgets/app_error_widget.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';

class AllEventsScreen extends StatefulWidget {
  const AllEventsScreen({super.key});

  @override
  State<AllEventsScreen> createState() => _AllEventsScreenState();
}

class _AllEventsScreenState extends State<AllEventsScreen> {
  static const _pageSize = 20;
  int _limit = _pageSize;

  Stream<QuerySnapshot> get _stream => FirebaseFirestore.instance
      .collection('events')
      .orderBy('date', descending: false)
      .limit(_limit)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final surface = theme.colorScheme.surface;
    final bg = theme.scaffoldBackgroundColor;

    final shadow = BoxShadow(
      color: isDark
          ? Colors.white.withOpacity(0.04)
          : Colors.black.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 6),
    );

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        title: Text(
          'Events',
          style: TextStyle(
            color: onSurface,
            fontFamily: 'Marcellus',
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        foregroundColor: onSurface,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primary));
          }
          if (snap.hasError) {
            return AppErrorWidget(
              message: 'Could not load events.\nCheck your connection and try again.',
              icon: Icons.event_busy_rounded,
              onRetry: () => setState(() {}),
            );
          }

          final docs = snap.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_busy, size: 60, color: primary.withOpacity(0.25)),
                  const SizedBox(height: 16),
                  Text(
                    'No events right now',
                    style: TextStyle(
                      color: onSurface.withOpacity(0.5),
                      fontSize: 16,
                      fontFamily: 'Marcellus',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back soon for upcoming events in Egypt.',
                    style: TextStyle(
                      color: onSurface.withOpacity(0.35),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final hasMore = docs.length == _limit;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: docs.length + (hasMore ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == docs.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: TextButton(
                      onPressed: () => setState(() => _limit += _pageSize),
                      child: Text(
                        'Load more',
                        style: TextStyle(
                          color: primary,
                          fontFamily: 'Marcellus',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }

              final data = docs[i].data() as Map<String, dynamic>;
              final event = EventModel.fromMap(data, docs[i].id);
              return _EventCard(
                event: event,
                shadow: shadow,
                surface: surface,
                onSurface: onSurface,
                primary: primary,
                isDark: isDark,
              );
            },
          );
        },
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  final BoxShadow shadow;
  final Color surface;
  final Color onSurface;
  final Color primary;
  final bool isDark;

  const _EventCard({
    required this.event,
    required this.shadow,
    required this.surface,
    required this.onSurface,
    required this.primary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, d MMM yyyy').format(event.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [shadow],
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              SizedBox(
                height: 180,
                width: double.infinity,
                child: event.imagePath.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: event.imagePath,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: onSurface.withOpacity(0.06)),
                        errorWidget: (_, __, ___) =>
                            _ImageError(primary: primary),
                      )
                    : event.imagePath.isNotEmpty
                        ? Image.asset(
                            event.imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _ImageError(primary: primary),
                          )
                        : _ImageError(primary: primary),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Marcellus',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 14, color: primary),
                        const SizedBox(width: 5),
                        Text(
                          dateStr,
                          style: TextStyle(
                            color: primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (event.locationAddress.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 14,
                              color: onSurface.withOpacity(0.5)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              event.locationAddress,
                              style: TextStyle(
                                color: onSurface.withOpacity(0.55),
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      children: [
                        Icon(Icons.star_rounded,
                            color: Colors.amber, size: 15),
                        const SizedBox(width: 4),
                        Text(
                          event.rating.toStringAsFixed(1),
                          style: TextStyle(
                            color: onSurface.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.access_time_outlined,
                            size: 14,
                            color: onSurface.withOpacity(0.5)),
                        const SizedBox(width: 4),
                        Text(
                          event.duration,
                          style: TextStyle(
                            color: onSurface.withOpacity(0.55),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  final Color primary;
  const _ImageError({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: primary.withOpacity(0.08),
      child: Icon(Icons.image_not_supported_outlined,
          color: primary.withOpacity(0.3), size: 40),
    );
  }
}
