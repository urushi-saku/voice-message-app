// ========================================
// プロフィール編集画面
// ========================================
// ユーザーのプロフィール情報（ユーザー名、自己紹介、プロフィール画像）を
// 編集する画面です

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
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
  final _handleController = TextEditingController();
  final _bioController = TextEditingController();

  File? _selectedImage;
  File? _selectedHeaderImage;
  bool _isLoading = false;
  bool _isImageChanged = false;
  bool _isHeaderImageChanged = false;

  @override
  void initState() {
    super.initState();
    // 現在のユーザー情報を初期値として設定
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      _usernameController.text = authProvider.user!.username;
      _handleController.text = authProvider.user!.handle;
      _bioController.text = authProvider.user!.bio;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _handleController.dispose();
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

  /// 画像パス → HTTP URL 変換
  String _imgUrl(String path) {
    if (path.startsWith('http')) return path;
    return '$kServerUrl/$path';
  }

  /// ヘッダー未設定時のプレースホルダー
  Widget _headerPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C4DFF), Color(0xFF512DA8)],
        ),
      ),
    );
  }

  /// ========================================
  /// ヘッダー画像選択（ギャラリーから）
  /// ========================================
  Future<void> _pickHeaderImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedHeaderImage = File(image.path);
          _isHeaderImageChanged = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ヘッダー画像の選択に失敗しました: $e')));
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

      // ヘッダー画像が変更されている場合はアップロード
      if (_isHeaderImageChanged && _selectedHeaderImage != null) {
        await UserService.updateHeaderImage(_selectedHeaderImage!);
      }

      // ユーザー名またはhandleまたは自己紹介が変更されている場合は更新
      final usernameChanged = _usernameController.text != currentUser.username;
      final handleChanged =
          _handleController.text.toLowerCase().trim() != currentUser.handle;
      final bioChanged = _bioController.text != currentUser.bio;

      if (usernameChanged || handleChanged || bioChanged) {
        await UserService.updateProfile(
          username: usernameChanged ? _usernameController.text : null,
          handle: handleChanged
              ? _handleController.text.toLowerCase().trim()
              : null,
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
      debugPrint('プロフィール更新エラー詳細: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('プロフィールの更新に失敗しました:\n$e'),
          duration: const Duration(seconds: 10),
        ),
      );
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
      appBar: AppBar(title: const Text('プロフィール編集'), elevation: 0),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========================================
              // ヘッダー画像 ＋ アバター セクション
              // ========================================
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    children: [
                      // ヘッダー画像（200px）
                      GestureDetector(
                        onTap: _isLoading ? null : _pickHeaderImage,
                        child: SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _selectedHeaderImage != null
                                  ? Image.file(
                                      _selectedHeaderImage!,
                                      fit: BoxFit.cover,
                                    )
                                  : (currentUser.headerImage != null
                                        ? Image.network(
                                            _imgUrl(currentUser.headerImage!),
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _headerPlaceholder(),
                                          )
                                        : _headerPlaceholder()),
                              const Center(
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.black45,
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 52),
                    ],
                  ),
                  // プロフィールアバター（ヘッダー下端に重なる）
                  Positioned(
                    top: 160,
                    left: 16,
                    child: GestureDetector(
                      onTap: _isLoading ? null : _pickImage,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: const Color(0xFF7C4DFF),
                              backgroundImage: _selectedImage != null
                                  ? FileImage(_selectedImage!)
                                  : (currentUser.profileImage != null
                                            ? NetworkImage(
                                                _imgUrl(
                                                  currentUser.profileImage!,
                                                ),
                                              )
                                            : null)
                                        as ImageProvider?,
                              child:
                                  _selectedImage == null &&
                                      currentUser.profileImage == null
                                  ? Text(
                                      currentUser.username.isNotEmpty
                                          ? currentUser.username[0]
                                                .toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor,
                                radius: 14,
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ========================================
              // フォーム
              // ========================================
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'アバター・ヘッダー画像をタップして変更',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),

                    const SizedBox(height: 24),

                    // ========================================
                    // ユーザー名入力
                    // ========================================
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'ユーザー名（表示名）',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'ユーザー名を入力してください';
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
                    // ID入力
                    // ========================================
                    TextFormField(
                      controller: _handleController,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: 'ID（@handle）',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.alternate_email),
                        prefixText: '@',
                        helperText: '英小文字・数字・_の3〜20文字',
                        helperStyle: TextStyle(color: Colors.grey[600]),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'IDを入力してください';
                        }
                        final regex = RegExp(r'^[a-z0-9_]{3,20}$');
                        if (!regex.hasMatch(value.toLowerCase().trim())) {
                          return 'IDは英小文字・数字・_の3〜20文字で入力してください';
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
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
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

                    // ========================================
                    // 保存ボタン
                    // ========================================
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C4DFF),
                          disabledBackgroundColor: Colors.grey[400],
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
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'プロフィールを保存',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
