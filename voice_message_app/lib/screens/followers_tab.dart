// ========================================
// フォロワー一覧タブ
// ========================================
// 初学者向け説明：
// このファイルは、フォロワー（ユーザーをフォローしている人）の
// 一覧を表示するタブです

import 'package:flutter/material.dart';
import 'select_follower_screen.dart';

/// フォロワー一覧を表示するウィジェット
class FollowersTab extends StatefulWidget {
  const FollowersTab({super.key});

  @override
  State<FollowersTab> createState() => _FollowersTabState();
}

class _FollowersTabState extends State<FollowersTab> {
  // ========================================
  // サンプルデータ（将来的にはサーバーから取得）
  // ========================================
  final List<Map<String, String>> _followers = [
    {
      'name': '山田太郎',
      'username': '@yamada_taro',
      'message': '最近フォローしました',
    },
    {
      'name': '佐藤花子',
      'username': '@sato_hanako',
      'message': 'よろしくお願いします！',
    },
    {
      'name': '鈴木一郎',
      'username': '@suzuki_ichiro',
      'message': 'いつも楽しく聞いています',
    },
  ];

  // ========================================
  // ボイスメッセージ送信画面を開く
  // ========================================
  void _openSendVoiceMessage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectFollowerScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('フォロワー'),
        actions: [
          // ========================================
          // 検索ボタン（将来の機能）
          // ========================================
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '検索',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('検索機能は準備中です')),
              );
            },
          ),
        ],
      ),
      body: _followers.isEmpty
          ? const Center(
              child: Text('まだフォロワーがいません'),
            )
          : ListView.builder(
              itemCount: _followers.length,
              itemBuilder: (context, index) {
                final follower = _followers[index];

                return ListTile(
                  // ========================================
                  // フォロワーのアイコン
                  // ========================================
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: Text(
                      follower['name']![0], // 名前の最初の文字
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // ========================================
                  // フォロワーの名前とユーザー名
                  // ========================================
                  title: Text(follower['name']!),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        follower['username']!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        follower['message']!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),

                  // ========================================
                  // フォローバックボタン
                  // ========================================
                  trailing: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${follower['name']}をフォローしました'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('フォロー'),
                  ),

                  // ========================================
                  // タップしたらプロフィール表示（将来の機能）
                  // ========================================
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(follower['name']!),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ユーザー名: ${follower['username']}'),
                            const SizedBox(height: 8),
                            Text('メッセージ: ${follower['message']}'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('閉じる'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
      // ========================================
      // 右下の+ボタン（ボイスメッセージ送信）
      // ========================================
      floatingActionButton: FloatingActionButton(
        onPressed: _openSendVoiceMessage,
        tooltip: 'ボイスメッセージを送信',
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
