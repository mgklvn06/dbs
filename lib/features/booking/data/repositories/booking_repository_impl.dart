import '../../domain/entities/appointment.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_remote_datasource.dart';
import '../models/appointment_model.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource remote;

  BookingRepositoryImpl(this.remote);

  @override
  Future<AppointmentEntity> bookAppointment(AppointmentEntity appointment) async {
    final model = AppointmentModel(
      userId: appointment.userId,
      doctorId: appointment.doctorId,
      dateTime: appointment.dateTime,
      status: appointment.status,
    );

    final saved = await remote.createAppointment(model);
    return AppointmentEntity(
      id: saved.id,
      userId: saved.userId,
      doctorId: saved.doctorId,
      dateTime: saved.dateTime,
      status: saved.status,
    );
  }

  @override
  Future<List<AppointmentEntity>> getAppointmentsForUser(String userId) async {
    final models = await remote.getAppointmentsForUser(userId);
    return models
        .map((m) => AppointmentEntity(
              id: m.id,
              userId: m.userId,
              doctorId: m.doctorId,
              dateTime: m.dateTime,
              status: m.status,
            ))
        .toList();
  }

  @override
  Future<List<AppointmentEntity>> getAppointmentsForDoctor(String doctorId) async {
    final models = await remote.getAppointmentsForDoctor(doctorId);
    return models
        .map((m) => AppointmentEntity(
              id: m.id,
              userId: m.userId,
              doctorId: m.doctorId,
              dateTime: m.dateTime,
              status: m.status,
            ))
        .toList();
  }

  @override
  Future<List<AppointmentEntity>> getAllAppointments() async {
    final models = await remote.getAllAppointments();
    return models
        .map((m) => AppointmentEntity(
              id: m.id,
              userId: m.userId,
              doctorId: m.doctorId,
              dateTime: m.dateTime,
              status: m.status,
            ))
        .toList();
  }

  @override
  Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    return remote.updateAppointmentStatus(appointmentId, status);
  }
}
