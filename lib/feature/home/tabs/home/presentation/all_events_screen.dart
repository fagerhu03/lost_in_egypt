import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:lost_in_egypt/core/constants/event_categories.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/data/models/map_item_models.dart';
import 'package:lost_in_egypt/feature/home/tabs/home/presentation/event_details_screen.dart';

class AllEventsScreen extends StatefulWidget {
  final List<EventModel> events;
  const AllEventsScreen({super.key, required this.events});

  @override
  State<AllEventsScreen> createState() => _AllEventsScreenState();
}

class _AllEventsScreenState extends State<AllEventsScreen> {
  late List<EventModel> _allEvents;
  String _selectedCategory = 'all';
  String _selectedCity = 'All Cities';

  @override
  void initState() {
    super.initState();
    _allEvents = widget.events;
  }

  List<EventModel> get _filteredEvents {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _allEvents.where((e) {
      // Hide past non-recurring events
      if (!e.isRecurring && e.date.isBefore(today)) return false;
      final catMatch = _selectedCategory == 'all' || e.eventCategory == _selectedCategory;
      final cityMatch = _selectedCity == 'All Cities' || e.city == _selectedCity;
      return catMatch && cityMatch;
    }).toList();
  }

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
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.black.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 6),
    );

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        title: Text(
          'Experiences',
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
      body: Column(
              children: [
                // Category filter chips
                SizedBox(
                  height: 48.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    itemCount: EventCategories.values.length,
                    itemBuilder: (context, index) {
                      final cat = EventCategories.values[index];
                      final isSelected = _selectedCategory == cat.id;
                      return Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat.id),
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
                              cat.label,
                              style: TextStyle(
                                color: isSelected ? Colors.white : onSurface.withValues(alpha: 0.7),
                                fontSize: 12.sp,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                fontFamily: 'Marcellus',
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // City filter chips
                SizedBox(
                  height: 40.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                    itemCount: EventCategories.cities.length,
                    itemBuilder: (context, index) {
                      final city = EventCategories.cities[index];
                      final isSelected = _selectedCity == city;
                      return Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedCity = city),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primary.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: isSelected ? primary : onSurface.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Text(
                              city,
                              style: TextStyle(
                                color: isSelected ? primary : onSurface.withValues(alpha: 0.5),
                                fontSize: 11.sp,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 4.h),
                // Results count
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_filteredEvents.length} experience${_filteredEvents.length == 1 ? '' : 's'} found',
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.4),
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                // Event list
                Expanded(
                  child: _filteredEvents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event_busy, size: 60, color: primary.withValues(alpha: 0.25)),
                              SizedBox(height: 16.h),
                              Text(
                                'No events match your filters',
                                style: TextStyle(
                                  color: onSurface.withValues(alpha: 0.5),
                                  fontSize: 16,
                                  fontFamily: 'Marcellus',
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 32.h),
                          itemCount: _filteredEvents.length,
                          itemBuilder: (context, i) {
                            return _EventCard(
                              event: _filteredEvents[i],
                              shadow: shadow,
                              surface: surface,
                              onSurface: onSurface,
                              primary: primary,
                              isDark: isDark,
                            );
                          },
                        ),
                ),
              ],
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
    final categoryInfo = EventCategories.fromId(event.eventCategory);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [shadow],
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EventDetailsScreen(event: event),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with overlays
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 180.h,
                      width: double.infinity,
                      child: event.imagePath.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: event.imagePath,
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  Container(color: onSurface.withValues(alpha: 0.06)),
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
                    // Gradient overlay
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.35),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Category pill
                    Positioned(
                      top: 10.h,
                      left: 10.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          categoryInfo.label,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // Location badge
                    if (event.venueName.isNotEmpty || event.city.isNotEmpty)
                      Positioned(
                        top: 10.h,
                        right: 10.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on, size: 12.r, color: Colors.white),
                              SizedBox(width: 3.w),
                              Flexible(
                                child: Text(
                                  event.venueName.isNotEmpty ? event.venueName : event.city,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Recurring badge
                    if (event.isRecurring)
                      Positioned(
                        bottom: 10.h,
                        left: 10.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: Colors.green.shade700.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.repeat, size: 11.r, color: Colors.white),
                              SizedBox(width: 4.w),
                              Text(
                                event.recurrenceText,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Marcellus',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    if (event.venueName.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.place_outlined, size: 14.r, color: primary),
                          SizedBox(width: 5.w),
                          Expanded(
                            child: Text(
                              event.venueName,
                              style: TextStyle(
                                color: primary,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                    ],
                    Row(
                      children: [
                        Icon(Icons.star_rounded, color: Colors.amber, size: 15.r),
                        SizedBox(width: 4.w),
                        Text(
                          event.rating.toStringAsFixed(1) + (event.reviewCount > 0 ? " (${event.reviewCount})" : ""),
                          style: TextStyle(
                            color: onSurface.withValues(alpha: 0.7),
                            fontSize: 13.sp,
                          ),
                        ),
                        if (event.duration.isNotEmpty) ...[
                          SizedBox(width: 12.w),
                          Icon(Icons.access_time_outlined, size: 14.r, color: onSurface.withValues(alpha: 0.5)),
                          SizedBox(width: 4.w),
                          Text(
                            event.duration,
                            style: TextStyle(
                              color: onSurface.withValues(alpha: 0.55),
                              fontSize: 13.sp,
                            ),
                          ),
                        ],
                        if (event.price > 0) ...[
                          const Spacer(),
                          Text(
                            'EGP ${event.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: primary,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (event.description.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Text(
                        event.description,
                        style: TextStyle(
                          color: onSurface.withValues(alpha: 0.5),
                          fontSize: 12.sp,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
      color: primary.withValues(alpha: 0.08),
      child: Center(
        child: Icon(Icons.image_not_supported_outlined,
            color: primary.withValues(alpha: 0.3), size: 40),
      ),
    );
  }
}
