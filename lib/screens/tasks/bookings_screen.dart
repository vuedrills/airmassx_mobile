import 'package:flutter/material.dart';
import '../../config/theme.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 64, color: AppTheme.neutral300),
            const SizedBox(height: 16),
            const Text(
              'Your bookings will appear here',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.navy),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage your scheduled tasks and requests.',
              style: TextStyle(color: AppTheme.neutral500),
            ),
          ],
        ),
      ),
    );
  }
}
