import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/book_appointment.dart';
import '../../domain/usecases/get_appointments_for_user.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/entities/appointment.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookAppointment bookAppointment;
  final GetAppointmentsForUser getAppointmentsForUser;
  final BookingRepository bookingRepository;

  BookingBloc({
    required this.bookAppointment,
    required this.getAppointmentsForUser,
    required this.bookingRepository,
  }) : super(BookingInitial()) {
    on<BookAppointmentRequested>(_onBookAppointment);
    on<LoadAppointmentsRequested>(_onLoadAppointments);
    on<LoadAppointmentsForDoctorRequested>(_onLoadAppointmentsForDoctor);
    on<LoadAllAppointmentsRequested>(_onLoadAllAppointments);
    on<UpdateAppointmentStatusRequested>(_onUpdateStatus);
  }

  Future<void> _onBookAppointment(
    BookAppointmentRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    try {
      final appointmentEntity = AppointmentEntity(
        userId: event.userId,
        doctorId: event.doctorId,
        dateTime: event.dateTime,
        slotId: event.slotId,
        payment: event.payment,
      );

      final created = await bookAppointment(appointmentEntity);
      emit(BookingCreated(created));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  Future<void> _onLoadAppointments(
    LoadAppointmentsRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    try {
      final list = await getAppointmentsForUser(event.userId);
      emit(BookingListLoaded(list));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  Future<void> _onLoadAppointmentsForDoctor(
    LoadAppointmentsForDoctorRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    try {
      final list = await bookingRepository.getAppointmentsForDoctor(
        event.doctorId,
      );
      emit(BookingListLoaded(list));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  Future<void> _onLoadAllAppointments(
    LoadAllAppointmentsRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    try {
      final list = await bookingRepository.getAllAppointments();
      emit(BookingListLoaded(list));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  Future<void> _onUpdateStatus(
    UpdateAppointmentStatusRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    try {
      await bookingRepository.updateAppointmentStatus(
        event.appointmentId,
        event.status,
      );
      // Reloading not automatic here; emit success and caller can request reload
      emit(BookingInitial());
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }
}
