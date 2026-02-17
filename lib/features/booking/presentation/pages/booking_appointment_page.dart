// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: unnecessary_import
import 'package:firebase_core/firebase_core.dart';
import 'package:dbs/features/doctor/domain/usecases/get_doctors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:dbs/features/doctor/domain/entities/doctor.dart';
import 'package:dbs/core/widgets/app_background.dart';
import 'package:dbs/core/widgets/app_card.dart';
import 'package:dbs/core/widgets/reveal.dart';

import '../../presentation/bloc/booking_bloc.dart';
import '../../presentation/bloc/booking_event.dart';
import '../../presentation/bloc/booking_state.dart';

final sl = GetIt.instance;

class BookingAppointmentPage extends StatefulWidget {
  final DoctorEntity? initialDoctor;
  const BookingAppointmentPage({super.key, this.initialDoctor});

  @override
  State<BookingAppointmentPage> createState() => _BookingAppointmentPageState();
}

class _BookingAppointmentPageState extends State<BookingAppointmentPage> {
  String? _selectedDoctorId;
  String? _selectedSlotId;
  DateTime? _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _selectedDoctorId = widget.initialDoctor?.id;
  }

  void _submit() {
    final doctorId = _selectedDoctorId ?? '';
    final dt = _selectedDateTime;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (doctorId.isEmpty || dt == null || _selectedSlotId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a doctor and slot')));
      return;
    }

    final bloc = sl<BookingBloc>();
    bloc.add(BookAppointmentRequested(
      userId: user.uid,
      doctorId: doctorId,
      dateTime: dt,
      slotId: _selectedSlotId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final settingsRef = FirebaseFirestore.instance.collection('settings').doc('system');
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: settingsRef.snapshots(),
      builder: (context, settingsSnap) {
        final settings = settingsSnap.data?.data() ?? {};
        final maintenance = _readMap(settings['maintenance']);
        final booking = _readMap(settings['booking']);
        final maintenanceMode = (maintenance['enabled'] as bool?) ?? (settings['maintenanceMode'] as bool?) ?? false;
        final bookingEnabled = (booking['enabled'] as bool?) ?? true;
        final bookingDisabled = maintenanceMode || !bookingEnabled;
        final maintenanceMessage = (maintenance['message'] as String?)?.trim();
        final disabledMessage = (maintenanceMessage != null && maintenanceMessage.isNotEmpty)
            ? maintenanceMessage
            : 'Booking is temporarily disabled by the admin.';

        return BlocProvider<BookingBloc>(
          create: (_) => sl<BookingBloc>(),
          child: Scaffold(
            appBar: AppBar(title: const Text('Select a slot')),
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
                            Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(disabledMessage),
                            ),
                          ],
                        ),
                      ),
                    if (bookingDisabled) const SizedBox(height: 12),
                    Reveal(
                      delay: const Duration(milliseconds: 50),
                      child: const Text(
                        'Choose an available slot',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Reveal(
                      delay: const Duration(milliseconds: 110),
                      child: AppCard(
                        child: FutureBuilder<List<DoctorEntity>>(
                          future: sl<GetDoctors>()(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Text('Failed to load doctors: ${snapshot.error}');
                            }
                            final doctors = (snapshot.data ?? []).where((d) => (d.id ?? '').isNotEmpty).toList();
                            if (doctors.isEmpty) return const Text('No doctors available');
                            final selectedId = _selectedDoctorId ?? doctors.first.id;
                            final selected = doctors.firstWhere(
                              (d) => d.id == selectedId,
                              orElse: () => doctors.first,
                            );
                            _selectedDoctorId = selected.id;
                            return DropdownButtonFormField<DoctorEntity>(
                              initialValue: selected,
                              items: doctors
                                  .map((d) => DropdownMenuItem(value: d, child: Text('${d.name} - ${d.specialty}')))
                                  .toList(),
                              onChanged: bookingDisabled
                                  ? null
                                  : (d) {
                                      setState(() {
                                        _selectedDoctorId = d?.id;
                                        _selectedSlotId = null;
                                        _selectedDateTime = null;
                                      });
                                    },
                              decoration: const InputDecoration(labelText: 'Select doctor'),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Available slots',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _selectedDoctorId == null
                          ? const Center(child: Text('Select a doctor to view slots'))
                          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              stream: FirebaseFirestore.instance
                                  .collection('availability')
                                  .doc(_selectedDoctorId)
                                  .collection('slots')
                                  .where('isBooked', isEqualTo: false)
                                  .where('startTime', isGreaterThan: Timestamp.fromDate(DateTime.now()))
                                  .orderBy('startTime')
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                if (snapshot.hasError) {
                                  return Center(child: Text(_friendlyFirestoreError(snapshot.error)));
                                }
                                final docs = snapshot.data?.docs ?? [];
                                if (docs.isEmpty) {
                                  return const Center(child: Text('No available slots'));
                                }

                                return ListView.separated(
                                  itemCount: docs.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final doc = docs[index];
                                    final data = doc.data();
                                    final start = (data['startTime'] as Timestamp?)?.toDate();
                                    final end = (data['endTime'] as Timestamp?)?.toDate();
                                    if (start == null) return const SizedBox.shrink();
                                    final isSelected = _selectedSlotId == doc.id;
                                    return InkWell(
                                      onTap: bookingDisabled
                                          ? null
                                          : () {
                                              setState(() {
                                                _selectedSlotId = doc.id;
                                                _selectedDateTime = start;
                                              });
                                            },
                                      borderRadius: BorderRadius.circular(18),
                                      child: AppCard(
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
                                            : null,
                                        child: Row(
                                          children: [
                                            Icon(isSelected ? Icons.check_circle : Icons.schedule),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _formatSlot(start, end),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(fontWeight: FontWeight.w600),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Slot ID: ${doc.id}',
                                                    style: Theme.of(context).textTheme.bodySmall,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (isSelected) const Icon(Icons.check),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedDateTime != null
                          ? 'Selected: ${_formatSlot(_selectedDateTime!, null)}'
                          : 'No slot selected',
                    ),
                    const SizedBox(height: 12),
                    BlocConsumer<BookingBloc, BookingState>(
                      listener: (context, state) {
                        if (state is BookingCreated) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('Appointment created')));
                          Navigator.pop(context);
                        } else if (state is BookingError) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
                        }
                      },
                      builder: (context, state) {
                        if (state is BookingLoading) return const Center(child: CircularProgressIndicator());
                        return ElevatedButton(
                          onPressed: bookingDisabled ? null : _submit,
                          child: const Text('Confirm booking'),
                        );
                      },
                    ),
                  ],
                ),
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

String _formatSlot(DateTime start, DateTime? end) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  String two(int n) => n.toString().padLeft(2, '0');
  final h = start.hour % 12 == 0 ? 12 : start.hour % 12;
  final ampm = start.hour >= 12 ? 'PM' : 'AM';
  final date = '${months[start.month - 1]} ${start.day}, ${start.year}';
  final time = '${two(h)}:${two(start.minute)} $ampm';
  if (end == null) return '$date | $time';
  final endH = end.hour % 12 == 0 ? 12 : end.hour % 12;
  final endAmpm = end.hour >= 12 ? 'PM' : 'AM';
  final endTime = '${two(endH)}:${two(end.minute)} $endAmpm';
  return '$date | $time - $endTime';
}

String _friendlyFirestoreError(Object? error) {
  if (error is FirebaseException) {
    if (error.code == 'failed-precondition') {
      return 'Missing index for slots query. Deploy Firestore indexes and retry.';
    }
    if (error.code == 'permission-denied') {
      return 'Permission denied. Make sure Firestore rules are deployed and you are signed in.';
    }
  }
  return 'Failed to load slots: $error';
}
