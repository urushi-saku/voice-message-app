// ========================================
// 認証サービス
// ========================================
// バックエンドのAPI通信を管理するサービス

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 認証APIの基本URL
const String BASE_URL = 'http://localhost:3000';

/// 認証サービスクラス
class AuthService {
  // ========================================
  // ユーザー登録
  // ========================================
  /// 新規ユーザーを登録する
  /// 
  /// 引数:
  ///   - username: ユーザー名
  ///   - email: メールアドレス
  ///   - password: パスワード
  /// 
  /// 戻り値:
  ///   - 成功時: JWTトークンを含むMapオブジェクト
  ///   - 失敗時: エラーメッセージをthrow
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/auth/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        // トークンをローカルストレージに保存
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', data['data']['token']);
        
        return data['data'];
      } else {
        final error = jsonDecode(response.body);
        throw error['message'] ?? 'ユーザー登録に失敗しました';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // ========================================
  // ユーザーログイン
  // ========================================
  /// ユーザーがログインする
  /// 
  /// 引数:
  ///   - email: メールアドレス
  ///   - password: パスワード
  /// 
  /// 戻り値:
  ///   - 成功時: JWTトークンを含むMapオブジェクト
  ///   - 失敗時: エラーメッセージをthrow
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // トークンをローカルストレージに保存
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', data['data']['token']);
        
        return data['data'];
      } else {
        final error = jsonDecode(response.body);
        throw error['message'] ?? 'ログインに失敗しました';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // ========================================
  // ログアウト
  // ========================================
  /// ユーザーをログアウトする（トークンを削除）
  static Future<void> logout() async {
    try {
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
