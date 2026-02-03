// ========================================
// メインファイル - アプリのエントリーポイント
// ========================================
// 初学者向け説明：
// このファイルはアプリの起点です
// アプリ全体の設定（テーマ、タイトル）と、
// 最初に表示する画面を指定します
//
// 【処理の流れ】
// 1. main() 関数が最初に実行される
// 2. runApp(const MyApp()) でアプリ起動
// 3. MyApp で全体設定（テーマ、Provider、ルート）
// 4. AuthWrapper で認証状態確認
// 5. ログイン状態に応じて画面表示

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_page.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

// ========================================
// エントリーポイント
// ========================================
/// 【main() 関数】
/// アプリケーション実行時に最初に呼ばれる関数
/// 
/// 【処理】
/// runApp(const MyApp())でMyAppウィジェットを起動
void main() {
  runApp(const MyApp());
}

// ========================================
// MyApp - アプリ全体の設定
// ========================================
/// 【役割】
/// 1. アプリのテーマ（色、フォント）設定
/// 2. Provider（状態管理）の設定
/// 3. ルーティング（画面遷移）の設定
/// 4. 起動時の画面（home）設定
///
/// 【継承】
/// StatelessWidget: 状態を持たない（変わらない）ウィジェット
/// - テーマやProviderの設定は固定なため不要
///
/// 【const で生成】
/// - 最適化（同じインスタンスを再利用）
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ① MultiProvider で複数のProviderを登録
    return MultiProvider(
      providers: [
        // 認証状態を管理するProvider
        // AuthProvider()が初期化される
        // 全子ウィジェット（全画面）から Consumer<AuthProvider> でアクセス可能
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'ボイスメッセージアプリ', // アプリのタイトル（日本語）
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
          ), // 色のテーマ（deepPurpleを基調）
        ),
        // ② 起動時に表示する画面 → AuthWrapper
        // AuthWrapperが認証状態を確認して適切な画面を表示
        home: const AuthWrapper(),
        
        // ③ 名前付きルート（画面遷移時に使用）
        // Navigator.pushNamed('/login') のような形式で遷移可能
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
// AuthWrapper - 認証状態に応じた画面切り替え
// ========================================
/// 【役割】
/// AuthProvider の認証状態を監視して、
/// ログイン済み → ホーム画面
/// 未ログイン → ログイン画面
/// 初期化中 → ローディング画面
/// を表示する
///
/// 【継承】
/// StatelessWidget: 認証状態の管理はAuthProvider任せ
///
/// 【Consumer<AuthProvider>】
/// - AuthProvider の変更を監視
/// - authProvider.isAuthenticated が変わると rebuild
/// - notifyListeners()で画面が自動更新される
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // ① AuthProvider を監視
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // ② 初期化中（トークン確認中）
        // 保存トークンの確認が完了するまでローディング表示
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ③ ログイン状態確認
        if (authProvider.isAuthenticated) {
          // ③-1 ログイン済み → ホーム画面表示
          return const HomePage();
        } else {
          // ③-2 未ログイン → ログイン画面表示
          return const LoginScreen();
        }
      },
    );
  }
}
