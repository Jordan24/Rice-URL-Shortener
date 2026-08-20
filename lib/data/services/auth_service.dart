import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_constants.dart';

class RiceUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;

  const RiceUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });

  bool get isRiceEmail => email.toLowerCase().endsWith("@${AppConstants.allowedAuthDomain}");
}

class AuthService {
  final FirebaseAuth? _firebaseAuth;
  final StreamController<RiceUser?> _authStateController = StreamController<RiceUser?>.broadcast();
  RiceUser? _currentUser;

  AuthService({this._firebaseAuth}) {
    if (_firebaseAuth != null) {
      _firebaseAuth.authStateChanges().listen((User? user) {
        if (user != null && user.email != null) {
          if (user.email!.toLowerCase().endsWith("@${AppConstants.allowedAuthDomain}")) {
            _currentUser = RiceUser(
              uid: user.uid,
              email: user.email!,
              displayName: user.displayName ?? user.email!.split("@").first,
              photoUrl: user.photoURL,
            );
          } else {
            _currentUser = null;
          }
        } else {
          _currentUser = null;
        }
        _authStateController.add(_currentUser);
      });
    }
  }

  RiceUser? get currentUser => _currentUser;
  Stream<RiceUser?> get authStateChanges => _authStateController.stream;

  /// Initiates Google Sign-In with @rice.edu domain validation
  Future<RiceUser> signInWithRiceGoogle() async {
    if (_firebaseAuth != null) {
      final googleProvider = GoogleAuthProvider();
      googleProvider.setCustomParameters({"hd": AppConstants.allowedAuthDomain});
      
      final userCredential = await _firebaseAuth.signInWithPopup(googleProvider);
      final user = userCredential.user;

      if (user == null || user.email == null) {
        throw Exception("Failed to obtain account details. Please try again.");
      }

      if (!user.email!.toLowerCase().endsWith("@${AppConstants.allowedAuthDomain}")) {
        await _firebaseAuth.signOut();
        throw Exception("Access restricted: Please sign in with your official @rice.edu email address.");
      }

      final riceUser = RiceUser(
        uid: user.uid,
        email: user.email!,
        displayName: user.displayName ?? user.email!.split("@").first,
        photoUrl: user.photoURL,
      );
      _currentUser = riceUser;
      _authStateController.add(_currentUser);
      return riceUser;
    } else {
      // Offline / Demo fallback user for local preview testing
      final demoUser = RiceUser(
        uid: "rice_demo_uid_1912",
        email: "sammy.owl@rice.edu",
        displayName: "Sammy the Owl",
        photoUrl: null,
      );
      _currentUser = demoUser;
      _authStateController.add(_currentUser);
      return demoUser;
    }
  }

  Future<void> signOut() async {
    if (_firebaseAuth != null) {
      await _firebaseAuth.signOut();
    }
    _currentUser = null;
    _authStateController.add(null);
  }

  void dispose() {
    _authStateController.close();
  }
}
