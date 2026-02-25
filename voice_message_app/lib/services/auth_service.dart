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
import 'package:google_sign_in/google_sign_in.dart';
import 'fcm_service.dart';
import 'e2ee_service.dart';

/// 認証APIの基本URL（バックエンド）
/// adb reverse tcp:3000 tcp:3000 を実行することで
/// 実機・エミュレータ両方で localhost:3000 が使える
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
    required String handle,
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
          'handle': handle,
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
        // リフレッシュトークンも保存
        if (data['data']['refreshToken'] != null) {
          await prefs.setString('refreshToken', data['data']['refreshToken']);
        }
        // ユーザー ID をローカル保存（E2EE 郵号化で使用）
        final userId =
            data['data']['user']?['_id'] ?? data['data']['user']?['id'];
        if (userId != null) await storeCurrentUserId(userId.toString());

        // ④ E2EE キーペア生成 & 公開鍵をサーバーにアップロード
        await E2eeService.uploadPublicKey();

        // ⑤ ユーザー情報を返す
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
        // リフレッシュトークンも保存
        if (data['data']['refreshToken'] != null) {
          await prefs.setString('refreshToken', data['data']['refreshToken']);
        }
        // ユーザー ID をローカル保存（E2EE 郵号化で使用）
        final userId =
            data['data']['user']?['_id'] ?? data['data']['user']?['id'];
        if (userId != null) await storeCurrentUserId(userId.toString());

        // ④ E2EE キーペア生成 & 公開鍵をサーバーにアップロード
        await E2eeService.uploadPublicKey();

        // ⑤ ユーザー情報を返す
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
  /// ユーザーをログアウトする（サーバー・ローカル両方のトークンを削除）
  ///
  /// 【処理フロー】
  /// ①サーバーに POST /auth/logout を送信・FCMトークン・refreshTokenがクリアされる
  /// ②ローカルストレージから認証トークン・リフレッシュトークンを削除
  static Future<void> logout() async {
    try {
      final token = await getToken();
      // ①サーバーサイドのトークン・FCMトークンをクリア
      if (token != null) {
        try {
          await http.post(
            Uri.parse('$BASE_URL/auth/logout'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
        } catch (_) {
          // ネットワークエラーでもローカルのクリアは実行する
        }
      }
      // ②FCMトークンのローカルクリア
      await FcmService.deleteToken();
      // ③認証トークン・refreshTokenを消去
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('authToken');
      await prefs.remove('refreshToken');
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
  // トークンリフレッシュ
  // ========================================
  /// リフレッシュトークンで新しいアクセストークンを発行する。
  ///
  /// アクセストークンが期限切れになったときに呼び出す。
  /// 成功時は新しいアクセストークン＆リフレッシュトークンを保存する。
  /// 戻り値 true = 更新成功、false = リフレッシュトークンも無効（再ログイン必要）
  static Future<bool> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedRefreshToken = prefs.getString('refreshToken');
      if (storedRefreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$BASE_URL/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': storedRefreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await prefs.setString('authToken', data['data']['token']);
        await prefs.setString('refreshToken', data['data']['refreshToken']);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ========================================
  // パスワードリセットリクエスト
  // ========================================
  /// メールアドレスにパスワードリセット用メールを送信する。
  /// SMTP設定がない場合はサーバーコンソールにリセットURLが表示される。
  static Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$BASE_URL/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw error['message'] ?? 'パスワードリセットのリクエストに失敗しました';
    }
  }

  // ========================================
  // パスワードリセット確定
  // ========================================
  /// リセットトークン（URLから取得）と新しいパスワードでパスワードを更新する。
  static Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$BASE_URL/auth/reset-password/$token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': newPassword}),
    );
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw error['message'] ?? 'パスワードのリセットに失敗しました';
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

  // ========================================
  // ユーザー ID のローカル保存 / 取得
  // ========================================
  /// ログイン・登録成功時に呼び出し、ユーザー ID を SharedPreferences に保存する
  static Future<void> storeCurrentUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentUserId', userId);
  }

  /// SharedPreferences からユーザー ID を取得する（ネットワーク不要）
  static Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('currentUserId');
  }

  // ========================================
  // Google OAuth ログイン
  // ========================================
  /// Google Sign-In でユーザーを認証し、バックエンドと連携
  ///
  /// 【処理フロー】
  /// 1. Google Sign-In で認証
  /// 2. ユーザー情報とメールを取得
  /// 3. バックエンド POST /auth/google に送信
  /// 4. トークンをローカルに保存
  /// 5. E2EE キーペアを生成・アップロード
  static Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      // Google Sign-In インスタンスを初期化
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // サインイン実行
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw 'Google ログインがキャンセルされました';
      }

      // Google ユーザー情報を取得
      final String googleId = googleUser.id;
      final String? email = googleUser.email;
      final String displayName = googleUser.displayName ?? '';
      final String? photoUrl = googleUser.photoUrl;

      // バックエンドに Google 認証情報を送信
      final response = await http.post(
        Uri.parse('$BASE_URL/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'googleId': googleId,
          'email': email,
          'username': displayName,
          'profileImage': photoUrl,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // トークンをローカルに保存
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', data['accessToken']);
        await prefs.setString('refreshToken', data['refreshToken']);

        // ユーザー ID をローカルに保存
        final userId = data['user']?['id'] ?? data['user']?['_id'];
        if (userId != null) await storeCurrentUserId(userId.toString());

        // E2EE キーペア生成 & 公開鍵をサーバーにアップロード
        await E2eeService.uploadPublicKey();

        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw errorData['message'] ?? 'Google ログインに失敗しました';
      }
    } catch (e) {
      // Google Sign-In をサインアウトして、エラーを再スロー
      await GoogleSignIn().signOut();
      throw e.toString();
    }
  }
}
