import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../services/storage_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final StorageService _storageService = StorageService();

  List<ChatRoomModel> _chatRooms = [];
  ChatRoomModel? _currentChatRoom;
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;
  int _totalUnreadCount = 0;

  List<ChatRoomModel> get chatRooms => _chatRooms;
  ChatRoomModel? get currentChatRoom => _currentChatRoom;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  int get totalUnreadCount => _totalUnreadCount;

  // 채팅방 목록 스트림 구독
  void subscribeToChatRooms(String userId) {
    _chatService.getChatRooms(userId).listen(
      (chatRooms) {
        _chatRooms = chatRooms;
        notifyListeners();
      },
      onError: (error) {
        _setError(error.toString());
      },
    );
  }

  // 전체 안읽은 메시지 개수 스트림 구독
  void subscribeToUnreadCount(String userId) {
    _chatService.getTotalUnreadCount(userId).listen(
      (count) {
        _totalUnreadCount = count;
        notifyListeners();
      },
      onError: (error) {
        _setError(error.toString());
      },
    );
  }

  // 채팅방 생성 또는 가져오기
  Future<String?> getOrCreateChatRoom({
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final chatRoomId = await _chatService.getOrCreateChatRoom(
        currentUserId: currentUserId,
        otherUserId: otherUserId,
      );

      _setLoading(false);
      return chatRoomId;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  // 현재 채팅방 설정 및 메시지 구독
  void setCurrentChatRoom(String chatRoomId) {
    // 현재 채팅방 정보 구독
    _chatService.getChatRoomStream(chatRoomId).listen(
      (chatRoom) {
        _currentChatRoom = chatRoom;
        notifyListeners();
      },
      onError: (error) {
        _setError(error.toString());
      },
    );

    // 메시지 목록 구독
    _chatService.getMessages(chatRoomId).listen(
      (messages) {
        _messages = messages;
        notifyListeners();
      },
      onError: (error) {
        _setError(error.toString());
      },
    );
  }

  // 텍스트 메시지 전송
  Future<bool> sendTextMessage({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    try {
      _setSending(true);
      _clearError();

      await _chatService.sendMessage(
        chatRoomId: chatRoomId,
        senderId: senderId,
        senderName: senderName,
        text: text,
      );

      _setSending(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setSending(false);
      return false;
    }
  }

  // 이미지 메시지 전송
  Future<bool> sendImageMessage({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required File imageFile,
  }) async {
    try {
      _setSending(true);
      _clearError();

      // Storage에 이미지 업로드
      final imageUrl = await _storageService.uploadChatImage(
        chatRoomId: chatRoomId,
        imageFile: imageFile,
      );

      // 메시지 전송
      await _chatService.sendMessage(
        chatRoomId: chatRoomId,
        senderId: senderId,
        senderName: senderName,
        text: '',
        imageUrl: imageUrl,
      );

      _setSending(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setSending(false);
      return false;
    }
  }

  // 메시지 읽음 처리
  Future<void> markMessagesAsRead({
    required String chatRoomId,
    required String userId,
  }) async {
    try {
      await _chatService.markMessagesAsRead(
        chatRoomId: chatRoomId,
        userId: userId,
      );
    } catch (e) {
      _setError(e.toString());
    }
  }

  // 채팅방 ID로 채팅방 찾기 (로컬 캐시에서)
  ChatRoomModel? getChatRoomById(String chatRoomId) {
    try {
      return _chatRooms.firstWhere((room) => room.id == chatRoomId);
    } catch (e) {
      return null;
    }
  }

  // 채팅방 정보 가져오기 (Firestore에서 직접)
  Future<ChatRoomModel?> fetchChatRoom(String chatRoomId) async {
    try {
      return await _chatService.getChatRoom(chatRoomId);
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  // 현재 채팅방 클리어
  void clearCurrentChatRoom() {
    _currentChatRoom = null;
    _messages = [];
    notifyListeners();
  }

  // 로딩 상태 설정
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // 전송 중 상태 설정
  void _setSending(bool value) {
    _isSending = value;
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
    _chatRooms = [];
    _currentChatRoom = null;
    _messages = [];
    _errorMessage = null;
    _isLoading = false;
    _isSending = false;
    _totalUnreadCount = 0;
    notifyListeners();
  }
}
