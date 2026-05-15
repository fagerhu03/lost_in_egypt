import 'package:flutter/material.dart';
import '../../../tours/presentation/pages/create_tour_screen.dart';

class UpcomingBookingsScreen extends StatelessWidget {
  const UpcomingBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guide Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create New Tour',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CreateTourScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text(
              'No Upcoming Bookings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'When tourists book your tours, they will appear here.',
              style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CreateTourScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create a Tour'),
            )
          ],
        ),
      ),
    );
  }
}
