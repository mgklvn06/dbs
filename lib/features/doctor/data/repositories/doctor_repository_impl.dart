import '../../domain/entities/doctor.dart';
import '../../domain/repositories/doctor_repository.dart';
import '../datasources/doctor_remote_datasource.dart';

class DoctorRepositoryImpl implements DoctorRepository {
  final DoctorRemoteDataSource remote;

  DoctorRepositoryImpl(this.remote);

  @override
  Future<List<DoctorEntity>> getAllDoctors() async {
    final models = await remote.getAllDoctors();
    return models
        .map((m) => DoctorEntity(id: m.id, name: m.name, specialty: m.specialty))
        .toList();
  }
}
