import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthResultModel {
  final bool success;
  final String message;

  AuthResultModel({
    required this.success,
    required this.message,
  });
}

class AuthService {
  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // REGISTER
  Future<AuthResultModel> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {

    try {

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid =
          userCredential.user!.uid;

      await _firestore
          .collection('users')
          .doc(uid)
          .set({
        'name': name,
        'email': email,
        'role': role,
        'nim': '',
        'createdAt': Timestamp.now(),
      });

      return AuthResultModel(
        success: true,
        message: 'Register berhasil',
      );

    } on FirebaseAuthException catch (e) {

      print("CODE: ${e.code}");
      print("MESSAGE: ${e.message}");

      return AuthResultModel(
        success: false,
        message:
            "${e.code}: ${e.message}",
      );
    }
  } // <-- INI YANG KURANG

  // LOGIN
  Future<AuthResultModel> login({
    required String email,
    required String password,
  }) async {

    try {

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return AuthResultModel(
        success: true,
        message: 'Login berhasil',
      );

    } on FirebaseAuthException catch (e) {

      return AuthResultModel(
        success: false,
        message:
            "${e.code}: ${e.message}",
      );
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}