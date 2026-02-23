// ========================================
// グループAPIサービス
// ========================================
// グループのCRUD・メンバー管理・グループメッセージ送受信の
// バックエンドAPIと通信する機能を提供します

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'auth_service.dart';
import '../models/group.dart';

class GroupService {
  // ========================================
  // グループ一覧取得
  // GET /groups
  // ========================================
  static Future<List<GroupInfo>> getMyGroups() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('認証が必要です');

    final response = await http
        .get(
          Uri.parse('$BASE_URL/groups'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['groups'] as List<dynamic>;
      return list
          .map((g) => GroupInfo.fromJson(g as Map<String, dynamic>))
          .toList();
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'グループ一覧の取得に失敗しました');
    }
  }

  // ========================================
  // グループ詳細取得
  // GET /groups/:id
  // ========================================
  static Future<GroupInfo> getGroupById(String groupId) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('認証が必要です');

    final response = await http
        .get(
          Uri.parse('$BASE_URL/groups/$groupId'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return GroupInfo.fromJson(data['group'] as Map<String, dynamic>);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'グループ詳細の取得に失敗しました');
    }
  }

  // ========================================
  // グループ作成
  // POST /groups
  // ========================================
  static Future<GroupInfo> createGroup({
    required String name,
    String description = '',
    required List<String> memberIds,
    File? iconFile,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('認証が必要です');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$BASE_URL/groups'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['memberIds'] = jsonEncode(memberIds);

    if (iconFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'icon',
          iconFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 20),
    );
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return GroupInfo.fromJson(data['group'] as Map<String, dynamic>);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'グループの作成に失敗しました');
    }
  }

  // ========================================
  // グループ情報更新
  // PUT /groups/:id
  // ========================================
  static Future<GroupInfo> updateGroup({
    required String groupId,
    String? name,
    String? description,
    File? iconFile,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('認証が必要です');

    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$BASE_URL/groups/$groupId'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    if (name != null) request.fields['name'] = name;
    if (description != null) request.fields['description'] = description;

    if (iconFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'icon',
          iconFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 20),
    );
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return GroupInfo.fromJson(data['group'] as Map<String, dynamic>);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'グループの更新に失敗しました');
    }
  }

  // ========================================
  // グループ削除
  // DELETE /groups/:id
  // ========================================
  static Future<void> deleteGroup(String groupId) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('認証が必要です');

    final response = await http
        .delete(
          Uri.parse('$BASE_URL/groups/$groupId'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'グループの削除に失敗しました');
    }
  }

  // ========================================
  // メンバー追加
  // POST /groups/:id/members
  // ========================================
  static Future<void> addMember(String groupId, String userId) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('認証が必要です');

    final response = await http
        .post(
          Uri.parse('$BASE_URL/groups/$groupId/members'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'userId': userId}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'メンバーの追加に失敗しました');
    }
  }

  // ========================================
  // メンバー削除 / 退出
  // DELETE /groups/:id/members/:userId
  // ========================================
  static Future<void> removeMember(String groupId, String userId) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('認証が必要です');

    final response = await http
        .delete(
          Uri.parse('$BASE_URL/groups/$groupId/members/$userId'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'メンバーの削除に失敗しました');
    }
  }

  // ========================================
  // グループメッセージ一覧取得
  // GET /groups/:id/messages
  // ========================================
  static Future<List<GroupMessageInfo>> getGroupMessages(
    String groupId, {
    int page = 1,
    int limit = 30,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('認証が必要です');

    final response = await http
        .get(
          Uri.parse(
            '$BASE_URL/groups/$groupId/messages?page=$page&limit=$limit',
          ),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['messages'] as List<dynamic>;
      return list
          .map((m) => GroupMessageInfo.fromJson(m as Map<String, dynamic>))
          .toList();
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'グループメッセージの取得に失敗しました');
    }
  }

  // ========================================
  // グループテキストメッセージ送信
  // POST /groups/:id/messages/text
  // ========================================
  static Future<void> sendTextMessage(
    String groupId,
    String textContent,
  ) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('認証が必要です');

    final response = await http
        .post(
          Uri.parse('$BASE_URL/groups/$groupId/messages/text'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'textContent': textContent}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 201) {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'メッセージの送信に失敗しました');
    }
  }

  // ========================================
  // グループ音声メッセージ送信
  // POST /groups/:id/messages/voice
  // ========================================
  static Future<void> sendVoiceMessage(
    String groupId,
    File voiceFile, {
    int? duration,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('認証が必要です');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$BASE_URL/groups/$groupId/messages/voice'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    if (duration != null) request.fields['duration'] = duration.toString();

    request.files.add(
      await http.MultipartFile.fromPath(
        'voice',
        voiceFile.path,
        contentType: MediaType('audio', 'mp4'),
      ),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
    );
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201) {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'ボイスメッセージの送信に失敗しました');
    }
  }

  // ========================================
  // グループメッセージ既読
  // PUT /groups/:id/messages/:messageId/read
  // ========================================
  static Future<void> markMessageRead(String groupId, String messageId) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('認証が必要です');

    await http
        .put(
          Uri.parse('$BASE_URL/groups/$groupId/messages/$messageId/read'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 10));
  }
}
