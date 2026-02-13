import '../entities/doctor.dart';
import '../repositories/doctor_repository.dart';

class GetDoctors {
  final DoctorRepository repository;

  GetDoctors(this.repository);

  Future<List<DoctorEntity>> call() async {
    return await repository.getAllDoctors();
  }
}
