import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import '../bloc/guide_tours_cubit.dart';
import '../bloc/guide_tours_state.dart';
import '../bloc/create_tour_cubit.dart';
import 'create_tour_screen.dart';

class GuideDashboardScreen extends StatefulWidget {
  const GuideDashboardScreen({super.key});

  @override
  State<GuideDashboardScreen> createState() => _GuideDashboardScreenState();
}

class _GuideDashboardScreenState extends State<GuideDashboardScreen> {
  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.read<GuideToursCubit>().fetchTours(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guide Dashboard')),
      body: BlocBuilder<GuideToursCubit, GuideToursState>(
        builder: (context, state) {
          if (state is GuideToursLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is GuideToursError) {
            return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
          } else if (state is GuideToursLoaded) {
            final tours = state.tours;
            if (tours.isEmpty) {
              return const Center(child: Text('You have not created any tours yet.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tours.length,
              itemBuilder: (context, index) {
                final tour = tours[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: tour.images.isNotEmpty
                        ? Image.network(tour.images.first, width: 60, height: 60, fit: BoxFit.cover)
                        : const Icon(Icons.tour, size: 40),
                    title: Text(tour.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('\$${tour.price.toStringAsFixed(2)} - ${tour.frequency}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to tour details or editing
                    },
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (context) => CreateTourCubit(createTourUseCase: GetIt.I()),
                child: const CreateTourScreen(),
              ),
            ),
          );
          // Refresh tours after returning
          final user = FirebaseAuth.instance.currentUser;
          if (user != null && mounted) {
            context.read<GuideToursCubit>().fetchTours(user.uid);
          }
        },
        label: const Text('Create Tour'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFFC79A00),
      ),
    );
  }
}
