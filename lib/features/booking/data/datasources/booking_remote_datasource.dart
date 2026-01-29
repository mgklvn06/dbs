import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';

abstract class BookingRemoteDataSource {
  Future<AppointmentModel> createAppointment(AppointmentModel appointment);
  Future<List<AppointmentModel>> getAppointmentsForUser(String userId);
  Future<List<AppointmentModel>> getAppointmentsForDoctor(String doctorId);
  Future<void> updateAppointmentStatus(String appointmentId, String status);
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final FirebaseFirestore firestore;

  BookingRemoteDataSourceImpl({FirebaseFirestore? firestore}) : firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<AppointmentModel> get _col => firestore.collection('appointments').withConverter<AppointmentModel>(
        fromFirestore: (snap, _) => AppointmentModel.fromMap(snapshotMapToMap(snap.data())),
        toFirestore: (AppointmentModel model, _) => model.toMap(),
      );

  // Helper to ensure a Map<String, dynamic> is available for fromMap
  Map<String, dynamic> snapshotMapToMap(Map<String, dynamic>? maybeMap) {
    return maybeMap ?? <String, dynamic>{};
  }

  @override
  Future<AppointmentModel> createAppointment(AppointmentModel appointment) async {
    final docRef = await _col.add(appointment);
    final snap = await docRef.get();
    final model = snap.data()!;
    // Ensure id is stored
    final m = AppointmentModel.fromMap({...model.toMap(), 'id': docRef.id});
    await docRef.set(m);
    return m;
  }

  @override
  Future<List<AppointmentModel>> getAppointmentsForUser(String userId) async {
    final q = await _col.where('userId', isEqualTo: userId).get();
    return q.docs.map((d) {
      final model = d.data();
      return AppointmentModel.fromMap({...model.toMap(), 'id': d.id});
    }).toList();
  }

  @override
  Future<List<AppointmentModel>> getAppointmentsForDoctor(String doctorId) async {
    final q = await _col.where('doctorId', isEqualTo: doctorId).get();
    return q.docs.map((d) {
      final model = d.data();
      return AppointmentModel.fromMap({...model.toMap(), 'id': d.id});
    }).toList();
  }

  @override
  Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    await firestore.collection('appointments').doc(appointmentId).update({'status': status});
  }
}
