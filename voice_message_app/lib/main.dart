// Flutterの基本ウィジェットを使うためのimport（おまじない）
import 'package:flutter/material.dart';

// アプリのエントリーポイント（最初に実行される関数）
void main() {
  runApp(const MyApp());
}

// アプリ全体の設定やテーマを管理するウィジェット
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ボイスメッセージアプリ', // アプリのタイトル（日本語）
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), // 色のテーマ
      ),
      home: const HomePage(), // 最初に表示する画面
    );
  }
}

// ボイスメッセージの一覧や録音ボタンを表示する画面
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ボイスメッセージ'),
        actions: [
          // 右上のプロフィールアイコンボタン
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // プロフィール画面へ遷移
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ここに受信したボイスメッセージのリストを表示予定
            const Text('ここにボイスメッセージ一覧'),
            const SizedBox(height: 20),
            // 録音して送信するボタン
            ElevatedButton.icon(
              icon: const Icon(Icons.mic),
              label: const Text('録音して送信'),
              onPressed: () {
                // 録音・送信機能は後で実装します
              },
            ),
          ],
        ),
      ),
    );
  }
}

// プロフィール情報を表示・編集する画面
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
            // ユーザーアイコン（仮）
            const CircleAvatar(
              radius: 40,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 16),
            // ユーザー名（仮）
            const Text('ユーザー名'),
            const SizedBox(height: 16),
            // プロフィール編集ボタン
            ElevatedButton(
              onPressed: () {
                // プロフィール編集機能は後で実装します
              },
              child: const Text('プロフィール編集'),
            ),
          ],
        ),
      ),
    );
  }
}
