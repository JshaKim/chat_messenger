import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/chat_room_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/user_avatar.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    // 채팅방 목록은 이미 HomeScreen에서 구독됨
  }

  Future<void> _navigateToChatRoom(
    BuildContext context,
    ChatRoomModel chatRoom,
  ) async {
    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final currentUserId = authProvider.currentUser?.uid;

    if (currentUserId == null) return;

    // 상대방 ID 찾기
    final otherUserId = chatRoom.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    if (otherUserId.isEmpty) return;

    // 상대방 정보 가져오기
    final otherUser = await userProvider.fetchUserById(otherUserId);

    if (!context.mounted) return;

    if (otherUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomScreen(
            chatRoomId: chatRoom.id,
            otherUser: otherUser,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEE500),
        elevation: 0,
        title: const Text(
          '채팅',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFEE500),
              ),
            );
          }

          if (chatProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    chatProvider.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            );
          }

          final chatRooms = chatProvider.chatRooms;

          if (chatRooms.isEmpty) {
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
                    '채팅방이 없습니다',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '친구 목록에서 채팅을 시작하세요',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index];
              return _buildChatRoomTile(context, chatRoom);
            },
          );
        },
      ),
    );
  }

  Widget _buildChatRoomTile(BuildContext context, ChatRoomModel chatRoom) {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.currentUser?.uid;

    if (currentUserId == null) {
      return const SizedBox.shrink();
    }

    // 상대방 ID 찾기
    final otherUserId = chatRoom.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    if (otherUserId.isEmpty) {
      return const SizedBox.shrink();
    }

    // 안읽은 메시지 개수
    final unreadCount = chatRoom.unreadCount[currentUserId] ?? 0;

    return FutureBuilder<UserModel?>(
      future: context.read<UserProvider>().fetchUserById(otherUserId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final otherUser = snapshot.data!;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: UserAvatar(
            photoURL: otherUser.photoURL,
            isOnline: otherUser.isOnline,
            radius: 28,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  otherUser.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (chatRoom.lastMessageTime != null)
                Text(
                  _formatTime(chatRoom.lastMessageTime!),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(
                  chatRoom.lastMessage ?? '',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
          onTap: () => _navigateToChatRoom(context, chatRoom),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return '방금';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return DateFormat('HH:mm').format(time);
    } else if (difference.inDays < 7) {
      return DateFormat('E요일').format(time);
    } else {
      return DateFormat('M/d').format(time);
    }
  }
}
