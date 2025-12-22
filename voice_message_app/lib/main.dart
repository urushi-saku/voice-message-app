// ========================================
// メインファイル - アプリのエントリーポイント
// ========================================
// 初学者向け説明：
// このファイルはアプリの起点です
// アプリ全体の設定（テーマ、タイトル）と、
// 最初に表示する画面を指定します

import 'package:flutter/material.dart';
import 'screens/home_page.dart';

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
