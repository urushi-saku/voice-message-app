// ========================================
// プロフィールページ
// ========================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../providers/auth_provider.dart';
import 'edit_profile_screen.dart';
import 'followers_tab.dart';
import 'settings_screen.dart';

/// プロフィール情報を表示・編集する画面
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  /// 画像パス → HTTP URL 変換ヘルパー
  static String _imgUrl(String path) {
    if (path.startsWith('http')) return path;
    return '$kServerUrl/$path';
  }

  /// ヘッダー上に重ねるアイコンボタン
  Widget _overlayButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black45,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;

        if (user == null) {
          return const Scaffold(body: Center(child: Text('ユーザー情報が見つかりません')));
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            top: true,
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
                          SizedBox(
                            height: 200,
                            width: double.infinity,
                            child: user.headerImage != null
                                ? Image.network(
                                    _imgUrl(user.headerImage!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _headerPlaceholder(),
                                  )
                                : _headerPlaceholder(),
                          ),
                          // アバター下半分 + 余白
                          const SizedBox(height: 52),
                        ],
                      ),

                      // 設定・編集ボタン（ヘッダー右上）
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Row(
                          children: [
                            _overlayButton(
                              icon: Icons.settings,
                              tooltip: '設定',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SettingsScreen(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _overlayButton(
                              icon: Icons.edit,
                              tooltip: 'プロフィール編集',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EditProfileScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // プロフィールアバター（ヘッダー下端に重なる）
                      Positioned(
                        top: 160, // 200 - radius(40)
                        left: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color(0xFF7C4DFF),
                            backgroundImage: user.profileImage != null
                                ? NetworkImage(_imgUrl(user.profileImage!))
                                : null,
                            child: user.profileImage == null
                                ? Text(
                                    user.username.isNotEmpty
                                        ? user.username[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ========================================
                  // プロフィール情報
                  // ========================================
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ユーザー名
                        Text(
                          user.username,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),

                        // ハンドル
                        Text(
                          '@${user.handle}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),

                        // 自己紹介
                        if (user.bio.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            user.bio,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              height: 1.4,
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),

                        // フォロー情報
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const FollowersTab(initialTabIndex: 0),
                                ),
                              ),
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${user.followersCount}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' フォロワー',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const FollowersTab(initialTabIndex: 1),
                                ),
                              ),
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${user.followingCount}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' フォロー中',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// ヘッダー未設定時のグラデーションプレースホルダー
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
}
