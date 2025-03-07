import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Sign Up User
  Future<User?> signUp(String name, String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = userCredential.user;

      if (user != null) {
        // Save user details in Firestore
        await _db.collection("users").doc(user.uid).set({
          "name": name,
          "email": email,
          "created_at": DateTime.now(),
        });

        print("✅ Signup Successful! User: ${user.email}");
        return user;
      } else {
        print("❌ Signup failed: User is null");
        return null;
      }

      return user;
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }

  // Login User
  Future<User?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = userCredential.user;

      if (user != null) {
        print("✅ Login Successful! User: ${user.email}");
        return user;
      } else {
        print("❌ Login failed: User is null");
        return null;
      }
    } catch (e) {
      print("Error during login $e");
      return null;
    }
  }

  // Google Sign-In
  Future<User?> googleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // User canceled sign-in

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        _db.collection("users").doc(user.uid).set({
          "name": user.displayName,
          "email": user.email,
          "created_at": DateTime.now(),
        }, SetOptions(merge: true));
      }

      return user;
    } catch (e) {
      print("Google Sign-In failed: $e");
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }
}
