// ========================================
// トーク相手選択画面
// ========================================
// フォロー中のユーザーを一覧表示し、
// タップするとそのユーザーとのトーク画面を開きます

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import 'thread_detail_screen.dart';

/// トーク相手選択画面
class SelectFollowerScreen extends StatefulWidget {
  const SelectFollowerScreen({super.key});

  @override
  State<SelectFollowerScreen> createState() => _SelectFollowerScreenState();
}

class _SelectFollowerScreenState extends State<SelectFollowerScreen> {
  List<UserInfo> _following = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;

      if (userId == null) throw Exception('ユーザー情報が取得できません');

      final following = await UserService.getFollowing(userId);

      setState(() {
        _following = following;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ユーザーをタップしてトーク画面へ遷移
  void _openChat(UserInfo user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ThreadDetailScreen(
          senderId: user.id,
          senderUsername: user.username,
          senderProfileImage: user.profileImage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('トーク相手を選択'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('エラー: $_error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadFollowing,
                    child: const Text('再読み込み'),
                  ),
                ],
              ),
            )
          : _following.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'フォロー中のユーザーがいません',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadFollowing,
              child: ListView.builder(
                itemCount: _following.length,
                itemBuilder: (context, index) {
                  final user = _following[index];

                  return ListTile(
                    onTap: () => _openChat(user),
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      backgroundImage: user.profileImage != null
                          ? NetworkImage(user.profileImage!)
                          : null,
                      child: user.profileImage == null
                          ? Text(
                              user.username[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      user.username,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      '@${user.handle}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
    );
  }
}
