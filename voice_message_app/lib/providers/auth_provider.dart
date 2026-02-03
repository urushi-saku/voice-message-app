// ========================================
// 認証状態管理 Provider
// ========================================
// ログイン状態をアプリ全体で共有・管理するProvider

import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// ユーザー情報を表すクラス
class User {
  final String id;
  final String username;
  final String email;
  final String? profileImage;
  final String bio;
  final int followersCount;
  final int followingCount;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.profileImage,
    this.bio = '',
    this.followersCount = 0,
    this.followingCount = 0,
  });

  // JSONからUserオブジェクトに変換
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user']['id'] ?? json['id'] ?? '',
      username: json['user']['username'] ?? json['username'] ?? '',
      email: json['user']['email'] ?? json['email'] ?? '',
      profileImage: json['user']['profileImage'] ?? json['profileImage'],
      bio: json['user']['bio'] ?? json['bio'] ?? '',
      followersCount: json['user']['followersCount'] ?? json['followersCount'] ?? 0,
      followingCount: json['user']['followingCount'] ?? json['followingCount'] ?? 0,
    );
  }
}

/// 認証状態を管理するProvider
class AuthProvider extends ChangeNotifier {
  // ========================================
  // 状態管理
  // ========================================
  User? _user; // ログイン中のユーザー情報
  String? _token; // JWT トークン
  bool _isLoading = false; // ローディング状態
  String? _error; // エラーメッセージ
  bool _isAuthenticated = false; // ログイン状態

  // ========================================
  // ゲッター（状態を外部から取得）
  // ========================================
  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  // ========================================
  // コンストラクタ
  // ========================================
  AuthProvider() {
    _initializeAuth();
  }

  // ========================================
  // 認証状態の初期化
  // ========================================
  /// アプリ起動時に保存されたトークンを確認
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
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await AuthService.register(
        username: username,
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
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await AuthService.login(
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
