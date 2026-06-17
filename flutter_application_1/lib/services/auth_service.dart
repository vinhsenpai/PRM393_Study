import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';


/// Firebase + Google Sign-In wrapper.
///
class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  /// Stream of Firebase auth user session changes.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Returns the currently signed-in user (if any).
  User? getCurrentUser() => _auth.currentUser;

  /// Google Sign-In + Firebase authentication.
  Future<UserCredential> loginWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'google_sign_in_cancelled',
        message: 'Google sign-in cancelled.',
      );
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  /// Email/password sign in.
  Future<UserCredential> loginWithEmailPassword(
      String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Email/password sign up.
  Future<UserCredential> signUpWithEmailPassword(
      String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sends email verification to the current user.
  Future<void> sendEmailVerification() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw StateError('No user is currently signed in.');
    }
    await user.sendEmailVerification();
  }

  /// Checks if the current user's email is verified.
  Future<bool> isEmailVerified() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw StateError('No user is currently signed in.');
    }
    await user.reload(); // Refresh user data
    return user.emailVerified;
  }

  /// Logout from Firebase and Google.
  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

    /// Creates/updates Firestore user document at users/{uid}.
  ///
  /// Firestore structure:
  /// users/{uid} {
  ///   uid, name, email, photoUrl, role, provider, emailVerified, createdAt, updatedAt
  /// }
  ///
  /// Role rules:
  /// - If document doesn't exist: role defaults to 'buyer'
  /// - If document exists: preserve existing role (never overwrite seller/admin)
  /// Compatibility rules:
  /// - If provider field doesn't exist: set to 'google' for existing users
  /// - If emailVerified field doesn't exist: set to true for existing users
  Future<void> createOrUpdateUserInFirestore(
      UserCredential userCredential) async {
    final User? user = userCredential.user;
    if (user == null) {
      throw StateError('FirebaseAuth user is null after Google login.');
    }

    final String uid = user.uid;
    final DocumentReference<Map<String, dynamic>> userRef =
        _firestore.collection('users').doc(uid);

    final DocumentSnapshot<Map<String, dynamic>> existingSnap =
        await userRef.get();

    final String name = user.displayName ?? '';
    final String email = user.email ?? '';
    final String photoUrl = user.photoURL ?? '';

    final Timestamp now = Timestamp.now();

    final bool exists = existingSnap.exists;
    final Map<String, dynamic>? existingData = existingSnap.data();


    // Default role
    String role = 'buyer';

    if (exists) {
      final roleObj = existingData?['role'];
      if (roleObj is String && (roleObj == 'buyer' || roleObj == 'seller' || roleObj == 'admin')) {
        role = roleObj;
      }
    }

    // Provider/emailVerified defaults (will be overridden by backward-compat rules for existing docs)
    // - New email/password signups: provider=email, emailVerified=false
    // - New Google signins: provider=google, emailVerified=true
    // NOTE: For legacy accounts, we preserve existing provider/emailVerified if present.
    final bool isEmailCredential = userCredential.credential is EmailAuthCredential;
    String finalProvider = isEmailCredential ? 'email' : 'google';
    bool finalEmailVerified = isEmailCredential ? false : true;


    if (exists) {
      // Preserve existing role if valid
      final roleObj = existingData?['role'];
      if (roleObj is String && (roleObj == 'buyer' || roleObj == 'seller' || roleObj == 'admin')) {
        role = roleObj;
      }

      // Handle provider field for backward compatibility
      final providerObj = existingData?['provider'];
      if (providerObj is String) {
        finalProvider = providerObj;
      } else {
        // If provider doesn't exist, assume Google for existing users
        finalProvider = 'google';
      }

      // Handle emailVerified field for backward compatibility
      final emailVerifiedObj = existingData?['emailVerified'];
      if (emailVerifiedObj is bool) {
        finalEmailVerified = emailVerifiedObj;
      } else {
        // If emailVerified doesn't exist, assume true for existing users (Google users)
        finalEmailVerified = true;
      }
    }

    final Object? createdAtValue =
        exists ? (existingData?['createdAt'] ?? FieldValue.serverTimestamp()) : FieldValue.serverTimestamp();

    final Map<String, dynamic> data = {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'role': role,
      'provider': finalProvider,
      'emailVerified': finalEmailVerified,
      'createdAt': createdAtValue,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await userRef.set(data, SetOptions(merge: true));
  }

  /// Reads role from Firestore (buyer/seller/admin).
  Future<String> getUserRole(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final Object? roleObj = doc.data()?['role'];

    if (roleObj is String) {
      if (roleObj == 'buyer' || roleObj == 'seller' || roleObj == 'admin') {
        return roleObj;
      }
    }

    return 'buyer';
  }

  /// Exposes Firestore instance for model parsing.
  FirebaseFirestore get firestore => _firestore;

  /// Sign out wrapper.
  Future<void> signOut() => logout();
}