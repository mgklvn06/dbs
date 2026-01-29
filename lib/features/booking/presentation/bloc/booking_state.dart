import '../../domain/entities/appointment.dart';

abstract class BookingState {
  const BookingState();
}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingCreated extends BookingState {
  final AppointmentEntity appointment;

  const BookingCreated(this.appointment);
}

class BookingListLoaded extends BookingState {
  final List<AppointmentEntity> appointments;

  const BookingListLoaded(this.appointments);
}

class BookingError extends BookingState {
  final String message;

  const BookingError(this.message);
}
