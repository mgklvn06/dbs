import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/appointment.dart';

class AppointmentModel extends AppointmentEntity {
  AppointmentModel({
    super.id,
    required super.userId,
    required super.doctorId,
    required super.dateTime,
    super.status,
    super.slotId,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    final rawDate = map['appointmentTime'] ?? map['dateTime'];
    DateTime parsedDate;
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate =
          DateTime.tryParse(rawDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
    } else if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(0);
    }
    return AppointmentModel(
      id: map['id'] as String?,
      userId: map['userId'] as String,
      doctorId: map['doctorId'] as String,
      dateTime: parsedDate,
      status: map['status'] as String? ?? 'pending',
      slotId: map['slotId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final appointmentTimestamp = Timestamp.fromDate(dateTime);
    return {
      'id': id,
      'userId': userId,
      'doctorId': doctorId,
      'appointmentTime': appointmentTimestamp,
      'dateTime': appointmentTimestamp,
      'status': status,
      if (slotId != null) 'slotId': slotId,
    };
  }
}
