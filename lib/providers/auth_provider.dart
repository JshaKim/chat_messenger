import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  // 인증 상태 스트림
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  AuthProvider() {
    // 인증 상태 변화 감지
    _authService.authStateChanges.listen((user) {
      _currentUser = user;
      notifyListeners();

      // 로그인/로그아웃 시 온라인 상태 업데이트
      if (user != null) {
        _userService.updateOnlineStatus(user.uid, true);
      }
    });
  }

  // 회원가입
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Firebase Auth 회원가입 (Firestore 사용자 문서 자동 생성됨)
      await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // 로그인
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final userCredential = await _authService.signIn(
        email: email,
        password: password,
      );

      // 로그인 후 Firestore에 사용자 문서가 있는지 확인
      if (userCredential.user != null) {
        final existingUser = await _userService.getUserById(userCredential.user!.uid);

        // 사용자 문서가 없으면 생성
        if (existingUser == null) {
          await _userService.createUser(
            uid: userCredential.user!.uid,
            email: userCredential.user!.email ?? email,
            displayName: userCredential.user!.displayName ?? email.split('@')[0],
            photoURL: userCredential.user!.photoURL,
          );
        }
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      _setLoading(true);
      _clearError();

      // 오프라인 상태로 변경
      if (_currentUser != null) {
        await _userService.updateOnlineStatus(_currentUser!.uid, false);
      }

      await _authService.signOut();

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // 로딩 상태 설정
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // 에러 메시지 설정
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  // 에러 메시지 지우기
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // 에러 메시지 초기화 (UI에서 에러 표시 후 호출)
  void clearError() {
    _clearError();
  }
}
