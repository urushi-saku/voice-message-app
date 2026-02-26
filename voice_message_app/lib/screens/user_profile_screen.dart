// ========================================
// 他ユーザーのプロフィール画面
// ========================================
// 自分のプロフィール(profile_page.dart)と同じレイアウトで表示
// フォローボタン・ボイスメッセージボタンを保持

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import 'followers_tab.dart';
import 'recording_screen.dart';

/// 他ユーザーのプロフィールを表示する画面
class UserProfileScreen extends StatefulWidget {
  final UserInfo user;

  const UserProfileScreen({super.key, required this.user});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isFollowing = false;
  bool _isLoading = true;
  bool _isProcessing = false;

  // フォロワー/フォロー数をローカルで管理（フォロー操作後に即時反映）
  late int _followersCount;
  late int _followingCount;

  @override
  void initState() {
    super.initState();
    _followersCount = widget.user.followersCount;
    _followingCount = widget.user.followingCount;
    _checkFollowStatus();
  }

  // ========================================
  // 画像パス → HTTP URL 変換
  // ========================================
  static String _imgUrl(String path) {
    if (path.startsWith('http')) return path;
    return '$kServerUrl/$path';
  }

  // ========================================
  // フォロー状態を確認
  // ========================================
  Future<void> _checkFollowStatus() async {
    try {
      final myId = context.read<AuthProvider>().user?.id;
      if (myId == null) return;

      final following = await UserService.getFollowing(myId);
      if (mounted) {
        setState(() {
          _isFollowing = following.any((u) => u.id == widget.user.id);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ========================================
  // フォロー / フォロー解除
  // ========================================
  Future<void> _toggleFollow() async {
    setState(() => _isProcessing = true);
    try {
      if (_isFollowing) {
        await UserService.unfollowUser(widget.user.id);
        if (mounted) {
          setState(() {
            _isFollowing = false;
            _followersCount = (_followersCount - 1).clamp(0, 999999);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${widget.user.username}のフォローを解除しました')),
          );
        }
      } else {
        await UserService.followUser(widget.user.id);
        if (mounted) {
          setState(() {
            _isFollowing = true;
            _followersCount += 1;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${widget.user.username}をフォローしました')),
          );
        }
      }
      // 自分のフォロー数も更新
      if (mounted) await context.read<AuthProvider>().loadUserInfo();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラー: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ========================================
  // ヘッダー未設定時のプレースホルダー
  // ========================================
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

  // ========================================
  // ヘッダー上に重ねるアイコンボタン
  // ========================================
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
    final user = widget.user;

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

                  // 左上：戻るボタン
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _overlayButton(
                      icon: Icons.arrow_back,
                      tooltip: '戻る',
                      onTap: () => Navigator.pop(context),
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
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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

                    // フォロー情報（タップでフォロワー一覧へ）
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FollowersTab(
                                initialTabIndex: 0,
                                targetUserId: user.id,
                              ),
                            ),
                          ),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$_followersCount',
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
                              builder: (_) => FollowersTab(
                                initialTabIndex: 1,
                                targetUserId: user.id,
                              ),
                            ),
                          ),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$_followingCount',
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

                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 20),

                    // ========================================
                    // アクションボタン（フォロー ＋ ボイスメッセージ）
                    // ========================================
                    Row(
                      children: [
                        // フォローボタン
                        Expanded(
                          child: _isLoading
                              ? const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: _isProcessing
                                      ? null
                                      : _toggleFollow,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isFollowing
                                        ? Colors.grey[200]
                                        : const Color(0xFF7C4DFF),
                                    foregroundColor: _isFollowing
                                        ? Colors.black87
                                        : Colors.white,
                                    elevation: _isFollowing ? 0 : 4,
                                    shadowColor: const Color(
                                      0xFF7C4DFF,
                                    ).withValues(alpha: 0.4),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _isProcessing
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          _isFollowing ? 'フォロー中' : 'フォローする',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                ),
                        ),
                        const SizedBox(width: 12),

                        // ボイスメッセージボタン（マイクアイコン）
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecordingScreen(
                                recipientIds: [user.id],
                                recipientUsername: user.username,
                                recipientProfileImage: user.profileImage,
                              ),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE7F6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(
                                  0xFF7C4DFF,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Icon(
                              Icons.mic_rounded,
                              color: Color(0xFF7C4DFF),
                              size: 24,
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
  }
}
