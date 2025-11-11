import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 현재 사용자
  User? get currentUser => _auth.currentUser;

  // 인증 상태 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 회원가입
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Firebase Auth 회원가입
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestore에 사용자 문서 생성
      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        final now = Timestamp.now();

        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'email': email,
          'displayName': displayName,
          'photoURL': null,
          'isOnline': true,
          'lastSeen': now,
          'createdAt': now,
        });

        // Firebase Auth 프로필 업데이트
        await userCredential.user!.updateDisplayName(displayName);
      }

      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // 로그인
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 에러 처리
  String _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return '사용자를 찾을 수 없습니다.';
        case 'wrong-password':
          return '비밀번호가 올바르지 않습니다.';
        case 'email-already-in-use':
          return '이미 사용 중인 이메일입니다.';
        case 'weak-password':
          return '비밀번호는 6자 이상이어야 합니다.';
        case 'invalid-email':
          return '유효하지 않은 이메일 형식입니다.';
        default:
          return '인증 오류가 발생했습니다: ${e.message}';
      }
    }
    return '알 수 없는 오류가 발생했습니다.';
  }
}
