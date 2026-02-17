// ignore_for_file: strict_top_level_inference, camel_case_types

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:dbs/config/routes.dart';
import 'package:dbs/features/doctor/domain/entities/doctor.dart';
import 'package:dbs/features/doctor/domain/usecases/get_doctors.dart';
import 'package:dbs/core/widgets/app_background.dart';
import 'package:dbs/core/widgets/app_card.dart';
import 'package:dbs/core/widgets/reveal.dart';

final sl = GetIt.instance;

class BookingFlowPage extends StatefulWidget {
  const BookingFlowPage({super.key});

  @override
  State<BookingFlowPage> createState() => _BookingFlowPageState();
}

class _BookingFlowPageState extends State<BookingFlowPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsRef = FirebaseFirestore.instance.collection('settings').doc('system');
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: settingsRef.snapshots(),
      builder: (context, settingsSnap) {
        final settings = settingsSnap.data?.data() ?? {};
        final maintenance = _readMap(settings['maintenance']);
        final booking = _readMap(settings['booking']);
        final maintenanceMode = _readBool(
          maintenance['enabled'],
          _readBool(settings['maintenanceMode'], false),
        );
        final bookingEnabled = _readBool(booking['enabled'], true);
        final bookingDisabled = maintenanceMode || !bookingEnabled;
        final maintenanceMessage = (maintenance['message'] as String?)?.trim();
        final disabledMessage = (maintenanceMessage != null && maintenanceMessage.isNotEmpty)
            ? maintenanceMessage
            : 'Booking is temporarily disabled by the admin.';

        return Scaffold(
          appBar: AppBar(title: const Text('Book an appointment')),
          body: AppBackground(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (bookingDisabled)
                    AppCard(
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(disabledMessage),
                          ),
                        ],
                      ),
                    ),
                  if (bookingDisabled) const SizedBox(height: 12),
                  Reveal(
                    delay: const Duration(milliseconds: 40),
                    child: Text(
                      'Find the right specialist',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Reveal(
                    delay: const Duration(milliseconds: 120),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search doctors or specialties',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: FutureBuilder<List<DoctorEntity>>(
                      future: sl<GetDoctors>()(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Failed to load doctors: ${snapshot.error}'));
                        }
                        final doctors = (snapshot.data ?? []).where((d) => (d.id ?? '').isNotEmpty).toList();
                        if (doctors.isEmpty) return const Center(child: Text('No doctors available'));

                        final filtered = _query.isEmpty
                            ? doctors
                            : doctors.where((d) {
                                final name = d.name.toLowerCase();
                                final spec = d.specialty.toLowerCase();
                                return name.contains(_query) || spec.contains(_query);
                              }).toList();

                        if (filtered.isEmpty) return const Center(child: Text('No doctors match your search'));

                        return ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final d = filtered[index];
                            return _DoctorCard(
                              doctor: d,
                              onTap: () {
                                if (bookingDisabled) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(disabledMessage)),
                                  );
                                  return;
                                }
                                Navigator.pushNamed(context, Routes.bookingAppointment, arguments: d);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Map<String, dynamic> _readMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) {
    return raw.map((key, value) => MapEntry('$key', value));
  }
  return <String, dynamic>{};
}

bool _readBool(dynamic raw, bool fallback) {
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  if (raw is String) {
    final normalized = raw.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') return true;
    if (normalized == 'false' || normalized == '0' || normalized == 'no') return false;
  }
  return fallback;
}

class _DoctorCard extends StatelessWidget {
  final DoctorEntity doctor;
  final VoidCallback onTap;

  const _DoctorCard({required this.doctor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AppCard(
        child: Row(
          children: [
            const CircleAvatar(
              radius: 26,
              child: Icon(Icons.medical_services_outlined),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doctor.specialty,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
