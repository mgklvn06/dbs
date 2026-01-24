import 'package:dbs/features/auth/data/models/user_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_remote_datasource.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final GoogleSignIn googleSignIn;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.googleSignIn,
  });

  @override
  Future<UserModel> login(String email, String password) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
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
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in was cancelled by the user.');
    }
    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final authResult =
        await firebaseAuth.signInWithCredential(credential);

    final user = authResult.user!;
    return UserModel.fromFirebase(
      id: user.uid,
      email: user.email!,
      avatarUrl: user.photoURL,
    );
  }

  @override
  Future<void> logout() async {
    await googleSignIn.signOut();
    await firebaseAuth.signOut();
  }
}
