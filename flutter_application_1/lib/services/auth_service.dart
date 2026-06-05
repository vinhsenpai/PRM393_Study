import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase + Google Sign-In wrapper.
///
/// Responsibilities:
/// - loginWithGoogle()
/// - logout()
/// - create/update Firestore user doc at users/{uid}
/// - role-safe mapping: new users default to buyer, existing roles preserved
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

  /// Logout from Firebase and Google.
  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  /// Creates/updates Firestore user document at users/{uid}.
  ///
  /// Firestore structure:
  /// users/{uid} {
  ///   uid, name, email, photoUrl, role, createdAt, updatedAt
  /// }
  ///
  /// Role rules:
  /// - If document doesn't exist: role defaults to 'buyer'
  /// - If document exists: preserve existing role (never overwrite seller/admin)
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

    final Object? createdAtValue =
        exists ? (existingData?['createdAt'] ?? now) : now;

    final Map<String, dynamic> data = {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'role': role,
      'createdAt': createdAtValue,
      'updatedAt': now,
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

