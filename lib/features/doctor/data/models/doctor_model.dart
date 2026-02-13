import '../../domain/entities/doctor.dart';

class DoctorModel extends DoctorEntity {
  DoctorModel({
    super.id,
    required super.name,
    required super.specialty,
  });

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
