// ========================================
// メッセージ関連APIサービス
// ========================================
// メッセージ送信、受信リスト取得、既読管理などの
// バックエンドAPIと通信する機能を提供します

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'auth_service.dart';
import 'offline_service.dart';
import 'network_connectivity_service.dart';
import 'package:voice_message_app/models/offline_model.dart';

/// メッセージ情報を表すクラス
class MessageInfo {
  final String id;
  final String senderId;
  final String senderUsername;
  final String? senderProfileImage;
  final String messageType; // 'voice' | 'text'
  final String? textContent;
  final bool isMine;
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
    this.messageType = 'voice',
    this.textContent,
    this.isMine = false,
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
      messageType: json['messageType'] ?? 'voice',
      textContent: json['textContent'],
      isMine: json['isMine'] ?? false,
      filePath: json['filePath'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      duration: json['duration'],
      mimeType: json['mimeType'] ?? 'audio/mpeg',
      sentAt: DateTime.parse(json['sentAt']),
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
    );
  }
}

/// スレッド情報を表すクラス
class ThreadInfo {
  final String senderId;
  final String senderUsername;
  final String? senderProfileImage;
  final MessageInfo lastMessage;
  final int unreadCount;
  final int totalCount;
  final DateTime lastMessageAt;

  ThreadInfo({
    required this.senderId,
    required this.senderUsername,
    this.senderProfileImage,
    required this.lastMessage,
    required this.unreadCount,
    required this.totalCount,
    required this.lastMessageAt,
  });

