import '../entities/appointment.dart';
import '../repositories/booking_repository.dart';

class GetAppointmentsForUser {
  final BookingRepository repository;

  GetAppointmentsForUser(this.repository);

  Future<List<AppointmentEntity>> call(String userId) async {
    return await repository.getAppointmentsForUser(userId);
  }
}
