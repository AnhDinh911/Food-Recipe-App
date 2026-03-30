import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _tryUpsertUserProfile(
      uid: credential.user!.uid,
      email: credential.user?.email ?? email,
      provider: 'password',
    );

    return credential;
  }

  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'aborted-by-user',
        message: 'Google sign-in cancelled.',
      );
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    await _tryUpsertUserProfile(
      uid: userCredential.user!.uid,
      email: userCredential.user?.email ?? '',
      displayName: userCredential.user?.displayName,
      photoUrl: userCredential.user?.photoURL,
      provider: 'google',
    );

    return userCredential;
  }

  Future<void> _upsertUserProfile({
    required String uid,
    required String email,
    required String provider,
    String? displayName,
    String? photoUrl,
  }) {
    return _db.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'provider': provider,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _tryUpsertUserProfile({
    required String uid,
    required String email,
    required String provider,
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      await _upsertUserProfile(
        uid: uid,
        email: email,
        provider: provider,
        displayName: displayName,
        photoUrl: photoUrl,
      );
    } catch (_) {
      // Allow auth to succeed even if Firestore is unavailable or not configured.
    }
  }

  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  }
}
