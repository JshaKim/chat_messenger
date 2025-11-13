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
  bool _isLoading = false;

  // 핵심 1: Provider 리스너를 별도로 관리
  VoidCallback? _providerListener;

  // 핵심 2: 사용자 입력 중인지 추적
  bool _isUserEditing = false;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();
    _statusController = TextEditingController();

    // 핵심 3: 컨트롤러에 직접 리스너 등록
    _nicknameController.addListener(_onUserEdit);
    _statusController.addListener(_onUserEdit);

    // 핵심 4: 첫 프레임 후 Provider 연결
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupProviderListener();
    });
  }

  void _onUserEdit() {
    // 사용자가 입력 중임을 표시
    _isUserEditing = true;
    // 3초 후 플래그 리셋 (디바운싱)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isUserEditing = false;
        });
      }
    });
  }

  void _setupProviderListener() {
    if (!mounted) return;

    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.currentUser;

    // 초기값 설정
    if (currentUser != null) {
      _nicknameController.text = currentUser.displayName;
      _statusController.text = currentUser.statusMessage ?? '';
    }

    // Provider 리스너 설정
    _providerListener = () {
      if (!mounted || _isUserEditing) return;

      final user = userProvider.currentUser;
      if (user != null) {
        // 값이 실제로 변경된 경우만 업데이트
        if (_nicknameController.text != user.displayName) {
          _nicknameController.text = user.displayName;
        }
        if (_statusController.text != (user.statusMessage ?? '')) {
          _statusController.text = user.statusMessage ?? '';
        }
      }
    };

    userProvider.addListener(_providerListener!);
  }

  @override
  void dispose() {
    // 핵심 5: 올바른 dispose 순서
    // 1. Provider 리스너 먼저 제거
    if (_providerListener != null) {
      try {
        context.read<UserProvider>().removeListener(_providerListener!);
      } catch (e) {
        // Context가 이미 dispose된 경우 무시
      }
    }

    // 2. 컨트롤러 리스너 제거
    _nicknameController.removeListener(_onUserEdit);
    _statusController.removeListener(_onUserEdit);

    // 3. 컨트롤러 dispose
    _nicknameController.dispose();
    _statusController.dispose();

    super.dispose();
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

      // Firestore 직접 업데이트 (Provider는 Stream으로 자동 업데이트됨)
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'displayName': nickname,
        'statusMessage': status.isEmpty ? null : status,
      });

      if (!mounted) return;

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
    // 핵심 6: build에서는 watch 사용 안 함 (read만 사용)
    final currentUser = context.read<UserProvider>().currentUser;
    final authUser = context.read<AuthProvider>().currentUser;

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
