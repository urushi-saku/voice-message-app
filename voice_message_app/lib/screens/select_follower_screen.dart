// ========================================
// フォロワー選択画面
// ========================================
// 初学者向け説明：
// このファイルは、ボイスメッセージを送る相手を選択する画面です
// 複数のフォロワーを選択して、まとめて送信できます

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import 'recording_screen.dart';

/// フォロワー選択画面
class SelectFollowerScreen extends StatefulWidget {
  const SelectFollowerScreen({super.key});

  @override
  State<SelectFollowerScreen> createState() => _SelectFollowerScreenState();
}

class _SelectFollowerScreenState extends State<SelectFollowerScreen> {
  // ========================================
  // 状態変数
  // ========================================
  List<UserInfo> _following = [];
  final Set<String> _selectedUserIds = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  // ========================================
  // フォロー中リストを読み込み
  // ========================================
  Future<void> _loadFollowing() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;

      if (userId == null) {
        throw Exception('ユーザー情報が取得できません');
      }

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

  // ========================================
  // 選択/解除を切り替え
  // ========================================
  void _toggleSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  // ========================================
  // 全選択/全解除
  // ========================================
  void _toggleAllSelection() {
    setState(() {
      if (_selectedUserIds.length == _following.length) {
        _selectedUserIds.clear();
      } else {
        _selectedUserIds.clear();
        _selectedUserIds.addAll(_following.map((u) => u.id));
      }
    });
  }

  // ========================================
  // 選択完了
  // ========================================
  void _confirmSelection() {
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('送信先を選択してください')));
      return;
    }

    // 録音画面に遷移
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RecordingScreen(recipientIds: _selectedUserIds.toList()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedUserIds.isNotEmpty
              ? '送信先を選択 (${_selectedUserIds.length}人)'
              : '送信先を選択',
        ),
        actions: [
          // ========================================
          // 全選択/全解除ボタン
          // ========================================
          IconButton(
            icon: Icon(
              _selectedUserIds.length == _following.length
                  ? Icons.check_box
                  : Icons.check_box_outline_blank,
            ),
            tooltip: _selectedUserIds.length == _following.length
                ? '全解除'
                : '全選択',
            onPressed: _toggleAllSelection,
          ),
        ],
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
          ? const Center(child: Text('フォロー中のユーザーがいません'))
          : Column(
              children: [
                // ========================================
                // 選択したユーザー数の表示
                // ========================================
                if (_selectedUserIds.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.deepPurple.withOpacity(0.1),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_selectedUserIds.length}人を選択中',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                // ========================================
                // フォロワーリスト
                // ========================================
                Expanded(
                  child: ListView.builder(
                    itemCount: _following.length,
                    itemBuilder: (context, index) {
                      final user = _following[index];
                      final isSelected = _selectedUserIds.contains(user.id);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (_) => _toggleSelection(user.id),
                        secondary: CircleAvatar(
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
                        title: Text(user.username),
                        subtitle: Text(user.email),
                        activeColor: Colors.deepPurple,
                      );
                    },
                  ),
                ),
              ],
            ),
      // ========================================
      // 次へボタン（フローティングアクションボタン）
      // ========================================
      floatingActionButton: _selectedUserIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _confirmSelection,
              icon: const Icon(Icons.mic),
              label: const Text('録音する'),
              backgroundColor: Colors.deepPurple,
            )
          : null,
    );
  }
}
