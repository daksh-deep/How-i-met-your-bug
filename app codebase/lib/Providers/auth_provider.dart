import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? profilePicUrl;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.profilePicUrl,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      profilePicUrl: data['profilePicUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'profilePicUrl': profilePicUrl,
    };
  }
}

class MyAuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserProfile? _currentUserProfile;
  UserProfile? get currentUserProfile => _currentUserProfile;

  User? get currentUser => _auth.currentUser;

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        // Create user profile in Firestore
        UserProfile userProfile = UserProfile(
          uid: user.uid,
          name: name,
          email: email,
          phone: phone,
        );

        await _firestore.collection('users').doc(user.uid).set(userProfile.toMap());

        _currentUserProfile = userProfile;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Sign Up Error: $e');
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fetch user profile
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .get();

      _currentUserProfile = UserProfile.fromFirestore(userDoc);
      notifyListeners();
      return true;
    } catch (e) {
      print('Sign In Error: $e');
      return false;
    }
  }

  Future<bool> googleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        // Store additional user info in Firestore if new user
        await _firestore.collection('users').doc(user.uid).set({
          'name': user.displayName,
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        return true;
      }
      return false;
    } catch (e) {
      print('Google Sign In Error: $e');
      return false;
    }
  }

  Future<bool> updateProfile(UserProfile updatedProfile) async {
    try {
      await _firestore
          .collection('users')
          .doc(updatedProfile.uid)
          .update(updatedProfile.toMap());

      _currentUserProfile = updatedProfile;
      notifyListeners();
      return true;
    } catch (e) {
      print('Profile Update Error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
    _currentUserProfile = null;
    notifyListeners();
  }
}