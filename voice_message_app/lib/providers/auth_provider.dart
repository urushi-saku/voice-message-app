// ========================================
// 認証状態管理 Provider
// ========================================
// ログイン状態をアプリ全体で共有・管理するProvider
//
// 【主な役割】
// 1. ユーザー情報の管理（ユーザー名、メール、フォロワー数など）
// 2. 認証状態の管理（ログイン中か未ログインか）
// 3. JWT トークンの保持
// 4. 登録・ログイン・ログアウト処理
// 5. 画面の描画トリガー（notifyListeners）
//
// 【継承】
// - ChangeNotifier: 状態変更時に画面を自動更新する基底クラス
//   → notifyListeners()で登録済みのウィジェットが再描画される
//
// 【利用場面】
// - UI層（画面）からのデータ取得
// - 認証状態に応じた画面切り替え
// - ログイン情報の永続化

import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// ユーザー情報を表すクラス
/// 【メンバー変数】
/// - id: MongoDB ObjectId（ユーザー識別子）
/// - username: ユーザー名
/// - email: メールアドレス
/// - profileImage: プロフィール画像URL（オプション）
/// - bio: 自己紹介（デフォルト空文字列）
/// - followersCount: フォロワー数（デフォルト0）
/// - followingCount: フォロー中の数（デフォルト0）
class User {
  final String id;
  final String username;
  final String handle;
  final String email;
  final String? profileImage;
  final String bio;
  final int followersCount;
  final int followingCount;

  User({
    required this.id,
    required this.username,
    required this.handle,
    required this.email,
    this.profileImage,
    this.bio = '',
    this.followersCount = 0,
    this.followingCount = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final u = json['user'] as Map<String, dynamic>? ?? json;
    return User(
      id: u['id']?.toString() ?? u['_id']?.toString() ?? '',
      username: u['username'] ?? '',
      handle: u['handle'] ?? u['username'] ?? '',
      email: u['email'] ?? '',
      profileImage: u['profileImage'],
      bio: u['bio'] ?? '',
      followersCount: u['followersCount'] ?? 0,
      followingCount: u['followingCount'] ?? 0,
    );
  }
}

/// 認証状態を管理するProvider
///
/// 【ChangeNotifier を継承】
/// - notifyListeners() で登録済みウィジェットを再描画
/// - Consumer<AuthProvider> で画面がこのProviderを購読
///
/// 【状態変数（プライベート）】
/// - _user: ログイン中のユーザー情報
/// - _token: JWT トークン（API通信で使用）
/// - _isLoading: API通信中かどうか（ローディング表示用）
/// - _error: エラーメッセージ（画面表示用）
/// - _isAuthenticated: ログイン状態フラグ
class AuthProvider extends ChangeNotifier {
  // ========================================
  // 状態管理
  // ========================================
  /// 【プライベート変数】
  /// アンダースコア（_）で始まる変数は外部からアクセス不可
  /// ゲッター経由でのみ読み取り可能
  User? _user; // ログイン中のユーザー情報
  String? _token; // JWT トークン
  bool _isLoading = false; // ローディング状態
  String? _error; // エラーメッセージ
  bool _isAuthenticated = false; // ログイン状態

  // ========================================
  // ゲッター（状態を外部から取得）
  // ========================================
  /// 【用途】
  /// UI層（画面）がこれらのゲッターを通じて状態を読み取る
  /// private変数(_user等)に直接アクセスできないようにするため
  ///
  /// 【使用例】
  ///   final user = authProvider.user;
  ///   final isLoading = authProvider.isLoading;
  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  // ========================================
  // コンストラクタ
  // ========================================
  /// 【実行タイミング】
  /// - AuthProvider が最初に生成される時（アプリ起動時）
  /// - MultiProvider で ChangeNotifierProvider(create: (_) => AuthProvider())
  ///
  /// 【処理】
  /// - _initializeAuth() を呼び出して、保存トークンを確認
  AuthProvider() {
    _initializeAuth();
  }

  // ========================================
  // 認証状態の初期化
  // ========================================
  /// 【処理フロー】
  /// 1. AuthService.getToken() でshared_preferencesから保存トークンを取得
  /// 2. トークンが存在する場合：
  ///    a. _token = token で保持
  ///    b. _isAuthenticated = true に設定
  ///    c. _fetchUserInfo() でユーザー情報を取得
  /// 3. トークンが存在しない場合：
  ///    - _isAuthenticated = false
  ///    - _token = null
  ///    - _user = null
  /// 4. notifyListeners() で UI を更新
  ///
  /// 【用途】
  /// アプリ起動時に自動実行され、以前ログインしていた場合は
  /// ホーム画面を表示し、未ログインの場合はログイン画面を表示
  Future<void> _initializeAuth() async {
    try {
      final token = await AuthService.getToken();
      if (token != null) {
        _token = token;
        _isAuthenticated = true;

        // ユーザー情報を取得
        await _fetchUserInfo();
      }
    } catch (e) {
      _isAuthenticated = false;
      _token = null;
      _user = null;
    }
    notifyListeners();
  }

  // ========================================
  // ユーザー情報を取得
  // ========================================
  Future<void> _fetchUserInfo() async {
    try {
      final userInfo = await AuthService.getMe();
      _user = User.fromJson(userInfo);
    } catch (e) {
      _user = null;
    }
  }

  // ========================================
  // ユーザー登録
  // ========================================
  /// 新規ユーザーで登録する
  Future<bool> register({
    required String username,
    required String handle,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await AuthService.register(
        username: username,
        handle: handle,
        email: email,
        password: password,
      );

      _token = result['token'];
      _user = User.fromJson(result);
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ========================================
  // ユーザーログイン
  // ========================================
  /// メールアドレスとパスワードでログイン
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await AuthService.login(email: email, password: password);

      _token = result['token'];
      _user = User.fromJson(result);
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ========================================
  // ユーザー情報を再読み込み
  // ========================================
  /// サーバーからユーザー情報を再取得して保存
  Future<void> loadUserInfo() async {
    try {
      final userInfo = await AuthService.getMe();
      // getMe() は { "user": { ... } } を返す
      final u = userInfo['user'] as Map<String, dynamic>? ?? userInfo;
      _user = User(
        id: u['id']?.toString() ?? u['_id']?.toString() ?? _user?.id ?? '',
        username: u['username'] ?? _user?.username ?? '',
        handle: u['handle'] ?? u['username'] ?? _user?.handle ?? '',
        email: u['email'] ?? _user?.email ?? '',
        profileImage: u['profileImage'] ?? _user?.profileImage,
        bio: u['bio'] ?? _user?.bio ?? '',
        followersCount: u['followersCount'] ?? _user?.followersCount ?? 0,
        followingCount: u['followingCount'] ?? _user?.followingCount ?? 0,
      );
      notifyListeners();
    } catch (e) {
      _error = 'ユーザー情報の取得に失敗しました';
      notifyListeners();
    }
  }

  // ========================================
  // ユーザーログアウト
  // ========================================
  /// ログアウト処理
  Future<void> logout() async {
    try {
      await AuthService.logout();
      _user = null;
      _token = null;
      _isAuthenticated = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ========================================
  // エラーメッセージをクリア
  // ========================================
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
