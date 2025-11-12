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
    UserCredential? userCredential;

    try {
      // 1단계: Firebase Auth 회원가입
      print('[AuthService] 회원가입 시작: $email');
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('[AuthService] Firebase Auth 계정 생성 성공: ${userCredential.user?.uid}');

      // 2단계: Firestore에 사용자 문서 생성
      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        final now = Timestamp.now();

        try {
          print('[AuthService] Firestore 사용자 문서 생성 시도: $uid');
          await _firestore.collection('users').doc(uid).set({
            'uid': uid,
            'email': email,
            'displayName': displayName,
            'photoURL': null,
            'isOnline': true,
            'lastSeen': now,
            'createdAt': now,
          });
          print('[AuthService] Firestore 사용자 문서 생성 성공');

          // 3단계: Firebase Auth 프로필 업데이트
          await userCredential.user!.updateDisplayName(displayName);
          print('[AuthService] Firebase Auth 프로필 업데이트 성공');
        } catch (firestoreError) {
          // Firestore 문서 생성 실패 시 Auth 계정 삭제 (롤백)
          print('[AuthService] ❌ Firestore 문서 생성 실패: $firestoreError');
          print('[AuthService] Auth 계정 롤백 시작...');

          try {
            await userCredential.user!.delete();
            print('[AuthService] Auth 계정 삭제 성공 (롤백 완료)');
          } catch (deleteError) {
            print('[AuthService] ⚠️ Auth 계정 삭제 실패: $deleteError');
          }

          // Firestore 에러를 명확하게 전달
          throw _handleFirestoreException(firestoreError);
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('[AuthService] ❌ Firebase Auth 오류: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('[AuthService] ❌ 알 수 없는 오류: $e');
      rethrow;
    }
  }

  // 로그인
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('[AuthService] 로그인 시도: $email');
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('[AuthService] Firebase Auth 로그인 성공: ${userCredential.user?.uid}');

      // Firestore 사용자 문서 확인
      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        final userDoc = await _firestore.collection('users').doc(uid).get();

        if (!userDoc.exists) {
          // Firestore 문서가 없으면 자동 생성
          print('[AuthService] ⚠️ Firestore 사용자 문서가 없음. 자동 생성 시작...');
          try {
            final now = Timestamp.now();
            await _firestore.collection('users').doc(uid).set({
              'uid': uid,
              'email': userCredential.user!.email ?? email,
              'displayName': userCredential.user!.displayName ?? email.split('@')[0],
              'photoURL': userCredential.user!.photoURL,
              'isOnline': true,
              'lastSeen': now,
              'createdAt': now,
            });
            print('[AuthService] Firestore 사용자 문서 자동 생성 성공');
          } catch (e) {
            print('[AuthService] ❌ Firestore 사용자 문서 자동 생성 실패: $e');
            throw '사용자 프로필을 불러올 수 없습니다. Firestore 권한을 확인해주세요.';
          }
        } else {
          print('[AuthService] Firestore 사용자 문서 확인 완료');
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('[AuthService] ❌ Firebase Auth 로그인 오류: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('[AuthService] ❌ 로그인 중 알 수 없는 오류: $e');
      rethrow;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Firebase Auth 에러 처리
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
        case 'network-request-failed':
          return '네트워크 연결을 확인해주세요.';
        case 'too-many-requests':
          return '너무 많은 시도가 있었습니다. 잠시 후 다시 시도해주세요.';
        default:
          return '인증 오류가 발생했습니다: ${e.message}';
      }
    }
    return '알 수 없는 오류가 발생했습니다.';
  }

  // Firestore 에러 처리
  String _handleFirestoreException(dynamic e) {
    final errorString = e.toString().toLowerCase();

    if (errorString.contains('permission') || errorString.contains('denied')) {
      return 'Firestore 권한이 없습니다. Firebase Console에서 보안 규칙을 확인해주세요.';
    } else if (errorString.contains('network') || errorString.contains('unavailable')) {
      return '네트워크 연결을 확인해주세요.';
    } else if (errorString.contains('timeout')) {
      return 'Firestore 연결 시간이 초과되었습니다. 다시 시도해주세요.';
    } else if (errorString.contains('not-found')) {
      return 'Firestore 데이터베이스를 찾을 수 없습니다. Firebase Console에서 Firestore를 활성화해주세요.';
    } else {
      return 'Firestore 오류가 발생했습니다: $e';
    }
  }
}
