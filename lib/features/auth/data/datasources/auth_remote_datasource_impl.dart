import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'auth_remote_datasource.dart';
import '../models/user_models.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthRemoteDataSourceImpl({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn;

  @override
  Future<UserModel> login(String email, String password) async {
    final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return UserModel.fromFirebase(
      userCredential.user!,
      id: userCredential.user!.uid,
      email: userCredential.user!.email!,
      avatarUrl: userCredential.user!.photoURL,
    );
  }

  @override
  Future<UserModel> register(String email, String password) async {
    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return UserModel.fromFirebase(
      userCredential.user!,
      id: userCredential.user!.uid,
      email: userCredential.user!.email!,
      avatarUrl: userCredential.user!.photoURL,
    );
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    UserCredential userCredential;

    if (kIsWeb) {
      // On web, use Firebase's recommended approach: GoogleAuthProvider with signInWithPopup
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      // Allow account selection in the popup
      googleProvider.setCustomParameters({
        'prompt': 'select_account',
      });

      userCredential = await _firebaseAuth.signInWithPopup(googleProvider);
    } else {
      // For mobile platforms, use the google_sign_in plugin
      GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();

      googleUser ??= await _googleSignIn.signIn();

      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'CANCELLED',
          message: 'Google sign-in aborted',
        );
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      userCredential = await _firebaseAuth.signInWithCredential(credential);
    }

    return UserModel.fromFirebase(
      userCredential.user!,
      id: userCredential.user!.uid,
      email: userCredential.user!.email!,
      avatarUrl: userCredential.user!.photoURL,
    );
  }

  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }
}
