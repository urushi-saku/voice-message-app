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
import 'services/navigation_service.dart';
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
void main() {
  // Flutter Widgetの初期化のみ（同期処理・一瞬）
  WidgetsFlutterBinding.ensureInitialized();

  // 即座にアプリを起動してスプラッシュ画面を表示
  // 全初期化はSplashScreen内でバックグラウンド実行
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NetworkConnectivityService()),
        ChangeNotifierProvider(create: (_) => SyncService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'ボイスメッセージアプリ',
            navigatorKey: NavigationService.navigatorKey,
            theme: lightTheme(),
            darkTheme: darkTheme(),
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            home: const SplashScreen(),
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
// SplashScreen - 起動画面 & 初期化
// ========================================
/// 起動直後に表示し、バックグラウンドで全サービスを初期化する。
/// 初期化が完了したらAuthWrapperへ遷移。
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // OfflineService(Hive) と Firebase を並列で初期化
    // 両方バックグラウンドで実行し、完了を待たずに遷移
    OfflineService.initialize().catchError((e) {
      print('❌ Offline Service error: $e');
    });

    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).then((_) => FcmService.initialize()).catchError((e) {
      print('❌ Firebase error: $e');
    });

    // ThemeProvider・Network は軽量なので await
    if (mounted) {
      context.read<ThemeProvider>().initialize();
      context.read<NetworkConnectivityService>().initialize();
    }

    // 少し待って（スプラッシュを見せる最低限の時間）AuthWrapperへ
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const AuthWrapper()));
    }
  }

  @override
  Widget build(BuildContext context) {
    // アプリのテーマカラーをそのまま使ったシンプルなスプラッシュ
    return Scaffold(
      backgroundColor: const Color(0xFF7C4DFF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic, size: 72, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'ボイスメッセージ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================
// AuthWrapper - 認証状態に応じた画面切り替え
// ========================================
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isInitializing) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (authProvider.isAuthenticated) {
          return const HomePage();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
