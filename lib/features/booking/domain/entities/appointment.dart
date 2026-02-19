class AppointmentEntity {
  final String? id;
  final String userId;
  final String doctorId;
  final DateTime dateTime;
  final String status;
  final String? slotId;
  final Map<String, dynamic>? payment;

  AppointmentEntity({
    this.id,
    required this.userId,
    required this.doctorId,
    required this.dateTime,
    this.status = 'pending',
    this.slotId,
    this.payment,
  });
}
