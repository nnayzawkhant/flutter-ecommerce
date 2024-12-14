import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:user_repository/src/models/user.dart';
import 'package:user_repository/src/user_repo.dart';

import 'entities/entities.dart';

class FirebaseUserRepo implements UserRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firebaseFirestore;

  FirebaseUserRepo({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firebaseFirestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firebaseFirestore = firebaseFirestore ?? FirebaseFirestore.instance;

  final userCollection = FirebaseFirestore.instance.collection('users');

  @override
  Stream<MyUser?> get user {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;

      final userDoc = await userCollection.doc(user.uid).get();
      if (userDoc.exists) {
        return MyUser.fromEntity(MyUserEntity.fromDocument(userDoc.data()!));
      }
      return null;
    });
  }

  @override
  Future<void> signIn(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  @override
  Future<void> signUp(MyUser myUser, String password) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: myUser.email,
        password: password,
      );

      final userId = userCredential.user?.uid;
      if (userId != null) {
        final userEntity = myUser.toEntity();
        await userCollection.doc(userId).set(userEntity.toDocument());
      }
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  @override
  Future<void> logOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Failed to log out: $e');
    }
  }

  @override
  Future<void> setUserData(MyUser user) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw Exception('No user currently signed in.');
      }

      final userEntity = user.toEntity();
      await userCollection.doc(currentUser.uid).set(userEntity.toDocument(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to set user data: $e');
    }
  }
}
