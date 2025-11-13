import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/user_avatar.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nicknameController;
  late TextEditingController _statusController;
  late FocusNode _nicknameFocusNode;
  late FocusNode _statusFocusNode;
  bool _isLoading = false;
  UserProvider? _userProvider; // Provider 인스턴스 저장

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();
    _statusController = TextEditingController();
    _nicknameFocusNode = FocusNode();
    _statusFocusNode = FocusNode();

    // 첫 프레임 렌더링 후 초기값 설정 및 리스너 등록
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Provider 인스턴스 저장 (dispose에서 사용)
      _userProvider = context.read<UserProvider>();

      final currentUser = _userProvider!.currentUser;
      if (currentUser != null) {
        _nicknameController.text = currentUser.displayName;
        _statusController.text = currentUser.statusMessage ?? '';
      }

      // Provider 리스너 등록 (사용자 데이터 변경 시 controller 업데이트)
      _userProvider!.addListener(_updateControllersFromProvider);
    });
  }

  @override
  void dispose() {
    // 리스너 먼저 제거 (저장된 인스턴스 사용, context 사용 안 함!)
    _userProvider?.removeListener(_updateControllersFromProvider);

    // 그 다음 controller와 FocusNode dispose
    _nicknameController.dispose();
    _statusController.dispose();
    _nicknameFocusNode.dispose();
    _statusFocusNode.dispose();
    super.dispose();
  }

  // Provider 변경 시 controller 업데이트 (사용자 입력 중이 아닐 때만)
  void _updateControllersFromProvider() {
    if (!mounted) return;

    final currentUser = _userProvider?.currentUser;
    if (currentUser == null) return;

    // 닉네임 필드가 포커스 중이 아닐 때만 업데이트
    if (!_nicknameFocusNode.hasFocus) {
      if (_nicknameController.text != currentUser.displayName) {
        _nicknameController.text = currentUser.displayName;
      }
    }

    // 상태 메시지 필드가 포커스 중이 아닐 때만 업데이트
    if (!_statusFocusNode.hasFocus) {
      final newStatus = currentUser.statusMessage ?? '';
      if (_statusController.text != newStatus) {
        _statusController.text = newStatus;
      }
    }
  }

  Future<void> _saveProfile() async {
    final nickname = _nicknameController.text.trim();
    final status = _statusController.text.trim();

    if (nickname.isEmpty) {
      _showSnackBar('닉네임을 입력해주세요', isError: true);
      return;
    }

    if (nickname.length < 2 || nickname.length > 20) {
      _showSnackBar('닉네임은 2-20자여야 합니다', isError: true);
      return;
    }

    if (status.length > 50) {
      _showSnackBar('상태 메시지는 50자 이하여야 합니다', isError: true);
      return;
    }

    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final uid = context.read<AuthProvider>().currentUser?.uid;
      if (uid == null) {
        _showSnackBar('사용자 정보를 찾을 수 없습니다', isError: true);
        return;
      }

      // Firestore 업데이트
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'displayName': nickname,
        'statusMessage': status.isEmpty ? null : status,
      });

      if (!mounted) return;

      // Provider 직접 업데이트 (로컬 상태)
      final currentUser = context.read<UserProvider>().currentUser;
      if (currentUser != null) {
        context.read<UserProvider>().updateCurrentUser(
              currentUser.copyWith(
                displayName: nickname,
                statusMessage: status.isEmpty ? null : status,
              ),
            );
      }

      _showSnackBar('프로필이 저장되었습니다');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('저장 실패: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      try {
        context.read<UserProvider>().clear();
        context.read<ChatProvider>().clear();
        await context.read<AuthProvider>().signOut();

        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        _showSnackBar('로그아웃 실패: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<UserProvider>().currentUser;
    final authUser = context.watch<AuthProvider>().currentUser;

    if (currentUser == null || authUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.kakaoYellow,
        title: const Text(
          '프로필',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                '저장',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // 프로필 사진
            UserAvatar(
              photoURL: currentUser.photoURL,
              isOnline: currentUser.isOnline,
              radius: 60,
              showOnlineIndicator: false,
            ),

            const SizedBox(height: 32),

            // 이메일 (읽기 전용)
            _buildReadOnlyField(
              label: '이메일',
              value: currentUser.email != 'no-email@example.com'
                  ? currentUser.email
                  : (authUser.email ?? currentUser.email),
            ),

            const SizedBox(height: 16),

            // 닉네임 (편집 가능)
            TextField(
              controller: _nicknameController,
              focusNode: _nicknameFocusNode,
              enabled: !_isLoading,
              maxLength: 20,
              decoration: InputDecoration(
                labelText: '닉네임',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.kakaoYellow,
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 상태 메시지 (편집 가능)
            TextField(
              controller: _statusController,
              focusNode: _statusFocusNode,
              enabled: !_isLoading,
              maxLength: 50,
              decoration: InputDecoration(
                labelText: '상태 메시지',
                hintText: '상태 메시지를 입력하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.kakaoYellow,
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 앱 정보
            Card(
              elevation: 0,
              color: Colors.grey[100],
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('앱 버전'),
                    subtitle: Text(AppInfo.version),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.code),
                    title: const Text('앱 이름'),
                    subtitle: Text(AppInfo.appName),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 로그아웃 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        '로그아웃',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}
