abstract class BookingEvent {
  const BookingEvent();
}

class BookAppointmentRequested extends BookingEvent {
  final String userId;
  final String doctorId;
  final DateTime dateTime;
  final String? slotId;

  const BookAppointmentRequested({
    required this.userId,
    required this.doctorId,
    required this.dateTime,
    this.slotId,
  });
}

class LoadAppointmentsRequested extends BookingEvent {
  final String userId;

  const LoadAppointmentsRequested(this.userId);
}

class LoadAppointmentsForDoctorRequested extends BookingEvent {
  final String doctorId;

  const LoadAppointmentsForDoctorRequested(this.doctorId);
}

class LoadAllAppointmentsRequested extends BookingEvent {
  const LoadAllAppointmentsRequested();
}

class UpdateAppointmentStatusRequested extends BookingEvent {
  final String appointmentId;
  final String status;

  const UpdateAppointmentStatusRequested({required this.appointmentId, required this.status});
}
