abstract class BookingEvent {
  const BookingEvent();
}

class BookAppointmentRequested extends BookingEvent {
  final String userId;
  final String doctorId;
  final DateTime dateTime;

  const BookAppointmentRequested({required this.userId, required this.doctorId, required this.dateTime});
}

class LoadAppointmentsRequested extends BookingEvent {
  final String userId;

  const LoadAppointmentsRequested(this.userId);
}

class UpdateAppointmentStatusRequested extends BookingEvent {
  final String appointmentId;
  final String status;

  const UpdateAppointmentStatusRequested({required this.appointmentId, required this.status});
}
