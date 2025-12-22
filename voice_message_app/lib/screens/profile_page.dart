// ========================================
// プロフィールページ
// ========================================
// 初学者向け説明：
// このファイルは、ユーザーのプロフィール情報を表示するページです
// 将来的にはここでプロフィール編集などの機能を追加できます

import 'package:flutter/material.dart';

/// プロフィール情報を表示・編集する画面
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ========================================
            // ユーザーアイコン（仮）
            // ========================================
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            
            const SizedBox(height: 20),
            
            // ========================================
            // ユーザー名（仮）
            // ========================================
            const Text(
              'ユーザー名',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 10),
            
            // ========================================
            // メールアドレス（仮）
            // ========================================
            const Text(
              'user@example.com',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 30),
            
            // ========================================
            // プロフィール編集ボタン
            // ========================================
            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('プロフィール編集'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                // TODO: プロフィール編集機能は後で実装します
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('プロフィール編集機能は準備中です'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
