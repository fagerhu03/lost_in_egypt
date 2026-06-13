import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
            Icon(Icons.event_available, size: 80.r, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
            SizedBox(height: 16.h),
            Text(
              'No Upcoming Bookings',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Text(
              'When tourists book your tours, they will appear here.',
              style: TextStyle(fontSize: 14.sp, color: isDark ? Colors.white70 : Colors.black54),
            ),
            SizedBox(height: 24.h),
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
