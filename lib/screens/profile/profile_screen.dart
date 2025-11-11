import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/user_avatar.dart';
import '../../utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _imagePicker = ImagePicker();

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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('프로필 사진이 변경되었습니다'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (userProvider.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(userProvider.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
            userProvider.clearError();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지를 선택할 수 없습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleChangeDisplayName() async {
    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final currentUser = authProvider.currentUser;
    final currentDisplayName = userProvider.currentUser?.displayName ?? '';

    if (currentUser == null) return;

    final TextEditingController controller = TextEditingController(
      text: currentDisplayName,
    );

    final newDisplayName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('닉네임 변경'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '새 닉네임',
            hintText: '2-20자',
          ),
          maxLength: 20,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty && text.length >= 2) {
                Navigator.pop(context, text);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('닉네임은 2자 이상이어야 합니다'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('변경'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (newDisplayName != null && newDisplayName != currentDisplayName) {
      final success = await userProvider.updateDisplayName(
        uid: currentUser.uid,
        displayName: newDisplayName,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('닉네임이 변경되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (userProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userProvider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
        userProvider.clearError();
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
      final chatProvider = context.read<UserProvider>();

      await authProvider.signOut();

      // Provider 초기화
      userProvider.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그아웃되었습니다'),
          backgroundColor: Colors.green,
        ),
      );
    }
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

                const SizedBox(height: AppSpacing.lg),

                // 닉네임
                Text(
                  currentUser.displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // 이메일
                Text(
                  currentUser.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // 정보 카드
                Card(
                  elevation: 0,
                  color: Colors.grey[100],
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('닉네임 변경'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _handleChangeDisplayName,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: const Text('이메일'),
                        subtitle: Text(currentUser.email),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          Icons.circle,
                          color: currentUser.isOnline
                              ? Colors.green
                              : Colors.grey,
                          size: 16,
                        ),
                        title: const Text('상태'),
                        subtitle: Text(
                          currentUser.isOnline ? '온라인' : '오프라인',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

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
                    onPressed: _handleLogout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppBorderRadius.circularSm,
                      ),
                    ),
                    child: const Text(
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
}
