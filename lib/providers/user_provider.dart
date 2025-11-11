import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/storage_service.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();
  final StorageService _storageService = StorageService();

  UserModel? _currentUser;
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 현재 사용자 정보 로드
  Future<void> loadCurrentUser(String uid) async {
    try {
      _setLoading(true);
      _clearError();

      final user = await _userService.getUserById(uid);
      _currentUser = user;

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // 현재 사용자 스트림 구독
  void subscribeToCurrentUser(String uid) {
    _userService.getUserStream(uid).listen(
      (user) {
        _currentUser = user;
        notifyListeners();
      },
      onError: (error) {
        _setError(error.toString());
      },
    );
  }

  // 모든 사용자 목록 스트림 구독
  void subscribeToAllUsers() {
    _userService.getAllUsers().listen(
      (users) {
        _users = users;
        notifyListeners();
      },
      onError: (error) {
        _setError(error.toString());
      },
    );
  }

  // 사용자 검색
  Stream<List<UserModel>> searchUsers(String query) {
    return _userService.searchUsers(query);
  }

  // 프로필 사진 업데이트
  Future<bool> updateProfilePhoto({
    required String uid,
    required File imageFile,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Storage에 이미지 업로드
      final photoURL = await _storageService.uploadProfileImage(
        userId: uid,
        imageFile: imageFile,
      );

      // Firestore에 URL 저장
      await _userService.updatePhotoURL(uid, photoURL);

      // 현재 사용자 정보 업데이트
      if (_currentUser != null && _currentUser!.uid == uid) {
        _currentUser = _currentUser!.copyWith(photoURL: photoURL);
        notifyListeners();
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // 닉네임 업데이트
  Future<bool> updateDisplayName({
    required String uid,
    required String displayName,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      await _userService.updateDisplayName(uid, displayName);

      // 현재 사용자 정보 업데이트
      if (_currentUser != null && _currentUser!.uid == uid) {
        _currentUser = _currentUser!.copyWith(displayName: displayName);
        notifyListeners();
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // 온라인 상태 업데이트
  Future<void> updateOnlineStatus(String uid, bool isOnline) async {
    try {
      await _userService.updateOnlineStatus(uid, isOnline);

      // 현재 사용자 정보 업데이트
      if (_currentUser != null && _currentUser!.uid == uid) {
        _currentUser = _currentUser!.copyWith(
          isOnline: isOnline,
          lastSeen: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ID로 사용자 찾기 (로컬 캐시에서)
  UserModel? getUserById(String uid) {
    try {
      return _users.firstWhere((user) => user.uid == uid);
    } catch (e) {
      return null;
    }
  }

  // 사용자 정보 가져오기 (Firestore에서 직접)
  Future<UserModel?> fetchUserById(String uid) async {
    try {
      return await _userService.getUserById(uid);
    } catch (e) {
      _setError(e.toString());
      return null;
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

  // 에러 메시지 초기화 (UI에서 호출)
  void clearError() {
    _clearError();
  }

  // Provider 초기화 (로그아웃 시 호출)
  void clear() {
    _currentUser = null;
    _users = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
