import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor_model.dart';

abstract class DoctorRemoteDataSource {
  Future<List<DoctorModel>> getAllDoctors();
}

class DoctorRemoteDataSourceImpl implements DoctorRemoteDataSource {
  final FirebaseFirestore firestore;

  DoctorRemoteDataSourceImpl({FirebaseFirestore? firestore}) : firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<DoctorModel>> getAllDoctors() async {
    final col = firestore.collection('doctors');
    final snap = await col.where('isActive', isEqualTo: true).get();
    return snap.docs.map((d) {
      final map = d.data();
      return DoctorModel.fromMap({...map, 'id': d.id});
    }).toList();
  }
}
