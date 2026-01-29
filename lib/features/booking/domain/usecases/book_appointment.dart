import '../entities/appointment.dart';
import '../repositories/booking_repository.dart';

class BookAppointment {
  final BookingRepository repository;

  BookAppointment(this.repository);

  Future<AppointmentEntity> call(AppointmentEntity appointment) async {
    return await repository.bookAppointment(appointment);
  }
}
