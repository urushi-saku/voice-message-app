// ========================================
// 他ユーザーのプロフィール画面
// ========================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
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

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  // 自分がこのユーザーをフォロー中か確認
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

  // フォロー/フォロー解除
  Future<void> _toggleFollow() async {
    setState(() => _isProcessing = true);
    try {
      if (_isFollowing) {
        await UserService.unfollowUser(widget.user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${widget.user.username}のフォローを解除しました')),
          );
        }
      } else {
        await UserService.followUser(widget.user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${widget.user.username}をフォローしました')),
          );
        }
      }
      // プロフィールのフォロー数を即座に反映
      if (mounted) {
        await context.read<AuthProvider>().loadUserInfo();
        setState(() => _isFollowing = !_isFollowing);
      }
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

  @override
  Widget build(BuildContext context) {
    // Sliverを使ったリッチなスクロールUIに変更
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ========================================
          // 伸縮するヘッダー (SliverAppBar)
          // ========================================
          SliverAppBar(
            expandedHeight: 280.0,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF512DA8),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // 背景グラデーション
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          Color(0xFF7C4DFF),
                          Color(0xFF512DA8),
                          Color(0xFF311B92),
                        ],
                      ),
                    ),
                  ),
                  // 装飾的な円（デザインアクセント）
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  // プロフィール画像（大きく表示）
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40), // AppBar分の余白
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white,
                            backgroundImage: widget.user.profileImage != null
                                ? NetworkImage(widget.user.profileImage!)
                                : null,
                            child: widget.user.profileImage == null
                                ? Text(
                                    widget.user.username[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 50,
                                      color: Color(0xFF512DA8),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.user.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '@${widget.user.handle}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ========================================
          // コンテンツ部分
          // ========================================
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              transform: Matrix4.translationValues(0, -20, 0), // 少し上に重ねる
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ハンドルバー（装飾）
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // 自己紹介
                    if (widget.user.bio.isNotEmpty) ...[
                      const Text(
                        "About",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.user.bio,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // アクションボタンエリア
                    Row(
                      children: [
                        // フォローボタン
                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
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
                                            fontSize: 16,
                                          ),
                                        ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        // メッセージボタン
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecordingScreen(
                                recipientIds: [widget.user.id],
                                recipientUsername: widget.user.username,
                                recipientProfileImage: widget.user.profileImage,
                              ),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE7F6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF7C4DFF).withOpacity(0.3),
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
            ),
          ),
        ],
      ),
    );
  }
}
