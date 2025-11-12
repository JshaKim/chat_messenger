import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/user_avatar.dart';
import '../chat/chat_room_screen.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // 모든 사용자 목록 구독
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().subscribeToAllUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '로그아웃',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = context.read<AuthProvider>();
      final userProvider = context.read<UserProvider>();
      final chatProvider = context.read<ChatProvider>();

      await authProvider.signOut();

      // Provider 초기화
      userProvider.clear();
      chatProvider.clear();
    }
  }

  Future<void> _navigateToChat(BuildContext context, UserModel otherUser) async {
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

    // 채팅방 생성 또는 가져오기
    final chatRoomId = await chatProvider.getOrCreateChatRoom(
      currentUserId: currentUser.uid,
      otherUserId: otherUser.uid,
    );

    if (!context.mounted) return;

    if (chatRoomId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomScreen(
            chatRoomId: chatRoomId,
            otherUser: otherUser,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('채팅방을 열 수 없습니다'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userProvider = context.watch<UserProvider>();
    final currentUserId = authProvider.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEE500),
        elevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '이름 검색...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.black54),
                ),
                style: const TextStyle(color: Colors.black87),
                onChanged: (value) {
                  setState(() {});
                },
              )
            : const Text(
                '친구',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          _isSearching
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.black87),
                  onPressed: _stopSearch,
                )
              : IconButton(
                  icon: const Icon(Icons.search, color: Colors.black87),
                  onPressed: _startSearch,
                ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: _handleLogout,
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFEE500),
              ),
            );
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '친구 목록 불러오기 실패',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Firestore 보안 규칙을 확인해주세요\n• 네트워크 연결을 확인해주세요\n• 사용자 데이터 형식을 확인해주세요',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        provider.clearError();
                        provider.subscribeToAllUsers();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('다시 시도'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEE500),
                        foregroundColor: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // 현재 사용자 제외 및 검색 필터
          final searchQuery = _searchController.text.toLowerCase();
          final filteredUsers = provider.users.where((user) {
            if (user.uid == currentUserId) return false;
            if (searchQuery.isNotEmpty) {
              return user.displayName.toLowerCase().contains(searchQuery) ||
                  user.email.toLowerCase().contains(searchQuery);
            }
            return true;
          }).toList();

          if (filteredUsers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isSearching ? Icons.search_off : Icons.people_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isSearching ? '검색 결과가 없습니다' : '등록된 사용자가 없습니다',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              return _buildUserTile(user);
            },
          );
        },
      ),
    );
  }

  Widget _buildUserTile(UserModel user) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      leading: UserAvatar(
        photoURL: user.photoURL,
        isOnline: user.isOnline,
        radius: 28,
      ),
      title: Text(
        user.displayName,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        user.isOnline ? '온라인' : _formatLastSeen(user.lastSeen),
        style: TextStyle(
          color: user.isOnline ? Colors.green : Colors.grey[600],
          fontSize: 13,
        ),
      ),
      onTap: () => _navigateToChat(context, user),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${lastSeen.year}.${lastSeen.month}.${lastSeen.day}';
    }
  }
}
