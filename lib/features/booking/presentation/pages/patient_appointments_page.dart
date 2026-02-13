import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:dbs/core/widgets/app_background.dart';
import 'package:dbs/core/widgets/app_card.dart';

import '../../presentation/bloc/booking_bloc.dart';
import '../../presentation/bloc/booking_event.dart';
import '../../presentation/bloc/booking_state.dart';

final sl = GetIt.instance;

class PatientAppointmentsPage extends StatefulWidget {
  const PatientAppointmentsPage({super.key});

  @override
  State<PatientAppointmentsPage> createState() => _PatientAppointmentsPageState();
}

class _PatientAppointmentsPageState extends State<PatientAppointmentsPage> {
  late final BookingBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = sl<BookingBloc>();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _bloc.add(LoadAppointmentsRequested(user.uid));
    }
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
                    future: _prefetchDoctorNames(list),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return Center(child: Text('Failed to load doctors: ${snap.error}'));
                      }
                      final doctors = snap.data ?? {};

                      return ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final a = list[index];
                          final dname = doctors[a.doctorId] ?? a.doctorId;
                          return AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dname,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text('${a.dateTime} - Status: ${a.status}'),
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

  Future<Map<String, String>> _prefetchDoctorNames(List appointments) async {
    final firestore = FirebaseFirestore.instance;
    final doctorIds = <String>{};
    for (var a in appointments) {
      doctorIds.add(a.doctorId);
    }

    final doctors = <String, String>{};
    final ids = doctorIds.toList();
    const chunk = 10;
    for (var i = 0; i < ids.length; i += chunk) {
      final slice = ids.sublist(i, i + chunk > ids.length ? ids.length : i + chunk);
      final q = await firestore.collection('doctors').where(FieldPath.documentId, whereIn: slice).get();
      for (var d in q.docs) {
        final data = d.data();
        doctors[d.id] = (data['name'] as String?) ?? d.id;
      }
    }
    return doctors;
  }
}
