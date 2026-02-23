// ========================================
// 通知APIサービス
// ========================================
// 通知の取得・送信・削除・既読操作を行うサービスです

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// 通知情報を表すクラス
class NotificationInfo {
  final String id;
  final String type; // 'follow' | 'message' | 'system'
  final String content;
  final String? relatedId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final NotificationSender? sender;

  NotificationInfo({
    required this.id,
    required this.type,
    required this.content,
    this.relatedId,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    this.sender,
  });

  factory NotificationInfo.fromJson(Map<String, dynamic> json) {
    return NotificationInfo(
      id:        json['_id']?.toString() ?? '',
      type:      json['type'] as String,
      content:   json['content'] as String,
      relatedId: json['relatedId']?.toString(),
      isRead:    json['isRead'] as bool? ?? false,
      readAt:    json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      sender: json['sender'] != null
          ? NotificationSender.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// 通知の送信者情報
class NotificationSender {
  final String id;
  final String username;
  final String handle;
  final String? profileImage;

  NotificationSender({
    required this.id,
    required this.username,
    required this.handle,
    this.profileImage,
  });

  factory NotificationSender.fromJson(Map<String, dynamic> json) {
    return NotificationSender(
      id:           json['_id']?.toString() ?? '',
      username:     json['username'] as String,
      handle:       json['handle'] as String,
      profileImage: json['profileImage']?.toString(),
    );
  }
}

/// ページング情報
class NotificationPagination {
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNext;

  NotificationPagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNext,
  });

  factory NotificationPagination.fromJson(Map<String, dynamic> json) {
    return NotificationPagination(
      total:      json['total'] as int,
      page:       json['page'] as int,
      limit:      json['limit'] as int,
      totalPages: json['totalPages'] as int,
      hasNext:    json['hasNext'] as bool,
    );
  }
}

class NotificationService {

  // ========================================
  // 通知一覧取得
  // GET /notifications?page=1&limit=20&unreadOnly=false
  // ========================================
  /// 自分宛ての通知をページング付きで取得します
  ///
  /// 【パラメータ】
  /// - page       : ページ番号（1始まり）
  /// - limit      : 1ページあたりの件数（最大50）
  /// - unreadOnly : 未読のみ取得する場合は true
  ///
  /// 【戻り値】
  /// - notifications : 通知リスト
  /// - unreadCount   : 未読通知の総数
  /// - pagination    : ページング情報
  static Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('認証が必要です');

    final params = {
      'page':       page.toString(),
      'limit':      limit.toString(),
      'unreadOnly': unreadOnly.toString(),
    };
    final uri = Uri.parse('$BASE_URL/notifications')
        .replace(queryParameters: params);

    try {
      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'notifications': (data['notifications'] as List)
              .map((n) => NotificationInfo.fromJson(n))
              .toList(),
          'unreadCount': data['unreadCount'] as int,
          'pagination':  NotificationPagination.fromJson(
              data['pagination'] as Map<String, dynamic>),
        };
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '通知の取得に失敗しました');
      }
    } on SocketException {
      throw Exception('サーバーに接続できません。');
    } on TimeoutException {
      throw Exception('接続がタイムアウトしました。');
    }
  }

  // ========================================
  // 通知送信
  // POST /notifications
  // ========================================
  /// 指定したユーザーに通知を送信します
  ///
  /// 【パラメータ】
  /// - recipientId : 通知を受け取るユーザーのID
  /// - type        : 通知種別（'follow' | 'message' | 'system'）
  /// - content     : 通知本文（500文字以内）
  /// - relatedId   : 関連リソースのID（省略可）
  static Future<NotificationInfo> sendNotification({
    required String recipientId,
    required String type,
    required String content,
    String? relatedId,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('認証が必要です');

    final body = <String, dynamic>{
      'recipientId': recipientId,
      'type':        type,
      'content':     content,
      if (relatedId != null) 'relatedId': relatedId,
    };

    try {
      final response = await http
          .post(
            Uri.parse('$BASE_URL/notifications'),
            headers: {
              'Authorization':  'Bearer $token',
              'Content-Type':   'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return NotificationInfo.fromJson(
            data['notification'] as Map<String, dynamic>);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '通知の送信に失敗しました');
      }
    } on SocketException {
      throw Exception('サーバーに接続できません。');
    } on TimeoutException {
      throw Exception('接続がタイムアウトしました。');
    }
  }

  // ========================================
  // 通知削除
  // DELETE /notifications/:id
  // ========================================
  /// 自分宛ての通知を削除します
  ///
  /// 【パラメータ】
  /// - notificationId : 削除する通知のID
  static Future<void> deleteNotification(String notificationId) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('認証が必要です');

    try {
      final response = await http
          .delete(
            Uri.parse('$BASE_URL/notifications/$notificationId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '通知の削除に失敗しました');
      }
    } on SocketException {
      throw Exception('サーバーに接続できません。');
    } on TimeoutException {
      throw Exception('接続がタイムアウトしました。');
    }
  }

  // ========================================
  // 通知を既読にする
  // PATCH /notifications/:id/read
  // ========================================
  /// 指定した通知を既読にします
  ///
  /// 【パラメータ】
  /// - notificationId : 既読にする通知のID
  static Future<void> markAsRead(String notificationId) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('認証が必要です');

    final response = await http.patch(
      Uri.parse('$BASE_URL/notifications/$notificationId/read'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? '既読の更新に失敗しました');
    }
  }

  // ========================================
  // 全通知を既読にする
  // PATCH /notifications/read-all
  // ========================================
  /// 自分宛ての未読通知をすべて既読にします
  static Future<void> markAllAsRead() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('認証が必要です');

    final response = await http.patch(
      Uri.parse('$BASE_URL/notifications/read-all'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? '既読の更新に失敗しました');
    }
  }
}
