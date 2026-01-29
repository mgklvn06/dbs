import 'package:flutter/material.dart';

class BookingFlowPage extends StatelessWidget {
  const BookingFlowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book an appointment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Booking flow (placeholder)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/booking/appointment');
              },
              child: const Text('Select slot & confirm'),
            ),
          ],
        ),
      ),
    );
  }
}
