import '../../domain/entities/appointment.dart';

class AppointmentModel extends AppointmentEntity {
  AppointmentModel({
    String? id,
    required String userId,
    required String doctorId,
    required DateTime dateTime,
    String status = 'pending',
  }) : super(id: id, userId: userId, doctorId: doctorId, dateTime: dateTime, status: status);

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      id: map['id'] as String?,
      userId: map['userId'] as String,
      doctorId: map['doctorId'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      status: map['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'doctorId': doctorId,
      'dateTime': dateTime.toIso8601String(),
      'status': status,
    };
  }
}
