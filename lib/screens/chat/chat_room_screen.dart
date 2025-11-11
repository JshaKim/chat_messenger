import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../models/user_model.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/chat_input_field.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatRoomId;
  final UserModel otherUser;

  const ChatRoomScreen({
    super.key,
    required this.chatRoomId,
    required this.otherUser,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeChatRoom();
  }

  void _initializeChatRoom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<ChatProvider>();
      final authProvider = context.read<AuthProvider>();
      final currentUserId = authProvider.currentUser?.uid;

      // 현재 채팅방 설정 및 메시지 구독
      chatProvider.setCurrentChatRoom(widget.chatRoomId);

      // 메시지 읽음 처리
      if (currentUserId != null) {
        chatProvider.markMessagesAsRead(
          chatRoomId: widget.chatRoomId,
          userId: currentUserId,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // 채팅방 나갈 때 현재 채팅방 클리어
    context.read<ChatProvider>().clearCurrentChatRoom();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSendText(String text) async {
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

    final success = await chatProvider.sendTextMessage(
      chatRoomId: widget.chatRoomId,
      senderId: currentUser.uid,
      senderName: currentUser.displayName ?? 'Unknown',
      text: text,
    );

    if (success) {
      _scrollToBottom();
    } else if (chatProvider.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(chatProvider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      chatProvider.clearError();
    }
  }

  Future<void> _handleSendImage(File imageFile) async {
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

    final success = await chatProvider.sendImageMessage(
      chatRoomId: widget.chatRoomId,
      senderId: currentUser.uid,
      senderName: currentUser.displayName ?? 'Unknown',
      imageFile: imageFile,
    );

    if (success) {
      _scrollToBottom();
    } else if (chatProvider.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(chatProvider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      chatProvider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEE500),
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            UserAvatar(
              photoURL: widget.otherUser.photoURL,
              isOnline: widget.otherUser.isOnline,
              radius: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.displayName,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    widget.otherUser.isOnline ? '온라인' : '오프라인',
                    style: TextStyle(
                      color: widget.otherUser.isOnline
                          ? Colors.green
                          : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 메시지 목록
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final messages = chatProvider.messages;

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '메시지를 보내보세요',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // 메시지 목록 표시 (역순 - 최신 메시지가 아래)
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // 최신 메시지가 아래로
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;

                    return MessageBubble(
                      message: message,
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),

          // 메시지 입력 필드
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              return ChatInputField(
                onSendText: _handleSendText,
                onSendImage: _handleSendImage,
                isSending: chatProvider.isSending,
              );
            },
          ),
        ],
      ),
    );
  }
}
