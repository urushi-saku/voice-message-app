// ========================================
// ホームページ - メイン画面（タブ管理）
// ========================================
// 初学者向け説明：
// このファイルは、アプリのメイン画面を表示します
// 4つのタブ（メッセージ、フォロワー、受信ファイル、プロフィール）を管理します

import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'message_threads_screen.dart';

/// ホームページウィジェット（タブナビゲーション）
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ========================================
  // タブの状態管理
  // ========================================
  int _currentTabIndex = 0; // 現在選択中のタブ（0=メッセージ, 1=プロフィール）

  // ========================================
  // 各タブの内容を返す
  // ========================================
  Widget _getCurrentTab() {
    switch (_currentTabIndex) {
      case 0:
        return const MessageThreadsScreen(); // メッセージスレッド一覧
      case 1:
        return const ProfilePage(); // プロフィールタブ
      default:
        return const MessageThreadsScreen();
    }
  }

  // ========================================
  // UIを構築
  // ========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getCurrentTab(), // 現在選択中のタブを表示
      // ========================================
      // 下部ナビゲーションバー
      // ========================================
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        // アクティブタブの表示を改善
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 13,
        unselectedFontSize: 12,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'メッセージ'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'プロフィール'),
        ],
      ),
    );
  }
}
