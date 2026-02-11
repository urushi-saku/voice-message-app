// ========================================
// ホームページ - メイン画面（タブ管理）
// ========================================
// 初学者向け説明：
// このファイルは、アプリのメイン画面を表示します
// 4つのタブ（メッセージ、フォロワー、受信ファイル、プロフィール）を管理します

import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'followers_tab.dart';
import 'received_files_tab.dart';
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
  int _currentTabIndex = 0; // 現在選択中のタブ（0=メッセージスレッド, 1=フォロワー, 2=受信, 3=プロフィール）

  // ========================================
  // タブに応じたタイトルを返す
  // ========================================
  String _getTabTitle() {
    switch (_currentTabIndex) {
      case 0:
        return 'メッセージ';
      case 1:
        return 'フォロワー';
      case 2:
        return '受信一覧';
      case 3:
        return 'プロフィール';
      default:
        return 'メッセージ';
    }
  }

  // ========================================
  // 各タブの内容を返す
  // ========================================
  Widget _getCurrentTab() {
    switch (_currentTabIndex) {
      case 0:
        return const MessageThreadsScreen(); // メッセージスレッド一覧
      case 1:
        return const FollowersTab(); // フォロワータブ
      case 2:
        return const ReceivedFilesTab(); // 受信ファイルタブ（従来の一覧）
      case 3:
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
      appBar: AppBar(
        title: Text(_getTabTitle()), // タブに応じたタイトル
      ),
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'メッセージ'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'フォロワー'),
          BottomNavigationBarItem(icon: Icon(Icons.inbox), label: '受信一覧'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'プロフィール'),
        ],
      ),
    );
  }
}
