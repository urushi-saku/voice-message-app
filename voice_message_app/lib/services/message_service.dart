// ========================================
// メッセージ関連APIサービス
// ========================================
// メッセージ送信、受信リスト取得、既読管理などの
// バックエンドAPIと通信する機能を提供します

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'auth_service.dart';

/// メッセージ情報を表すクラス
class MessageInfo {
  final String id;
  final String senderId;
  final String senderUsername;
  final String? senderProfileImage;
  final String filePath;
  final int fileSize;
  final int? duration;
  final String mimeType;
  final DateTime sentAt;
  final bool isRead;
  final DateTime? readAt;

  MessageInfo({
    required this.id,
    required this.senderId,
    required this.senderUsername,
    this.senderProfileImage,
    required this.filePath,
    required this.fileSize,
    this.duration,
    required this.mimeType,
    required this.sentAt,
    required this.isRead,
    this.readAt,
  });

  /// JSONからMessageInfoオブジェクトを生成
  factory MessageInfo.fromJson(Map<String, dynamic> json) {
    return MessageInfo(
      id: json['_id'],
      senderId: json['sender']['_id'] ?? json['sender'],
      senderUsername: json['sender']['username'] ?? 'Unknown',
      senderProfileImage: json['sender']['profileImage'],
      filePath: json['filePath'],
      fileSize: json['fileSize'],
      duration: json['duration'],
      mimeType: json['mimeType'] ?? 'audio/mpeg',
      sentAt: DateTime.parse(json['sentAt']),
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
    );
  }
}

class MessageService {
  /// ========================================
  /// メッセージ送信
  /// POST /messages/send
  /// ========================================
  /// 【パラメータ】
  /// - voiceFile: 音声ファイル（File）
  /// - receiverIds: 受信者のIDリスト
  /// - duration: 録音時間（秒）
  ///
  /// 【処理フロー】
  /// ①保存されているJWTトークンを取得
  /// ②MultipartRequestを作成
  /// ③音声ファイルを添付
  /// ④receiverIdsをJSON文字列に変換して送信
  /// ⑤レスポンスを確認
  static Future<String> sendMessage({
    required File voiceFile,
    required List<String> receiverIds,
    int? duration,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('認証が必要です');
    }

    // MultipartRequestを作成
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$BASE_URL/messages/send'),
    );

    // ヘッダーを設定
    request.headers['Authorization'] = 'Bearer $token';

    // 音声ファイルを添付
    request.files.add(
      await http.MultipartFile.fromPath('voice', voiceFile.path),
    );

    // 受信者IDリストをJSON文字列として送信
    request.fields['receivers'] = jsonEncode(receiverIds);

    // 録音時間がある場合は送信
    if (duration != null) {
      request.fields['duration'] = duration.toString();
    }

    // リクエスト送信
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['messageId'];
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'メッセージの送信に失敗しました');
    }
  }

  /// ========================================
  /// 受信メッセージリスト取得
  /// GET /messages/received
  /// ========================================
  /// 自分宛てのメッセージ一覧を取得します
  ///
  /// 【処理フロー】
  /// ①保存されているJWTトークンを取得
  /// ②GET リクエスト送信
  /// ③レスポンスをMessageInfoリストに変換
  static Future<List<MessageInfo>> getReceivedMessages() async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('認証が必要です');
    }

    final response = await http.get(
      Uri.parse('$BASE_URL/messages/received'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => MessageInfo.fromJson(json)).toList();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? '受信メッセージの取得に失敗しました');
    }
  }

  /// ========================================
  /// 送信メッセージリスト取得
  /// GET /messages/sent
  /// ========================================
  /// 自分が送信したメッセージの一覧を取得します
  static Future<List<dynamic>> getSentMessages() async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('認証が必要です');
    }

    final response = await http.get(
      Uri.parse('$BASE_URL/messages/sent'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? '送信メッセージの取得に失敗しました');
    }
  }

  /// ========================================
  /// メッセージを既読にする
  /// PUT /messages/:id/read
  /// ========================================
  /// 【パラメータ】
  /// - messageId: 既読にするメッセージのID
  ///
  /// 【処理フロー】
  /// ①保存されているJWTトークンを取得
  /// ②PUT リクエスト送信
  /// ③ステータスコード200を確認
  static Future<void> markAsRead(String messageId) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('認証が必要です');
    }

    final response = await http.put(
      Uri.parse('$BASE_URL/messages/$messageId/read'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? '既読更新に失敗しました');
    }
  }

  /// ========================================
  /// メッセージ削除
  /// DELETE /messages/:id
  /// ========================================
  /// 【パラメータ】
  /// - messageId: 削除するメッセージのID
  ///
  /// 【処理フロー】
  /// ①保存されているJWTトークンを取得
  /// ②DELETE リクエスト送信
  /// ③ステータスコード200を確認
  static Future<void> deleteMessage(String messageId) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('認証が必要です');
    }

    final response = await http.delete(
      Uri.parse('$BASE_URL/messages/$messageId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'メッセージの削除に失敗しました');
    }
  }

  /// ========================================
  /// 音声ファイルダウンロード
  /// GET /messages/:id/download
  /// ========================================
  /// メッセージの音声ファイルをダウンロードします
  ///
  /// 【パラメータ】
  /// - messageId: ダウンロードするメッセージのID
  /// - savePath: 保存先のパス
  ///
  /// 【処理フロー】
  /// ①保存されているJWTトークンを取得
  /// ②GET リクエスト送信（ストリーミング）
  /// ③ファイルに書き込み
  static Future<String> downloadMessage({
    required String messageId,
    required String savePath,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('認証が必要です');
    }

    final response = await http.get(
      Uri.parse('$BASE_URL/messages/$messageId/download'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      // ファイルに書き込み
      final file = File(savePath);
      await file.writeAsBytes(response.bodyBytes);
      return savePath;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'ファイルのダウンロードに失敗しました');
    }
  }

  /// ========================================
  /// 音声ファイルのURLを取得
  /// ========================================
  /// メッセージの音声ファイルを直接再生するためのURLを返します
  ///
  /// 【注意】
  /// このメソッドは認証トークンを含まないため、
  /// バックエンドで静的ファイル配信が有効な場合のみ使用可能です
  static String getAudioUrl(String messageId) {
    return '$BASE_URL/messages/$messageId/download';
  }
}
