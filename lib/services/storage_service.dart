import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  // 프로필 사진 업로드
  Future<String> uploadProfileImage({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final fileName = '${_uuid.v4()}.jpg';
      final ref = _storage.ref().child('profile_images/$userId/$fileName');

      // 메타데이터 설정
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // 업로드
      final uploadTask = await ref.putFile(imageFile, metadata);

      // 다운로드 URL 가져오기
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('프로필 사진 업로드 실패: $e');
    }
  }

  // 채팅 이미지 업로드
  Future<String> uploadChatImage({
    required String chatRoomId,
    required File imageFile,
  }) async {
    try {
      final fileName = '${_uuid.v4()}.jpg';
      final ref = _storage.ref().child('chat_images/$chatRoomId/$fileName');

      // 메타데이터 설정
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'chatRoomId': chatRoomId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // 업로드
      final uploadTask = await ref.putFile(imageFile, metadata);

      // 다운로드 URL 가져오기
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('채팅 이미지 업로드 실패: $e');
    }
  }

  // 이미지 삭제 (URL로부터)
  Future<void> deleteImageByUrl(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('이미지 삭제 실패: $e');
    }
  }

  // 사용자의 모든 프로필 이미지 삭제
  Future<void> deleteAllProfileImages(String userId) async {
    try {
      final ref = _storage.ref().child('profile_images/$userId');
      final listResult = await ref.listAll();

      for (var item in listResult.items) {
        await item.delete();
      }
    } catch (e) {
      throw Exception('프로필 이미지 삭제 실패: $e');
    }
  }

  // 업로드 진행률을 스트림으로 반환 (선택적 기능)
  Stream<double> uploadProfileImageWithProgress({
    required String userId,
    required File imageFile,
  }) {
    final fileName = '${_uuid.v4()}.jpg';
    final ref = _storage.ref().child('profile_images/$userId/$fileName');

    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {
        'userId': userId,
        'uploadedAt': DateTime.now().toIso8601String(),
      },
    );

    final uploadTask = ref.putFile(imageFile, metadata);

    return uploadTask.snapshotEvents.map((snapshot) {
      return snapshot.bytesTransferred / snapshot.totalBytes;
    });
  }

  // 채팅 이미지 업로드 진행률 (선택적 기능)
  Stream<double> uploadChatImageWithProgress({
    required String chatRoomId,
    required File imageFile,
  }) {
    final fileName = '${_uuid.v4()}.jpg';
    final ref = _storage.ref().child('chat_images/$chatRoomId/$fileName');

    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {
        'chatRoomId': chatRoomId,
        'uploadedAt': DateTime.now().toIso8601String(),
      },
    );

    final uploadTask = ref.putFile(imageFile, metadata);

    return uploadTask.snapshotEvents.map((snapshot) {
      return snapshot.bytesTransferred / snapshot.totalBytes;
    });
  }
}
