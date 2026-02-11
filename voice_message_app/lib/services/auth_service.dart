// ========================================
// 認証サービス
// ========================================
// バックエンドのAPI通信を管理するサービス
//
// 【主な役割】
// 1. ユーザー登録（POST /auth/register）
// 2. ユーザーログイン（POST /auth/login）
// 3. トークン管理（保存・取得・削除）
// 4. 現在のユーザー情報取得（GET /auth/me）
//
// 【特徴】
// - すべてのメソッドがstaticで、インスタンス化不要
// - ローカルストレージ（shared_preferences）とAPI通信を統合管理
// - エラーハンドリング付き

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'fcm_service.dart';

/// 認証APIの基本URL（バックエンド）
const String BASE_URL = 'http://localhost:3000';

/// 認証サービスクラス
///
/// 【static メソッド構成】
/// - register(): 新規ユーザー登録
/// - login(): ユーザーログイン
/// - logout(): ログアウト（トークン削除）
/// - getToken(): 保存済みトークン取得
/// - getMe(): 現在のユーザー情報取得
class AuthService {
  // ========================================
  // ユーザー登録
  // ========================================
  /// 【処理フロー】
  /// 1. バックエンドに POST リクエスト送信
  /// 2. ステータスコード201（作成成功）を確認
  /// 3. レスポンスの JWT トークンを取得
  /// 4. トークンをshared_preferencesに保存
  /// 5. ユーザー情報を呼び出し元に返却
  ///
  /// 【例外処理】
  /// - ステータスコード201以外 → エラーメッセージをthrow
  /// - 通信エラー → エラーをthrow
  ///
  /// 【引数】
  ///   - username: ユーザー名（3文字以上30文字以内）
  ///   - email: メールアドレス
  ///   - password: パスワード（6文字以上）
  ///
  /// 【戻り値】
  ///   - 成功時: ユーザー情報とトークンを含むMap
  ///   - 失敗時: 例外（throw）
  ///
  /// 【API エンドポイント】
  ///   POST http://localhost:3000/auth/register
  ///   Request: { username, email, password }
  ///   Response: { success, message, data: { user, token } }
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // ① バックエンドに POST リクエスト送信
      final response = await http.post(
        Uri.parse('$BASE_URL/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      // ② ステータスコード201（成功）を確認
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // ③ トークンをローカルストレージに保存
        // 将来的なAPI呼び出しで認証ヘッダーとして使用
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', data['data']['token']);

        // ④ ユーザー情報を返す
        return data['data'];
      } else {
        // ② エラーレスポンスの場合
        final error = jsonDecode(response.body);
        throw error['message'] ?? 'ユーザー登録に失敗しました';
      }
    } catch (e) {
      // 例外処理
      throw e.toString();
    }
  }

  // ========================================
  // ユーザーログイン
  // ========================================
  /// 【処理フロー】
  /// 1. バックエンドに POST リクエスト送信
  /// 2. ステータスコード200（成功）を確認
  /// 3. レスポンスの JWT トークンを取得
  /// 4. トークンをshared_preferencesに保存
  /// 5. ユーザー情報を呼び出し元に返却
  ///
  /// 【例外処理】
  /// - ステータスコード200以外 → エラーメッセージをthrow
  /// - 通信エラー → エラーをthrow
  ///
  /// 【引数】
  ///   - email: 登録済みメールアドレス
  ///   - password: パスワード
  ///
  /// 【戻り値】
  ///   - 成功時: ユーザー情報とトークンを含むMap
  ///   - 失敗時: 例外（throw）
  ///
  /// 【API エンドポイント】
  ///   POST http://localhost:3000/auth/login
  ///   Request: { email, password }
  ///   Response: { success, message, data: { user, token } }
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      // ① バックエンドに POST リクエスト送信
      final response = await http.post(
        Uri.parse('$BASE_URL/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      // ② ステータスコード200（成功）を確認
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ③ トークンをローカルストレージに保存
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', data['data']['token']);

        // ④ ユーザー情報を返す
        return data['data'];
      } else {
        // ② エラーレスポンスの場合
        final error = jsonDecode(response.body);
        throw error['message'] ?? 'ログインに失敗しました';
      }
    } catch (e) {
      // 例外処理
      throw e.toString();
    }
  }

  // ========================================
  // ログアウト
  // ========================================
  // ログアウト
  // ========================================
  /// ユーザーをログアウトする（トークンを削除）
  ///
  /// 【処理フロー】
  /// ①FCMトークンをサーバーから削除
  /// ②ローカルストレージから認証トークンを削除
  static Future<void> logout() async {
    try {
      // ①FCMトークンを削除（プッシュ通知を停止）
      await FcmService.deleteToken();

      // ②認証トークンを削除
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('authToken');
    } catch (e) {
      throw e.toString();
    }
  }

  // ========================================
  // トークン取得
  // ========================================
  /// ローカルストレージから保存されたトークンを取得
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('authToken');
    } catch (e) {
      return null;
    }
  }

  // ========================================
  // 現在のユーザー情報を取得
  // ========================================
  /// トークンを使用して、現在のユーザー情報を取得
  static Future<Map<String, dynamic>> getMe() async {
    try {
      final token = await getToken();

      if (token == null) {
        throw 'トークンが見つかりません';
      }

      final response = await http.get(
        Uri.parse('$BASE_URL/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw 'ユーザー情報の取得に失敗しました';
      }
    } catch (e) {
      throw e.toString();
    }
  }
}
