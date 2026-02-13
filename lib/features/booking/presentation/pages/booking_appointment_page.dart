import 'package:dbs/features/doctor/domain/usecases/get_doctors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:dbs/features/doctor/domain/entities/doctor.dart';

import '../../presentation/bloc/booking_bloc.dart';
import '../../presentation/bloc/booking_event.dart';
import '../../presentation/bloc/booking_state.dart';

final sl = GetIt.instance;

class BookingAppointmentPage extends StatefulWidget {
  const BookingAppointmentPage({super.key});

  @override
  State<BookingAppointmentPage> createState() => _BookingAppointmentPageState();
}

class _BookingAppointmentPageState extends State<BookingAppointmentPage> {
  DoctorEntity? _selectedDoctor;
  // ignore: unused_field
  List<DoctorEntity>? _doctors;
  DateTime? _selectedDateTime;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
    if (time == null) return;
    setState(() {
      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _submit() {
  final doctorId = _selectedDoctor?.id ?? '';
    final dt = _selectedDateTime;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (doctorId.isEmpty || dt == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select doctor and date/time')));
      return;
    }

    final bloc = sl<BookingBloc>();
    bloc.add(BookAppointmentRequested(userId: user.uid, doctorId: doctorId, dateTime: dt));
    // Show a temporary message; listen to bloc for success
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BookingBloc>(
      create: (_) => sl<BookingBloc>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Confirm appointment')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FutureBuilder<List<DoctorEntity>>(
                future: sl<GetDoctors>()(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('Failed to load doctors: ${snapshot.error}');
                  }
                  final doctors = snapshot.data ?? [];
                  if (doctors.isEmpty) return const Text('No doctors available');
                  return DropdownButtonFormField<DoctorEntity>(
                    value: _selectedDoctor ?? doctors.first,
                    items: doctors
                        .map((d) => DropdownMenuItem(value: d, child: Text('${d.name} — ${d.specialty}')))
                        .toList(),
                    onChanged: (d) {
                      setState(() {
                        _selectedDoctor = d;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Select doctor'),
                  );
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _pickDateTime, child: const Text('Pick date & time')),
              const SizedBox(height: 12),
              Text(_selectedDateTime != null ? _selectedDateTime.toString() : 'No date selected'),
              const SizedBox(height: 24),
              BlocConsumer<BookingBloc, BookingState>(
                listener: (context, state) {
                  if (state is BookingCreated) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment created')));
                    Navigator.pop(context);
                  } else if (state is BookingError) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
                  }
                },
                builder: (context, state) {
                  if (state is BookingLoading) return const Center(child: CircularProgressIndicator());
                  return ElevatedButton(onPressed: _submit, child: const Text('Confirm booking'));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
