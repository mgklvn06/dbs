import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor_model.dart';

abstract class DoctorRemoteDataSource {
  Future<List<DoctorModel>> getAllDoctors();
}

class DoctorRemoteDataSourceImpl implements DoctorRemoteDataSource {
  final FirebaseFirestore firestore;

  DoctorRemoteDataSourceImpl({FirebaseFirestore? firestore})
    : firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<DoctorModel>> getAllDoctors() async {
    final col = firestore.collection('doctors');
    final snap = await col.where('isActive', isEqualTo: true).get();
    return snap.docs
        .where((doc) {
          final data = doc.data();
          final visible = _readBool(data['profileVisible'], true);
          final accepting = _readBool(data['acceptingBookings'], true);
          return visible && accepting;
        })
        .map((d) {
          final map = d.data();
          return DoctorModel.fromMap({...map, 'id': d.id});
        })
        .toList();
  }

  bool _readBool(dynamic raw, bool fallback) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final normalized = raw.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return fallback;
  }
}
