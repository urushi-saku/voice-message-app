// ========================================
// ユーザー関連APIサービス
// ========================================
// ユーザー検索、フォロー管理、フォロワーリスト取得などの
// バックエンドAPIと通信する機能を提供します

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// ユーザー情報を表すクラス
class UserInfo {
  final String id;
  final String username;
  final String email;
  final String? profileImage;
  final String bio;
  final int followersCount;
  final int followingCount;

  UserInfo({
    required this.id,
    required this.username,
    required this.email,
    this.profileImage,
    required this.bio,
    required this.followersCount,
    required this.followingCount,
  });

  /// JSONからUserInfoオブジェクトを生成
  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['_id'],
      username: json['username'],
      email: json['email'],
      profileImage: json['profileImage'],
      bio: json['bio'] ?? '',
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
    );
  }
}

class UserService {
  /// ========================================
  /// ユーザー検索
  /// GET /users/search?q=keyword
  /// ========================================
  /// 【パラメータ】
  /// - keyword: 検索キーワード（ユーザー名で部分一致検索）
  ///
  /// 【処理フロー】
  /// ①保存されているJWTトークンを取得
  /// ②Bearerトークンをヘッダーに設定
  /// ③GET リクエスト送信
  /// ④レスポンスをUserInfoリストに変換
  /// ⑤エラー時は例外をスロー
  static Future<List<UserInfo>> searchUsers(String keyword) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('認証が必要です');
    }

    final response = await http.get(
      Uri.parse('$BASE_URL/users/search?q=$keyword'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => UserInfo.fromJson(json)).toList();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'ユーザー検索に失敗しました');
    }
  }

  /// ========================================
  /// ユーザー詳細取得
  /// GET /users/:id
  /// ========================================
  /// 指定したユーザーの詳細情報を取得します
  static Future<UserInfo> getUserById(String userId) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('認証が必要です');
    }

    final response = await http.get(
      Uri.parse('$BASE_URL/users/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return UserInfo.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'ユーザー情報の取得に失敗しました');
    }
  }

  /// ========================================
  /// フォローする
  /// POST /users/:id/follow
  /// ========================================
  /// 【パラメータ】
  /// - userId: フォローしたいユーザーのID
  ///
  /// 【処理フロー】
  /// ①保存されているJWTトークンを取得
  /// ②POST リクエスト送信（Bearerトークン付き）
  /// ③ステータスコード201（作成成功）を確認
  /// ④エラー時は例外をスロー
  static Future<void> followUser(String userId) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('認証が必要です');
    }

    final response = await http.post(
      Uri.parse('$BASE_URL/users/$userId/follow'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'フォローに失敗しました');
    }
  }

  /// ========================================
  /// フォロー解除
  /// DELETE /users/:id/follow
  /// ========================================
  /// 【パラメータ】
  /// - userId: フォロー解除したいユーザーのID
  ///
  /// 【処理フロー】
  /// ①保存されているJWTトークンを取得
  /// ②DELETE リクエスト送信（Bearerトークン付き）
  /// ③ステータスコード200を確認
  /// ④エラー時は例外をスロー
  static Future<void> unfollowUser(String userId) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('認証が必要です');
    }

    final response = await http.delete(
      Uri.parse('$BASE_URL/users/$userId/follow'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'フォロー解除に失敗しました');
    }
  }

  /// ========================================
  /// フォロワーリスト取得
  /// GET /users/:id/followers
  /// ========================================
  /// 指定したユーザーのフォロワー一覧を取得します
  static Future<List<UserInfo>> getFollowers(String userId) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('認証が必要です');
    }

    final response = await http.get(
      Uri.parse('$BASE_URL/users/$userId/followers'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => UserInfo.fromJson(json)).toList();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'フォロワーリストの取得に失敗しました');
    }
  }

  /// ========================================
  /// フォロー中リスト取得
  /// GET /users/:id/following
  /// ========================================
  /// 指定したユーザーがフォロー中のユーザー一覧を取得します
  static Future<List<UserInfo>> getFollowing(String userId) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('認証が必要です');
    }

    final response = await http.get(
      Uri.parse('$BASE_URL/users/$userId/following'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => UserInfo.fromJson(json)).toList();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'フォロー中リストの取得に失敗しました');
    }
  }

  /// ========================================
  /// プロフィール更新
  /// PUT /users/profile
  /// ========================================
  /// 【パラメータ】
  /// - username: 新しいユーザー名（オプション）
  /// - bio: 新しい自己紹介（オプション）
  ///
  /// 【処理フロー】
  /// ①保存されているJWTトークンを取得
  /// ②PUT リクエスト送信（JSONボディ付き）
  /// ③更新されたユーザー情報を返す
  /// ④エラー時は例外をスロー
  static Future<UserInfo> updateProfile({String? username, String? bio}) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('認証が必要です');
    }

    final Map<String, dynamic> body = {};
    if (username != null) body['username'] = username;
    if (bio != null) body['bio'] = bio;

    if (body.isEmpty) {
      throw Exception('更新する情報がありません');
    }

    final response = await http.put(
      Uri.parse('$BASE_URL/users/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserInfo.fromJson(data['user']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'プロフィールの更新に失敗しました');
    }
  }

  /// ========================================
  /// プロフィール画像更新
  /// PUT /users/profile/image
  /// ========================================
  /// 【パラメータ】
  /// - imageFile: アップロードする画像ファイル
  ///
  /// 【処理フロー】
  /// ①保存されているJWTトークンを取得
  /// ②MultipartRequestを作成
  /// ③画像ファイルを添付
  /// ④リクエスト送信
  /// ⑤更新されたユーザー情報を返す
  /// ⑥エラー時は例外をスロー
  static Future<UserInfo> updateProfileImage(File imageFile) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('認証が必要です');
    }

    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$BASE_URL/users/profile/image'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserInfo.fromJson(data['user']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'プロフィール画像の更新に失敗しました');
    }
  }
}
