import 'package:flutter/material.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final slots = List.generate(6, (i) => '2026-01-2${i + 1} 09:00');

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) => ListTile(
          leading: const Icon(Icons.calendar_today),
          title: Text(slots[index]),
          trailing: ElevatedButton(
            onPressed: () {},
            child: const Text('Reserve'),
          ),
        ),
        separatorBuilder: (_, __) => const Divider(),
        itemCount: slots.length,
      ),
    );
  }
}
