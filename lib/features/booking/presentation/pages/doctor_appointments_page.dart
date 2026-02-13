import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:dbs/core/widgets/app_background.dart';
import 'package:dbs/core/widgets/app_card.dart';

import '../../presentation/bloc/booking_bloc.dart';
import '../../presentation/bloc/booking_event.dart';
import '../../presentation/bloc/booking_state.dart';

final sl = GetIt.instance;

class DoctorAppointmentsPage extends StatefulWidget {
  final String doctorId;
  const DoctorAppointmentsPage({super.key, required this.doctorId});

  @override
  State<DoctorAppointmentsPage> createState() => _DoctorAppointmentsPageState();
}

class _DoctorAppointmentsPageState extends State<DoctorAppointmentsPage> {
  late final BookingBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = sl<BookingBloc>();
    _bloc.add(LoadAppointmentsForDoctorRequested(widget.doctorId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BookingBloc>.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(title: const Text('My Appointments')),
        body: AppBackground(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: BlocBuilder<BookingBloc, BookingState>(
              builder: (context, state) {
                if (state is BookingLoading) return const Center(child: CircularProgressIndicator());
                if (state is BookingListLoaded) {
                  final list = state.appointments;
                  if (list.isEmpty) return const Center(child: Text('No appointments'));

                  return FutureBuilder<Map<String, String>>(
                    future: _prefetchUserNames(list),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return Center(child: Text('Failed to load patients: ${snap.error}'));
                      }
                      final users = snap.data ?? {};

                      return ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final a = list[index];
                          final pname = users[a.userId] ?? a.userId;
                          return AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pname,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text('${a.dateTime} - Status: ${a.status}'),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.check, color: Colors.green),
                                      onPressed: () {
                                        if (a.id == null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Missing appointment id. Refresh data.')),
                                          );
                                          return;
                                        }
                                        _bloc.add(UpdateAppointmentStatusRequested(
                                          appointmentId: a.id!,
                                          status: 'accepted',
                                        ));
                                        _bloc.add(LoadAppointmentsForDoctorRequested(widget.doctorId));
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.red),
                                      onPressed: () {
                                        if (a.id == null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Missing appointment id. Refresh data.')),
                                          );
                                          return;
                                        }
                                        _bloc.add(UpdateAppointmentStatusRequested(
                                          appointmentId: a.id!,
                                          status: 'rejected',
                                        ));
                                        _bloc.add(LoadAppointmentsForDoctorRequested(widget.doctorId));
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                }
                if (state is BookingError) return Center(child: Text('Error: ${state.message}'));
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<Map<String, String>> _prefetchUserNames(List appointments) async {
    final firestore = FirebaseFirestore.instance;
    final userIds = <String>{};
    for (var a in appointments) {
      userIds.add(a.userId);
    }

    final users = <String, String>{};
    final ids = userIds.toList();
    const chunk = 10;
    for (var i = 0; i < ids.length; i += chunk) {
      final slice = ids.sublist(i, i + chunk > ids.length ? ids.length : i + chunk);
      final q = await firestore.collection('users').where(FieldPath.documentId, whereIn: slice).get();
      for (var d in q.docs) {
        final data = d.data();
        users[d.id] = (data['displayName'] as String?) ?? (data['email'] as String?) ?? d.id;
      }
    }
    return users;
  }
}
