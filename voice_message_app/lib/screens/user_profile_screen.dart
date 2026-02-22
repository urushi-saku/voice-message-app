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
    return Scaffold(
      appBar: AppBar(title: Text(widget.user.username), elevation: 0),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ========================================
              // ユーザーアイコン
              // ========================================
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.deepPurple,
                backgroundImage: widget.user.profileImage != null
                    ? NetworkImage(widget.user.profileImage!)
                    : null,
                child: widget.user.profileImage == null
                    ? Text(
                        widget.user.username[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),

              const SizedBox(height: 24),

              // ========================================
              // ユーザー名
              // ========================================
              Text(
                widget.user.username,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // ========================================
              // ユーザーID
              // ========================================
              Text(
                '@${widget.user.handle}',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),

              const SizedBox(height: 24),

              // ========================================
              // 自己紹介
              // ========================================
              if (widget.user.bio.isNotEmpty) ...[
                Text(
                  widget.user.bio,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 24),
              ],

              // ========================================
              // フォロー/フォロー解除ボタン
              // ========================================
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _toggleFollow,
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                _isFollowing
                                    ? Icons.person_remove
                                    : Icons.person_add,
                              ),
                        label: Text(_isFollowing ? 'フォロー解除' : 'フォローする'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFollowing
                              ? Colors.grey[400]
                              : Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),

              const SizedBox(height: 12),

              // ========================================
              // メッセージを送るボタン
              // ========================================
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecordingScreen(
                        recipientIds: [widget.user.id],
                        recipientUsername: widget.user.username,
                        recipientProfileImage: widget.user.profileImage,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.mic, color: Colors.deepPurple),
                  label: const Text(
                    'ボイスメッセージを送る',
                    style: TextStyle(color: Colors.deepPurple),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.deepPurple),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
