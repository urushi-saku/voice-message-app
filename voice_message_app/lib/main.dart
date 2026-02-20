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
// 2. Firebase初期化（プッシュ通知用）
// 3. runApp(const MyApp()) でアプリ起動
// 4. MyApp で全体設定（テーマ、Provider、ルート）
// 5. AuthWrapper で認証状態確認
// 6. ログイン状態に応じて画面表示

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_page.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'services/fcm_service.dart';
import 'services/offline_service.dart';
import 'services/network_connectivity_service.dart';
import 'services/sync_service.dart';
import 'theme/app_theme.dart';

// FlutterFire CLI生成のオプションファイル
// 'flutterfire configure' 実行後に自動生成されます
// まだ実行していない場合、このインポートをコメントアウトしてください
// import 'firebase_options.dart';
import 'firebase_options.dart';

// ========================================
// エントリーポイント
// ========================================
/// 【main() 関数】
/// アプリケーション実行時に最初に呼ばれる関数
///
/// 【処理】
/// ①Flutter Widgetの初期化
/// ②Firebase初期化（プッシュ通知用）
/// ③FCMサービス初期化（通知受信設定）
/// ④runApp(const MyApp())でMyAppウィジェットを起動
///
/// 【FlutterFire CLI使用時】
/// 'flutterfire configure' 実行後、上記のインポートを有効化し、
/// Firebase.initializeApp() の引数を追加：
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
void main() async {
  // Flutter Widgetの初期化（async処理を使うために必要）
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Firebase初期化
    // FlutterFire CLI使用時は options: DefaultFirebaseOptions.currentPlatform を追加
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');

    // FCMサービス初期化（通知受信設定）
    await FcmService.initialize();
  } catch (e) {
    print('❌ Firebase initialization error: $e');
    print('⚠️  Push notifications will not work');
    print('⚠️  Run: cd voice_message_app && flutterfire configure');
  }

  // ========================================
  // オフラインモード初期化
  // ========================================
  try {
    // HiveデータベースとOfflineServiceを初期化
    await OfflineService.initialize();
    print('✅ Offline Service initialized');

    // ネットワーク接続状態監視を開始
    final networkService = NetworkConnectivityService();
    await networkService.initialize();
    print('✅ Network Connectivity Service initialized');
    print('📡 Current status: ${networkService.getStatusText()}');

    // 同期サービスを初期化
    // NOTE: SyncServiceの完全な初期化はMessageServiceが必要なため、
    //       main.dartではなく、認証後にAuthProviderで実行
    print('✅ Sync Service initialized');
  } catch (e) {
    print('❌ Offline Service initialization error: $e');
    print('⚠️  Offline mode will not work');
  }

  // ========================================
  // テーマプロバイダー初期化
  // ========================================
  try {
    final themeProvider = ThemeProvider();
    await themeProvider.initialize();
    print('✅ Theme Provider initialized');
  } catch (e) {
    print('❌ Theme Provider initialization error: $e');
  }

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
        // テーマプロバイダー
        // ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // 認証状態を管理するProvider
        // AuthProvider()が初期化される
        // 全子ウィジェット（全画面）から Consumer<AuthProvider> でアクセス可能
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // テーマ設定を管理するProvider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // ネットワーク接続状態を管理するProvider
        // NetworkConnectivityService が初期化される
        // リアルタイムにオンライン/オフライン状態を監視
        ChangeNotifierProvider(create: (_) => NetworkConnectivityService()),

        // 同期処理を管理するProvider
        // SyncService が初期化される
        // オフラインメッセージの同期を管理
        ChangeNotifierProvider(create: (_) => SyncService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'ボイスメッセージアプリ', // アプリのタイトル（日本語）
            // ② テーマ設定（ダークモード対応）
            theme: lightTheme(),
            darkTheme: darkTheme(),
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            // ③ 起動時に表示する画面 → AuthWrapper
            // AuthWrapperが認証状態を確認して適切な画面を表示
            home: const AuthWrapper(),
            // ④ 名前付きルート（画面遷移時に使用）
            // Navigator.pushNamed('/login') のような形式で遷移可能
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => const HomePage(),
            },
          );
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
        // ② 初期化中（起動時のトークン確認中のみ）
        // isLoading（ログイン操作中）では切り替えない → LoginScreenがアンマウントされるのを防ぐ
        if (authProvider.isInitializing) {
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
