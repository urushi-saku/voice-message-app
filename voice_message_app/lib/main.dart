// ========================================
// メインファイル - アプリのエントリーポイント
// ========================================
// 初学者向け説明：
// このファイルはアプリの起点です
// アプリ全体の設定（テーマ、タイトル）と、
// 最初に表示する画面を指定します

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_page.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

// アプリのエントリーポイント（最初に実行される関数）
void main() {
  runApp(const MyApp());
}

// アプリ全体の設定やテーマを管理するウィジェット
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 認証状態を管理するProvider
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'ボイスメッセージアプリ', // アプリのタイトル（日本語）
        theme: ThemeData(
          colorScheme:
              ColorScheme.fromSeed(seedColor: Colors.deepPurple), // 色のテーマ
        ),
        home: const AuthWrapper(), // 認証状態に応じて画面を切り替え
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomePage(),
        },
      ),
    );
  }
}

// ========================================
// 認証ラッパー
// ========================================
// ログイン状態に応じて、ログイン画面またはホーム画面を表示
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // ログイン状態の初期化待機中
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // ログイン状態に応じて画面を切り替え
        if (authProvider.isAuthenticated) {
          return const HomePage(); // ログイン済み → ホーム画面
        } else {
          return const LoginScreen(); // 未ログイン → ログイン画面
        }
      },
    );
  }
}
