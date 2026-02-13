import '../entities/doctor.dart';

abstract class DoctorRepository {
  Future<List<DoctorEntity>> getAllDoctors();
}
