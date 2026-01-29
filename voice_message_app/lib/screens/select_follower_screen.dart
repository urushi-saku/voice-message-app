// ========================================
// フォロワー選択画面
// ========================================
// 初学者向け説明：
// このファイルは、ボイスメッセージを送る相手を選択する画面です
// 複数のフォロワーを選択して、まとめて送信できます

import 'package:flutter/material.dart';
import 'recording_screen.dart';

/// フォロワー選択画面
class SelectFollowerScreen extends StatefulWidget {
  const SelectFollowerScreen({super.key});

  @override
  State<SelectFollowerScreen> createState() => _SelectFollowerScreenState();
}

class _SelectFollowerScreenState extends State<SelectFollowerScreen> {
  // ========================================
  // フォロワーリスト（サンプルデータ）
  // ========================================
  final List<Map<String, dynamic>> _followers = [
    {
      'id': '1',
      'name': '山田太郎',
      'username': '@yamada_taro',
      'isSelected': false,
    },
    {
      'id': '2',
      'name': '佐藤花子',
      'username': '@sato_hanako',
      'isSelected': false,
    },
    {
      'id': '3',
      'name': '鈴木一郎',
      'username': '@suzuki_ichiro',
      'isSelected': false,
    },
    {
      'id': '4',
      'name': '田中美咲',
      'username': '@tanaka_misaki',
      'isSelected': false,
    },
    {
      'id': '5',
      'name': '高橋健太',
      'username': '@takahashi_kenta',
      'isSelected': false,
    },
  ];

  // ========================================
  // 選択中のフォロワー数を取得
  // ========================================
  int get _selectedCount {
    return _followers.where((f) => f['isSelected'] == true).length;
  }

  // ========================================
  // 選択/解除を切り替え
  // ========================================
  void _toggleSelection(int index) {
    setState(() {
      _followers[index]['isSelected'] = !_followers[index]['isSelected'];
    });
  }

  // ========================================
  // 全選択/全解除
  // ========================================
  void _toggleAllSelection() {
    final allSelected = _selectedCount == _followers.length;
    setState(() {
      for (var follower in _followers) {
        follower['isSelected'] = !allSelected;
      }
    });
  }

  // ========================================
  // 選択完了
  // ========================================
  void _confirmSelection() {
    final selectedFollowers = _followers
        .where((f) => f['isSelected'] == true)
        .map((f) => f['name'] as String)
        .toList();

    if (selectedFollowers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('送信先を選択してください')),
      );
      return;
    }

    // 録音画面に遷移
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordingScreen(recipients: selectedFollowers),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedCount > 0
              ? '送信先を選択 ($_selectedCount人)'
              : '送信先を選択',
        ),
        actions: [
          // ========================================
          // 全選択/全解除ボタン
          // ========================================
          IconButton(
            icon: Icon(
              _selectedCount == _followers.length
                  ? Icons.check_box
                  : Icons.check_box_outline_blank,
            ),
            tooltip: _selectedCount == _followers.length ? '全解除' : '全選択',
            onPressed: _toggleAllSelection,
          ),
        ],
      ),
      body: Column(
        children: [
          // ========================================
          // 説明テキスト
          // ========================================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: const Text(
              'ボイスメッセージを送信する相手を選択してください',
              style: TextStyle(fontSize: 14),
            ),
          ),

          // ========================================
          // フォロワーリスト
          // ========================================
          Expanded(
            child: ListView.builder(
              itemCount: _followers.length,
              itemBuilder: (context, index) {
                final follower = _followers[index];
                final isSelected = follower['isSelected'] as bool;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  color: isSelected ? Colors.blue.shade50 : null,
                  child: ListTile(
                    // ========================================
                    // アイコン
                    // ========================================
                    leading: CircleAvatar(
                      backgroundColor:
                          isSelected ? Colors.blue : Colors.grey,
                      child: Text(
                        follower['name'][0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // ========================================
                    // 名前とユーザー名
                    // ========================================
                    title: Text(
                      follower['name'],
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(follower['username']),

                    // ========================================
                    // チェックボックス
                    // ========================================
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (value) => _toggleSelection(index),
                    ),

                    // ========================================
                    // タップで選択切り替え
                    // ========================================
                    onTap: () => _toggleSelection(index),
                  ),
                );
              },
            ),
          ),

          // ========================================
          // 送信ボタン
          // ========================================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: Text(
                _selectedCount > 0
                    ? '$_selectedCount人に送信'
                    : '送信先を選択',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor:
                    _selectedCount > 0 ? Colors.blue : Colors.grey,
                foregroundColor: Colors.white,
              ),
              onPressed: _selectedCount > 0 ? _confirmSelection : null,
            ),
          ),
        ],
      ),
    );
  }
}
