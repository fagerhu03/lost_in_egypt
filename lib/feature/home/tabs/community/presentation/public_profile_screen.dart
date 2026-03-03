import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../auth/data/models/user.dart';
import '../../../../tours/presentation/bloc/guide_tours_cubit.dart';
import '../../../../tours/presentation/bloc/guide_tours_state.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PublicProfileScreen extends StatefulWidget {
  final UserModel user;

  const PublicProfileScreen({super.key, required this.user});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.user.isVerifiedGuide) {
      context.read<GuideToursCubit>().fetchTours(widget.user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.user.firstName} ${widget.user.lastName}')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            ClipOval(
              child: widget.user.profileImageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.user.profileImageUrl,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      memCacheHeight: 250, // Resizes the image in memory heavily improving performance
                      memCacheWidth: 250,
                      placeholder: (context, url) => Container(
                        width: 120,
                        height: 120,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 120,
                        height: 120,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                        child: const Icon(Icons.person, size: 60),
                      ),
                    )
                  : Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, size: 60),
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${widget.user.firstName} ${widget.user.lastName}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (widget.user.isVerifiedGuide) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.verified, color: Colors.blue, size: 24),
                ],
              ],
            ),
            if (widget.user.bio.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  widget.user.bio,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ],
            if (widget.user.isVerifiedGuide) ...[
              const SizedBox(height: 24),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Active Tours', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
              BlocBuilder<GuideToursCubit, GuideToursState>(
                builder: (context, state) {
                  if (state is GuideToursLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is GuideToursError) {
                    return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
                  } else if (state is GuideToursLoaded) {
                    final tours = state.tours;
                    if (tours.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: Text('This guide has no active tours.')),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: tours.length,
                      itemBuilder: (context, index) {
                        final tour = tours[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: tour.images.isNotEmpty
                                ? Image.network(tour.images.first, width: 80, height: 80, fit: BoxFit.cover)
                                : const Icon(Icons.tour, size: 40),
                            title: Text(tour.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('\$${tour.price.toStringAsFixed(2)} - ${tour.frequency}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // Can navigate to a Public Tour Detail page later
                            },
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
