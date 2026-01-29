class AppointmentEntity {
  final String? id;
  final String userId;
  final String doctorId;
  final DateTime dateTime;
  final String status;

  AppointmentEntity({
    this.id,
    required this.userId,
    required this.doctorId,
    required this.dateTime,
    this.status = 'pending',
  });
}
