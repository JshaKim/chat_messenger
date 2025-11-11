import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _chatRoomsCollection = 'chatRooms';
  final String _messagesCollection = 'messages';
  final _uuid = const Uuid();

  // 채팅방 생성 또는 가져오기 (1:1 채팅)
  Future<String> getOrCreateChatRoom({
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      // 두 사용자 ID를 정렬하여 고유한 채팅방 ID 생성
      final participants = [currentUserId, otherUserId]..sort();
      final chatRoomId = participants.join('_');

      // 채팅방이 이미 존재하는지 확인
      final chatRoomDoc = await _firestore
          .collection(_chatRoomsCollection)
          .doc(chatRoomId)
          .get();

      if (!chatRoomDoc.exists) {
        // 채팅방 생성
        final chatRoom = ChatRoomModel(
          id: chatRoomId,
          participants: participants,
          lastMessage: null,
          lastMessageTime: null,
          unreadCount: {
            currentUserId: 0,
            otherUserId: 0,
          },
        );

        await _firestore
            .collection(_chatRoomsCollection)
            .doc(chatRoomId)
            .set(chatRoom.toJson());
      }

      return chatRoomId;
    } catch (e) {
      throw Exception('채팅방 생성 실패: $e');
    }
  }

  // 메시지 전송
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required String text,
    String? imageUrl,
  }) async {
    try {
      final messageId = _uuid.v4();
      final now = DateTime.now();

      final message = MessageModel(
        id: messageId,
        chatRoomId: chatRoomId,
        senderId: senderId,
        senderName: senderName,
        text: text,
        imageUrl: imageUrl,
        timestamp: now,
        isRead: false,
      );

      // 메시지 저장
      await _firestore
          .collection(_chatRoomsCollection)
          .doc(chatRoomId)
          .collection(_messagesCollection)
          .doc(messageId)
          .set(message.toJson());

      // 채팅방 정보 업데이트 (마지막 메시지, 안읽은 메시지 개수)
      final chatRoomRef = _firestore
          .collection(_chatRoomsCollection)
          .doc(chatRoomId);

      final chatRoomDoc = await chatRoomRef.get();
      if (chatRoomDoc.exists) {
        final chatRoom = ChatRoomModel.fromJson(chatRoomDoc.data()!);
        final otherUserId = chatRoom.participants
            .firstWhere((id) => id != senderId);

        await chatRoomRef.update({
          'lastMessage': text.isNotEmpty ? text : '이미지',
          'lastMessageTime': Timestamp.fromDate(now),
          'unreadCount.$otherUserId': FieldValue.increment(1),
        });
      }
    } catch (e) {
      throw Exception('메시지 전송 실패: $e');
    }
  }

  // 메시지 스트림 가져오기
  Stream<List<MessageModel>> getMessages(String chatRoomId) {
    return _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .collection(_messagesCollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromJson(doc.data()))
          .toList();
    });
  }

  // 채팅방 목록 조회
  Stream<List<ChatRoomModel>> getChatRooms(String userId) {
    return _firestore
        .collection(_chatRoomsCollection)
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatRoomModel.fromJson(doc.data()))
          .toList();
    });
  }

  // 채팅방 정보 가져오기
  Future<ChatRoomModel?> getChatRoom(String chatRoomId) async {
    try {
      final doc = await _firestore
          .collection(_chatRoomsCollection)
          .doc(chatRoomId)
          .get();

      if (doc.exists && doc.data() != null) {
        return ChatRoomModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('채팅방 정보 조회 실패: $e');
    }
  }

  // 채팅방 스트림
  Stream<ChatRoomModel?> getChatRoomStream(String chatRoomId) {
    return _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return ChatRoomModel.fromJson(doc.data()!);
      }
      return null;
    });
  }

  // 메시지 읽음 처리
  Future<void> markMessagesAsRead({
    required String chatRoomId,
    required String userId,
  }) async {
    try {
      // 채팅방의 안읽은 메시지 개수 초기화
      await _firestore
          .collection(_chatRoomsCollection)
          .doc(chatRoomId)
          .update({
        'unreadCount.$userId': 0,
      });

      // 해당 채팅방의 읽지 않은 메시지들을 읽음으로 표시
      final messagesSnapshot = await _firestore
          .collection(_chatRoomsCollection)
          .doc(chatRoomId)
          .collection(_messagesCollection)
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('메시지 읽음 처리 실패: $e');
    }
  }

  // 안읽은 전체 메시지 개수
  Stream<int> getTotalUnreadCount(String userId) {
    return _firestore
        .collection(_chatRoomsCollection)
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
        if (unreadCount != null && unreadCount[userId] != null) {
          total += (unreadCount[userId] as int);
        }
      }
      return total;
    });
  }
}
