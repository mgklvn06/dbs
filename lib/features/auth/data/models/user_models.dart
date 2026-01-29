import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/user.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.avatarUrl,
  });

  factory UserModel.fromFirebase(User user, {
    required String id,
    required String email,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id,
      email: email,
      avatarUrl: avatarUrl,
    );
  }
}
