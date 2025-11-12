import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users';

  // Firestore에 사용자 정보 저장
  Future<void> createUser({
    required String uid,
    required String email,
    required String displayName,
    String? photoURL,
  }) async {
    try {
      final user = UserModel(
        uid: uid,
        email: email,
        displayName: displayName,
        photoURL: photoURL,
        createdAt: DateTime.now(),
        lastSeen: DateTime.now(),
        isOnline: true,
      );

      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .set(user.toJson());
    } catch (e) {
      throw Exception('사용자 정보 저장 실패: $e');
    }
  }

  // 사용자 정보 조회 (없으면 자동 생성)
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        try {
          return UserModel.fromJson(doc.data()!);
        } catch (e) {
          print('[UserService] ❌ 사용자 데이터 파싱 실패 ($uid): $e');
          print('[UserService] 데이터: ${doc.data()}');
          throw Exception('사용자 데이터 형식이 올바르지 않습니다: $e');
        }
      }

      // 사용자 문서가 없으면 null 반환 (AuthProvider에서 생성함)
      return null;
    } catch (e) {
      print('[UserService] ❌ 사용자 정보 조회 실패: $e');
      rethrow;
    }
  }

  // 사용자 정보 스트림
  Stream<UserModel?> getUserStream(String uid) {
    return _firestore
        .collection(_usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        try {
          return UserModel.fromJson(doc.data()!);
        } catch (e) {
          print('[UserService] ❌ 사용자 데이터 파싱 실패 ($uid): $e');
          return null;
        }
      }
      return null;
    });
  }

  // 사용자 정보 업데이트
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .update(data);
    } catch (e) {
      throw Exception('사용자 정보 업데이트 실패: $e');
    }
  }

  // 모든 사용자 목록 조회
  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection(_usersCollection)
        .orderBy('displayName')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          print('[UserService] 사용자 데이터 파싱: ${doc.id}');
          return UserModel.fromJson(data);
        } catch (e) {
          print('[UserService] ❌ 사용자 데이터 파싱 실패 (${doc.id}): $e');
          // 파싱 실패한 사용자는 기본값으로 생성
          return UserModel(
            uid: doc.id,
            email: 'error@example.com',
            displayName: '데이터 오류',
            photoURL: null,
            createdAt: DateTime.now(),
            lastSeen: DateTime.now(),
            isOnline: false,
          );
        }
      }).toList();
    });
  }

  // 사용자 검색 (이메일 또는 닉네임)
  Stream<List<UserModel>> searchUsers(String query) {
    return _firestore
        .collection(_usersCollection)
        .where('displayName', isGreaterThanOrEqualTo: query)
        .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return UserModel.fromJson(doc.data());
        } catch (e) {
          print('[UserService] ❌ 사용자 데이터 파싱 실패 (${doc.id}): $e');
          // 파싱 실패한 사용자는 기본값으로 생성
          return UserModel(
            uid: doc.id,
            email: 'error@example.com',
            displayName: '데이터 오류',
            photoURL: null,
            createdAt: DateTime.now(),
            lastSeen: DateTime.now(),
            isOnline: false,
          );
        }
      }).toList();
    });
  }

  // 온라인 상태 업데이트 (문서가 없으면 기본 정보로 생성)
  Future<void> updateOnlineStatus(String uid, bool isOnline) async {
    try {
      // 먼저 문서가 존재하는지 확인
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .get();

      if (doc.exists) {
        // 문서가 있으면 업데이트
        await _firestore
            .collection(_usersCollection)
            .doc(uid)
            .update({
          'isOnline': isOnline,
          'lastSeen': Timestamp.fromDate(DateTime.now()),
        });
      } else {
        // 문서가 없으면 set with merge로 생성
        await _firestore
            .collection(_usersCollection)
            .doc(uid)
            .set({
          'isOnline': isOnline,
          'lastSeen': Timestamp.fromDate(DateTime.now()),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // 에러 발생 시 조용히 무시 (온라인 상태는 중요하지 않음)
      print('온라인 상태 업데이트 실패: $e');
    }
  }

  // 프로필 사진 URL 업데이트
  Future<void> updatePhotoURL(String uid, String photoURL) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .update({'photoURL': photoURL});
    } catch (e) {
      throw Exception('프로필 사진 업데이트 실패: $e');
    }
  }

  // 닉네임 업데이트
  Future<void> updateDisplayName(String uid, String displayName) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .update({'displayName': displayName});
    } catch (e) {
      throw Exception('닉네임 업데이트 실패: $e');
    }
  }

  // 이메일로 사용자 검색
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      print('[UserService] 이메일로 사용자 검색: $email');
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('[UserService] 사용자를 찾을 수 없음: $email');
        return null;
      }

      final doc = querySnapshot.docs.first;
      try {
        final user = UserModel.fromJson(doc.data());
        print('[UserService] 사용자 찾음: ${user.displayName} (${user.uid})');
        return user;
      } catch (e) {
        print('[UserService] ❌ 사용자 데이터 파싱 실패: $e');
        return null;
      }
    } catch (e) {
      print('[UserService] ❌ 이메일 검색 실패: $e');
      throw Exception('사용자 검색 실패: $e');
    }
  }
}
