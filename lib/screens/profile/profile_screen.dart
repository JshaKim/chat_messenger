import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/user_service.dart';
import '../../widgets/user_avatar.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _imagePicker = ImagePicker();
  final _userService = UserService();

  // TextEditingControllers - 단순하게만 사용
  late final TextEditingController _nicknameController;
  late final TextEditingController _statusController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Controller 생성만
    _nicknameController = TextEditingController();
    _statusController = TextEditingController();
  }

  @override
  void dispose() {
    // Controller 해제만
    _nicknameController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    final nickname = _nicknameController.text.trim();
    final status = _statusController.text.trim();

    // Validation
    if (nickname.isEmpty) {
      _showSnackBar('닉네임을 입력해주세요', isError: true);
      return;
    }

    if (nickname.length < 2) {
      _showSnackBar('닉네임은 2자 이상이어야 합니다', isError: true);
      return;
    }

    if (nickname.length > 20) {
      _showSnackBar('닉네임은 20자 이하여야 합니다', isError: true);
      return;
    }

    if (status.length > 50) {
      _showSnackBar('상태 메시지는 50자 이하여야 합니다', isError: true);
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        _showSnackBar('사용자 정보를 찾을 수 없습니다', isError: true);
        return;
      }

      // Update nickname
      await _userService.updateDisplayName(currentUser.uid, nickname);

      // Update status message
      await _userService.updateStatusMessage(
        currentUser.uid,
        status.isEmpty ? null : status,
      );

      if (!mounted) return;

      // Reload user data
      await context.read<UserProvider>().loadCurrentUser(currentUser.uid);

      if (!mounted) return;

      // Controller 값 명시적 업데이트
      final updatedUser = context.read<UserProvider>().currentUser;
      if (updatedUser != null) {
        setState(() {
          _nicknameController.text = updatedUser.displayName;
          _statusController.text = updatedUser.statusMessage ?? '';
        });
      }

      _showSnackBar('프로필이 저장되었습니다');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('프로필 저장 실패: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleChangeProfilePhoto() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        final imageFile = File(pickedFile.path);
        final authProvider = context.read<AuthProvider>();
        final userProvider = context.read<UserProvider>();
        final currentUser = authProvider.currentUser;

        if (currentUser != null) {
          final success = await userProvider.updateProfilePhoto(
            uid: currentUser.uid,
            imageFile: imageFile,
          );

          if (!mounted) return;

          if (success) {
            _showSnackBar('프로필 사진이 변경되었습니다');
          } else if (userProvider.errorMessage != null) {
            _showSnackBar(userProvider.errorMessage!, isError: true);
            userProvider.clearError();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('이미지를 선택할 수 없습니다: $e', isError: true);
      }
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
      final authProvider = context.read<AuthProvider>();
      final userProvider = context.read<UserProvider>();
      final chatProvider = context.read<ChatProvider>();

      try {
        // Provider 초기화
        userProvider.clear();
        chatProvider.clear();

        // Firebase 로그아웃
        await authProvider.signOut();

        if (!mounted) return;

        // 모든 화면을 제거하고 로그인 화면으로 이동
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false, // 모든 이전 화면 제거
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
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.kakaoYellow,
        elevation: 0,
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
              onPressed: _handleSaveProfile,
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
      body: Consumer2<AuthProvider, UserProvider>(
        builder: (context, authProvider, userProvider, child) {
          final currentUser = userProvider.currentUser;
          final authUser = authProvider.currentUser;

          if (currentUser == null || authUser == null) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.kakaoYellow,
              ),
            );
          }

          // Controller 값 설정 (build 내에서)
          if (_nicknameController.text != currentUser.displayName) {
            _nicknameController.text = currentUser.displayName;
          }
          if (_statusController.text != (currentUser.statusMessage ?? '')) {
            _statusController.text = currentUser.statusMessage ?? '';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.lg),

                // 프로필 사진
                GestureDetector(
                  onTap: _handleChangeProfilePhoto,
                  child: Stack(
                    children: [
                      UserAvatar(
                        photoURL: currentUser.photoURL,
                        isOnline: currentUser.isOnline,
                        radius: 60,
                        showOnlineIndicator: false,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.kakaoYellow,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // 이메일 (읽기 전용)
                _buildReadOnlyField(
                  label: '이메일',
                  value: currentUser.email != 'no-email@example.com'
                      ? currentUser.email
                      : (authUser.email ?? currentUser.email),
                  icon: Icons.email,
                ),

                const SizedBox(height: AppSpacing.md),

                // 닉네임 (편집 가능)
                _buildEditableField(
                  label: '닉네임',
                  controller: _nicknameController,
                  icon: Icons.person,
                  maxLength: 20,
                  enabled: !_isLoading,
                ),

                const SizedBox(height: AppSpacing.md),

                // 상태 메시지 (편집 가능)
                _buildEditableField(
                  label: '상태 메시지',
                  controller: _statusController,
                  icon: Icons.chat_bubble_outline,
                  maxLength: 50,
                  hint: '상태 메시지를 입력하세요',
                  enabled: !_isLoading,
                ),

                const SizedBox(height: AppSpacing.xl),

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

                const SizedBox(height: AppSpacing.xl),

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
                        borderRadius: AppBorderRadius.circularSm,
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
                            style: AppTextStyles.button,
                          ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int? maxLength,
    String? hint,
    bool enabled = true,
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
        TextField(
          controller: controller,
          enabled: enabled,
          maxLength: maxLength,
          enableIMEPersonalizedLearning: true,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.kakaoYellow),
            hintText: hint,
            counterText: maxLength != null ? null : '',
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.kakaoYellow, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ),
      ],
    );
  }
}
