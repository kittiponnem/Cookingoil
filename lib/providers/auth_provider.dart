import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/api_service.dart';
import '../services/auth_api_service.dart';

class AuthProvider with ChangeNotifier {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final ApiService _apiService = ApiService();
  late final AuthApiService _authApiService;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  String? _verificationId;

  AuthProvider() {
    _authApiService = AuthApiService(_apiService);
    _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  UserRole? get userRole => _currentUser?.role;

  Future<void> _onAuthStateChanged(firebase_auth.User? firebaseUser) async {
    if (firebaseUser != null) {
      _currentUser = await _firestoreService.getUserById(firebaseUser.uid);
      notifyListeners();
    } else {
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Try middleware API first (optional - skip if unavailable)
      try {
        final apiResponse = await _authApiService.loginWithEmail(
          email: email,
          password: password,
        );
        final token = apiResponse['token'] as String?;
        if (token != null) {
          _apiService.setAuthToken(token);
        }
      } catch (apiError) {
        // API unavailable, continue with Firebase only
        if (kDebugMode) {
          debugPrint('Middleware API unavailable, using Firebase Auth only: $apiError');
        }
      }

      // Sign in to Firebase (this is the main authentication)
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        _currentUser = await _firestoreService.getUserById(credential.user!.uid);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          _errorMessage = 'No user found with this email';
          break;
        case 'wrong-password':
          _errorMessage = 'Incorrect password';
          break;
        case 'invalid-email':
          _errorMessage = 'Invalid email address';
          break;
        case 'user-disabled':
          _errorMessage = 'This account has been disabled';
          break;
        case 'too-many-requests':
          _errorMessage = 'Too many login attempts. Please try again later';
          break;
        default:
          _errorMessage = 'Login failed: ${e.message ?? e.code}';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Login error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendOtp(String phone) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Try middleware API (optional)
      try {
        await _authApiService.sendOtp(phone: phone);
      } catch (apiError) {
        if (kDebugMode) {
          debugPrint('Middleware API unavailable for OTP: $apiError');
        }
      }

      // Use Firebase phone auth
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (firebase_auth.PhoneAuthCredential credential) async {
          await _firebaseAuth.signInWithCredential(credential);
        },
        verificationFailed: (firebase_auth.FirebaseAuthException e) {
          _errorMessage = e.message;
          _isLoading = false;
          notifyListeners();
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _isLoading = false;
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Verify OTP with middleware API
      final apiResponse = await _authApiService.verifyOtp(
        phone: phone,
        otp: otp,
      );

      final token = apiResponse['token'] as String?;
      if (token != null) {
        _apiService.setAuthToken(token);
      }

      // Verify with Firebase
      if (_verificationId != null) {
        final credential = firebase_auth.PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: otp,
        );

        final userCredential = await _firebaseAuth.signInWithCredential(credential);

        if (userCredential.user != null) {
          _currentUser = await _firestoreService.getUserById(userCredential.user!.uid);
          
          // Create user profile if doesn't exist
          if (_currentUser == null) {
            _currentUser = UserModel(
              uid: userCredential.user!.uid,
              role: UserRole.customerB2c,
              displayName: phone,
              phone: phone,
              email: '',
              branchIds: [],
              isActive: true,
              createdAt: DateTime.now(),
            );
            await _firestoreService.createUser(_currentUser!);
          }

          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    _currentUser = null;
    _apiService.setAuthToken('');
    notifyListeners();
  }

  String getHomeRouteForRole() {
    if (_currentUser == null) return '/login';

    switch (_currentUser!.role) {
      case UserRole.customerB2c:
      case UserRole.customerB2bUser:
      case UserRole.customerB2bAdmin:
        return '/customer/home';
      case UserRole.driver:
        return '/driver/home';
      case UserRole.dispatcher:
        return '/dispatcher/home';
      case UserRole.admin:
        return '/admin/home';
    }
  }
}
