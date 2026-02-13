import '../entities/appointment.dart';

abstract class BookingRepository {
  Future<AppointmentEntity> bookAppointment(AppointmentEntity appointment);
  Future<List<AppointmentEntity>> getAppointmentsForUser(String userId);
  Future<List<AppointmentEntity>> getAppointmentsForDoctor(String doctorId);
  Future<List<AppointmentEntity>> getAllAppointments();
  Future<void> updateAppointmentStatus(String appointmentId, String status);
}
