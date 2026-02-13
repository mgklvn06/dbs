import 'package:flutter/material.dart';
import 'package:dbs/core/widgets/app_background.dart';
import 'package:dbs/core/widgets/app_card.dart';
import 'package:dbs/core/widgets/reveal.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final slots = List.generate(6, (i) => '2026-01-2${i + 1} 09:00');

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      body: AppBackground(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Reveal(
                delay: const Duration(milliseconds: 40),
                child: Text(
                  'Upcoming time slots',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemBuilder: (context, index) => AppCard(
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 12),
                        Expanded(child: Text(slots[index])),
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text('Reserve'),
                        ),
                      ],
                    ),
                  ),
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemCount: slots.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
