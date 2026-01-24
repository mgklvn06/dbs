import 'package:dbs/features/auth/data/models/user_models.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_remote_datasource.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
  });

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 10));

      final user = credential.user!;
      return UserModel.fromFirebase(
        id: user.uid,
        email: user.email!,
        avatarUrl: user.photoURL,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential') {
        throw Exception('Invalid email or password. Please check your credentials or register if you don\'t have an account.');
      }
      throw Exception(e.message ?? 'Authentication failed');
    }
  }

  @override
  Future<UserModel> register(String email, String password) async {
    final credential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user!;
    return UserModel.fromFirebase(
      id: user.uid,
      email: user.email!,
      avatarUrl: user.photoURL,
    );
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    final googleProvider = GoogleAuthProvider();

    final userCredential =
        await firebaseAuth.signInWithProvider(googleProvider);

    final user = userCredential.user!;
    return UserModel.fromFirebase(
      id: user.uid,
      email: user.email!,
      avatarUrl: user.photoURL,
    );
   }

  @override
  Future<void> logout() async {
    await firebaseAuth.signOut();
  }
}
