import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../utils/validators.dart';

enum AuthState {
  initial,
  authenticated,
  unauthenticated,
  needsEmailVerification,
  needsProfile,
  needsOnboarding,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final UserService _userService;

  AuthState _authState = AuthState.initial;
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _authSub;
  StreamSubscription? _userSub;

  AuthProvider({
    AuthService? authService,
    UserService? userService,
  })  : _authService = authService ?? AuthService(),
        _userService = userService ?? UserService();

  AuthState get authState => _authState;
  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _authState == AuthState.authenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get firebaseUser => _authService.currentUser;

  void init() {
    _authSub = _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      _authState = AuthState.unauthenticated;
      _userSub?.cancel();
      notifyListeners();
      return;
    }

    // Check email verification (bypass for admin)
    final isAdmin = Validators.isAdminEmail(firebaseUser.email ?? '');
    if (!firebaseUser.emailVerified && !isAdmin) {
      _authState = AuthState.needsEmailVerification;
      _currentUser = null;
      notifyListeners();
      return;
    }

    // Listen to user document for real-time updates
    _userSub?.cancel();
    _userSub = _userService.userStream(firebaseUser.uid).listen(
      (appUser) {
        if (appUser == null) {
          _authState = AuthState.needsProfile;
          _currentUser = null;
        } else if (!appUser.isOnboarded) {
          _authState = AuthState.needsOnboarding;
          _currentUser = appUser;
        } else {
          _authState = AuthState.authenticated;
          _currentUser = appUser;
        }
        notifyListeners();
      },
      onError: (e) {
        _authState = AuthState.needsProfile;
        notifyListeners();
      },
    );
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signIn(email, password);
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e.code);
    } catch (e) {
      _error = 'Sign in failed. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cred = await _authService.signUp(email, password);
      // Send verification email immediately after signup
      if (cred.user != null) {
        debugPrint('[AUTH] User created: ${cred.user!.uid} / ${cred.user!.email}');
        await cred.user!.sendEmailVerification();
        debugPrint('[AUTH] Verification email sent successfully to $email');
      } else {
        debugPrint('[AUTH] WARNING: cred.user is null after signup');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('[AUTH] FirebaseAuthException during signUp: ${e.code} - ${e.message}');
      _error = _mapAuthError(e.code);
    } catch (e) {
      debugPrint('[AUTH] Unexpected error during signUp: $e');
      _error = 'Sign up failed. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Called from VerifyEmailScreen to re-check verification status
  Future<bool> checkEmailVerified() async {
    try {
      await _authService.reloadUser();
      final user = _authService.currentUser;
      if (user != null && user.emailVerified) {
        // Re-trigger auth state change
        await _onAuthStateChanged(user);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> resendVerificationEmail() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('[AUTH] Resending verification email...');
      await _authService.sendEmailVerification();
      debugPrint('[AUTH] Resend verification email succeeded');
    } catch (e) {
      debugPrint('[AUTH] Resend verification email failed: $e');
      _error = 'Failed to resend. Try again in a moment.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _userSub?.cancel();
    await _authService.signOut();
    _currentUser = null;
    _authState = AuthState.unauthenticated;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendPasswordReset(email);
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e.code);
    } catch (e) {
      _error = 'Password reset failed.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }
}