  /// JSONからThreadInfoオブジェクトを生成
  factory ThreadInfo.fromJson(Map<String, dynamic> json) {
    return ThreadInfo(
      senderId: json['sender']['_id'],
      senderUsername: json['sender']['username'],
      senderProfileImage: json['sender']['profileImage'],
      lastMessage: MessageInfo(
        id: json['lastMessage']['_id'],
        senderId: json['sender']['_id'],
        senderUsername: json['sender']['username'],
        senderProfileImage: json['sender']['profileImage'],
        messageType: json['lastMessage']['messageType'] ?? 'voice',
        textContent: json['lastMessage']['textContent'],
        isMine: json['lastMessage']['isMine'] ?? false,
        filePath: '',
        fileSize: 0,
        duration: json['lastMessage']['duration'],
        mimeType: 'audio/mpeg',
        sentAt: DateTime.parse(json['lastMessage']['sentAt']),
        isRead: json['lastMessage']['isRead'] ?? false,
        readAt: null,
      ),
      unreadCount: json['unreadCount'],
      totalCount: json['totalCount'],
      lastMessageAt: DateTime.parse(json['lastMessageAt']),
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

    final networkService = NetworkConnectivityService();

    // ========================================
    // オフラインモード判定
    // ========================================
    if (!networkService.isOnline) {
      // アプリがオフラインの場合、メッセージをローカルに保存
      return _saveMessageOffline(
        voiceFile: voiceFile,
        receiverIds: receiverIds,
        duration: duration,
      );
    }

    // ========================================
    // オンラインモード - サーバーに送信
    // ========================================
    try {
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

      // タイムアウト付きでリクエスト送信（30秒）
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          // タイムアウト時はオフラインモードで保存
          throw Exception('リクエストタイムアウト - オフラインモードで保存します');
        },
      );

      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['messageId'];
      } else {
        final error = jsonDecode(response.body);

        // 5xxエラーやネットワークエラーの場合、オフラインモードで保存
        if (response.statusCode >= 500) {
          return _saveMessageOffline(
            voiceFile: voiceFile,
            receiverIds: receiverIds,
            duration: duration,
          );
        }

        throw Exception(error['error'] ?? 'メッセージの送信に失敗しました');
      }
    } catch (e) {
      // ネットワークエラーの場合、オフラインモードで保存
      if (e is SocketException || e.toString().contains('タイムアウト')) {
        return _saveMessageOffline(
          voiceFile: voiceFile,
          receiverIds: receiverIds,
          duration: duration,
        );
      }
      rethrow;
    }
  }

  /// メッセージをオフラインで保存
  static Future<String> _saveMessageOffline({
    required File voiceFile,
    required List<String> receiverIds,
    required int? duration,
  }) async {
    final offlineService = OfflineService();

    // ローカルIDを生成
    const uuid = Uuid();
    final messageId = uuid.v4();

    // メッセージファイルのサイズを取得
    final fileStat = await voiceFile.stat();
    final fileSize = fileStat.size;

    // 現在のユーザーIDを取得
    final currentUserId = await AuthService.getMe().then(
      (user) => user['_id'] ?? user['id'],
    );

    // オフラインメッセージオブジェクトを作成
    final offlineMessage = OfflineMessage(
      id: messageId,
      senderId: currentUserId,
      receiverIds: receiverIds,
      filePath: voiceFile.path,
      duration: duration ?? 0,
      fileSize: fileSize,
      sentAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
      createdAt: DateTime.now(),
    );

    // ローカルストレージに保存
    await offlineService.saveOfflineMessage(offlineMessage);

    // 送信待機中メッセージ数をカウント
    await offlineService.incrementOfflineSentCount();

    print('📱 オフラインモード: メッセージをローカルに保存しました (ID: $messageId)');
    print('📊 ネットワーク復帰時に自動的に送信されます');

    return messageId;
  }

  /// ========================================
  /// テキストメッセージ送信
  /// POST /messages/send-text
  /// ========================================
  static Future<void> sendTextMessage({
    required List<String> receiverIds,
    required String textContent,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('認証が必要です');

    final response = await http.post(
      Uri.parse('$BASE_URL/messages/send-text'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'receivers': receiverIds, 'textContent': textContent}),
    );

    if (response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'テキストメッセージの送信に失敗しました');
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
  /// ②GET リクエスト送信（オンラインの場合）
  /// ③レスポンスをMessageInfoリストに変換
  /// ④オフラインの場合はキャッシュから取得
  static Future<List<MessageInfo>> getReceivedMessages() async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('認証が必要です');
    }

    final networkService = NetworkConnectivityService();
    final offlineService = OfflineService();

    try {
      // ========================================
      // オンラインモード - サーバーから最新データ取得
      // ========================================
      if (networkService.isOnline) {
        final response = await http
            .get(
              Uri.parse('$BASE_URL/messages/received'),
              headers: {'Authorization': 'Bearer $token'},
            )
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                throw TimeoutException('リクエストタイムアウト');
              },
            );

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          final messages = data.map((json) {
            return MessageInfo.fromJson(json);
          }).toList();

          // キャッシュに保存（後で使用するため）
          _cacheReceivedMessages(messages);

          return messages;
        } else {
          final error = jsonDecode(response.body);
          throw Exception(error['error'] ?? '受信メッセージの取得に失敗しました');
        }
      } else {
        // ========================================
        // オフラインモード - キャッシュから取得
        // ========================================
        print('💾 オフラインモード: キャッシュからメッセージを読み込み中...');

        final cachedMessages = await offlineService.getAllCachedMessages();

        if (cachedMessages.isEmpty) {
          print('⚠️  キャッシュされたメッセージがありません');
          return [];
        }

        // CachedMessageInfo を MessageInfo に変換
        return cachedMessages.map((cached) {
          return MessageInfo(
            id: cached.id,
            senderId: cached.senderId,
            senderUsername: cached.senderName,
            senderProfileImage: cached.senderProfileImage,
            filePath: cached.filePath,
            fileSize: cached.fileSize,
            duration: null,
            mimeType: 'audio/mpeg',
            sentAt: cached.sentAt,
            isRead: cached.isRead,
            readAt: cached.readAt,
          );
        }).toList();
      }
    } on TimeoutException {
      // タイムアウト時はキャッシュから取得
      print('⏱️  タイムアウト: キャッシュからメッセージを読み込み中...');

      final cachedMessages = await offlineService.getAllCachedMessages();
      return cachedMessages.map((cached) {
        return MessageInfo(
          id: cached.id,
          senderId: cached.senderId,
          senderUsername: cached.senderName,
          senderProfileImage: cached.senderProfileImage,
          filePath: cached.filePath,
          fileSize: cached.fileSize,
          duration: null,
          mimeType: 'audio/mpeg',
          sentAt: cached.sentAt,
          isRead: cached.isRead,
          readAt: cached.readAt,
        );
      }).toList();
    }
  }

  /// 受信メッセージをキャッシュに保存
  static Future<void> _cacheReceivedMessages(List<MessageInfo> messages) async {
    final offlineService = OfflineService();

    final cachedMessages = messages.map((msg) {
      return CachedMessageInfo(
        id: msg.id,
        senderId: msg.senderId,
        senderName: msg.senderUsername,
        senderProfileImage: msg.senderProfileImage,
        receiverIds: [],
        filePath: msg.filePath,
        duration: msg.duration ?? 0,
        fileSize: msg.fileSize,
        isRead: msg.isRead,
        readAt: msg.readAt,
        sentAt: msg.sentAt,
        cachedAt: DateTime.now(),
        isDownloaded: false,
      );
    }).toList();

    await offlineService.cacheMultipleMessages(cachedMessages);
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
  /// 指定したメッセージを削除します
  ///
  /// 【パラメータ】
  /// - messageId: 削除するメッセージのID
  ///
  /// 【処理フロー】
  /// ①ローカルキャッシュから関連ファイルを削除
  /// ②保存されているJWTトークンを取得
  /// ③DELETE リクエスト送信
  /// ④ステータスコード200を確認
  ///
  /// 【ローカルファイル削除】
  /// - アプリは一時ディレクトリに `{messageId}.m4a` という形式でファイルを保存
  /// - メッセージ削除時にこれらファイルをクリーンアップ
  static Future<void> deleteMessage(String messageId) async {
    // 【段階1】ローカルキャッシュファイルの削除
    try {
      final tempDir = await getTemporaryDirectory();
      final cachedFilePath = '${tempDir.path}/$messageId.m4a';
      final cachedFile = File(cachedFilePath);

      if (await cachedFile.exists()) {
        await cachedFile.delete();
        print('ローカルキャッシュをクリア: $cachedFilePath');
      }
    } catch (e) {
      // ローカルファイル削除失敗でもサーバー削除は続行
      print('ローカルファイル削除エラー: $e');
    }

    // 【段階2】サーバー側の削除
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

  /// ========================================
  /// メッセージ検索
  /// GET /messages/search
  /// ========================================
  /// 受信メッセージを検索およびフィルタリングします
  ///
  /// 【パラメータ】
  /// - searchQuery: 検索文字列（送信者のユーザー名）（オプション）
  /// - dateFrom: 開始日時（オプション）
  /// - dateTo: 終了日時（オプション）
  /// - isRead: 既読フィルター（true/false/null）（オプション）
  ///
  /// 【処理フロー】
  /// ①保存されているJWTトークンを取得
  /// ②クエリパラメータを構築
  /// ③GET リクエスト送信
  /// ④レスポンスからMessageInfoリストを生成
  static Future<List<MessageInfo>> searchMessages({
    String? searchQuery,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool? isRead,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('認証が必要です');
    }

    // クエリパラメータを構築
    final queryParams = <String, String>{};
    if (searchQuery != null && searchQuery.isNotEmpty) {
      queryParams['q'] = searchQuery;
    }
    if (dateFrom != null) {
      queryParams['dateFrom'] = dateFrom.toIso8601String();
    }
    if (dateTo != null) {
      queryParams['dateTo'] = dateTo.toIso8601String();
    }
    if (isRead != null) {
      queryParams['isRead'] = isRead.toString();
    }

    final uri = Uri.parse(
      '$BASE_URL/messages/search',
    ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => MessageInfo.fromJson(json)).toList();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'メッセージの検索に失敗しました');
    }
  }

  /// ========================================
  /// スレッド一覧取得（送信者ごとにグループ化）
  /// GET /messages/threads
  /// ========================================
  /// 受信メッセージを送信者ごとにグループ化して取得します
  ///
  /// 【処理フロー】
  /// ①保存されているJWTトークンを取得
  /// ②GET リクエスト送信
  /// ③レスポンスからThreadInfoリストを生成
  static Future<List<ThreadInfo>> getMessageThreads() async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('認証が必要です');
    }

    try {
      final response = await http
          .get(
            Uri.parse('$BASE_URL/messages/threads'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => ThreadInfo.fromJson(json)).toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'スレッド一覧の取得に失敗しました');
      }
    } on SocketException {
      throw Exception('サーバーに接続できません。バックエンドが起動しているか確認してください。');
    } on TimeoutException {
      throw Exception('接続がタイムアウトしました。再度お試しください。');
    } on http.ClientException {
      throw Exception('通信エラーが発生しました。ネットワーク接続を確認してください。');
    }
  }

  /// ========================================
  /// 特定の送信者からのメッセージ取得
  /// GET /messages/thread/:senderId
  /// ========================================
  /// 指定した送信者からの全メッセージを取得します
  ///
  /// 【パラメータ】
  /// - senderId: 送信者のユーザーID
  ///
  /// 【処理フロー】
  /// ①保存されているJWTトークンを取得
  /// ②GET リクエスト送信
  /// ③レスポンスからMessageInfoリストを生成
  static Future<List<MessageInfo>> getThreadMessages(String senderId) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('認証が必要です');
    }

    try {
      final response = await http
          .get(
            Uri.parse('$BASE_URL/messages/thread/$senderId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => MessageInfo.fromJson(json)).toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'メッセージの取得に失敗しました');
      }
    } on SocketException {
      throw Exception('サーバーに接続できません。バックエンドが起動しているか確認してください。');
    } on TimeoutException {
      throw Exception('接続がタイムアウトしました。再度お試しください。');
    } on http.ClientException {
      throw Exception('通信エラーが発生しました。ネットワーク接続を確認してください。');
    }
  }
}
