import '../../domain/entities/doctor.dart';

class DoctorModel extends DoctorEntity {
  DoctorModel({
    String? id,
    required String name,
    required String specialty,
  }) : super(id: id, name: name, specialty: specialty);

  factory DoctorModel.fromMap(Map<String, dynamic> map) {
    return DoctorModel(
      id: map['id'] as String?,
      name: map['name'] as String? ?? '',
      specialty: map['specialty'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
    };
  }
}
