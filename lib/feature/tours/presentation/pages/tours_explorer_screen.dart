import 'package:flutter/material.dart';
import 'package:lost_in_egypt/feature/home/tabs/navigator/widget/search_header.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/shimmer_loading_widget.dart';
import '../../domain/entities/tour_entity.dart';
import '../bloc/explorer_tours_cubit.dart';
import '../bloc/explorer_tours_state.dart';
import 'tour_detail_screen.dart';

class ToursExplorerScreen extends StatelessWidget {
  const ToursExplorerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ExplorerToursCubit>()..loadTours(),
      child: const ToursExplorerView(),
    );
  }
}

class ToursExplorerView extends StatefulWidget {
  const ToursExplorerView({Key? key}) : super(key: key);

  @override
  State<ToursExplorerView> createState() => _ToursExplorerViewState();
}

class _ToursExplorerViewState extends State<ToursExplorerView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final shadow = (isDark ? Colors.white : Colors.black).withOpacity(0.08);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Discover Tours',
          style: TextStyle(
            color: onSurface,
            fontWeight: FontWeight.bold,
            fontFamily: 'Marcellus',
            fontSize: 24,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.tune, color: onSurface),
            onPressed: () {
              // TODO: Implement advanced filter bottom sheet
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search destinations, guides...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          Expanded(
            child: BlocBuilder<ExplorerToursCubit, ExplorerToursState>(
              builder: (context, state) {
                if (state is ExplorerToursLoading) {
                  return _buildShimmerLoading();
                } else if (state is ExplorerToursError) {
                  return Center(
                    child: Text(
                      'Failed to load tours.\n${state.message}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                } else if (state is ExplorerToursLoaded) {
                  final filteredTours = state.tours.where((t) {
                    return t.title.toLowerCase().contains(_searchQuery) ||
                           t.destinations.any((d) => d.toLowerCase().contains(_searchQuery));
                  }).toList();

                  if (filteredTours.isEmpty) {
                    return _buildEmptyState(theme);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTours.length,
                    itemBuilder: (context, index) {
                      return _buildTourCard(filteredTours[index], theme);
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTourCard(TourEntity tour, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TourDetailScreen(tour: tour)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Banner
            Hero(
              tag: 'tour_image_${tour.id}',
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: tour.images.isNotEmpty
                      ? Image.network(
                          tour.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          tour.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '\$${tour.price}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Metadata row
                  Row(
                    children: [
                      Icon(Icons.calendar_month, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, yyyy').format(tour.meetingTime),
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.people, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 4),
                      Text(
                        'Up to ${tour.maxAttendees}',
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  // Destinations chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tour.destinations.take(3).map((dest) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                      ),
                      child: Text(
                        dest,
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )).toList(),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey.withOpacity(0.2),
      child: const Center(
        child: Icon(Icons.landscape, size: 48, color: Colors.grey),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.travel_explore, size: 80, color: theme.colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 20),
          const Text(
            'No tours found',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search query.',
            style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    // Requires shimmer package. 
    // Creating a pseudo-shimmer effect since shimmer might not be in pubspec yet.
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          height: 300,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      },
    );
  }
}
