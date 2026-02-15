// ========================================
// プロフィール編集画面
// ========================================
// ユーザーのプロフィール情報（ユーザー名、自己紹介、プロフィール画像）を
// 編集する画面です

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';

/// プロフィール編集画面
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;
  bool _isImageChanged = false;

  @override
  void initState() {
    super.initState();
    // 現在のユーザー情報を初期値として設定
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      _usernameController.text = authProvider.user!.username;
      _bioController.text = authProvider.user!.bio;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  /// ========================================
  /// 画像選択（ギャラリーから）
  /// ========================================
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _isImageChanged = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('画像の選択に失敗しました: $e')));
    }
  }

  /// ========================================
  /// プロフィール更新処理
  /// ========================================
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user!;

      // プロフィール画像が変更されている場合は先にアップロード
      if (_isImageChanged && _selectedImage != null) {
        await UserService.updateProfileImage(_selectedImage!);
      }

      // ユーザー名または自己紹介が変更されている場合は更新
      final usernameChanged = _usernameController.text != currentUser.username;
      final bioChanged = _bioController.text != currentUser.bio;

      if (usernameChanged || bioChanged) {
        await UserService.updateProfile(
          username: usernameChanged ? _usernameController.text : null,
          bio: bioChanged ? _bioController.text : null,
        );
      }

      // 認証プロバイダーのユーザー情報を更新
      await authProvider.loadUserInfo();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('プロフィールを更新しました')));

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('プロフィールの更新に失敗しました: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('ユーザー情報が見つかりません')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール編集'),
        elevation: 0,
        actions: [
          // 保存ボタン
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _updateProfile,
              child: const Text(
                '保存',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),

                // ========================================
                // プロフィール画像
                // ========================================
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.deepPurple,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : (currentUser.profileImage != null
                                      ? NetworkImage(currentUser.profileImage!)
                                      : null)
                                  as ImageProvider?,
                        child:
                            _selectedImage == null &&
                                currentUser.profileImage == null
                            ? const Icon(
                                Icons.person,
                                size: 70,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          radius: 18,
                          child: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                Text(
                  'タップして画像を選択',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),

                const SizedBox(height: 32),

                // ========================================
                // ユーザー名入力
                // ========================================
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'ユーザー名',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'ユーザー名を入力してください';
                    }
                    if (value.trim().length < 3) {
                      return 'ユーザー名は3文字以上必要です';
                    }
                    if (value.trim().length > 30) {
                      return 'ユーザー名は30文字以内で設定してください';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),

                const SizedBox(height: 16),

                // ========================================
                // 自己紹介入力
                // ========================================
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: '自己紹介',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.info_outline),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  maxLength: 200,
                  validator: (value) {
                    if (value != null && value.length > 200) {
                      return '自己紹介は200文字以内で設定してください';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),

                const SizedBox(height: 24),

                // ========================================
                // メールアドレス表示（変更不可）
                // ========================================
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email, color: Colors.grey),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'メールアドレス',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentUser.email,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                Text(
                  '※メールアドレスは変更できません',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
