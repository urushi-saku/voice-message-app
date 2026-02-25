// ========================================
// メッセージ関連APIサービス
// ========================================
// メッセージ送信、受信リスト取得、既読管理などの
// バックエンドAPIと通信する機能を提供します
//
// ※ MessageInfo / ThreadInfo は models/message.dart へ移動済み

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'auth_service.dart';
import 'e2ee_service.dart';
import 'offline_service.dart';
import 'package:voice_message_app/models/offline_model.dart';
import 'package:voice_message_app/models/message.dart';

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
    File? thumbnailFile, // 添付画像（任意）
  }) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('認証が必要です');
    }

    // =====================================
    // E2EE 暗号化（受信者全員が公開鍵登録済みの場合）
    // =====================================
    File uploadFile = voiceFile;
    String? e2eeContentNonce;
    String? e2eeEncryptedKeysJson;

    try {
      final myUserId = await AuthService.getCurrentUserId();
      if (myUserId != null) {
        // 全受信者の公開鍵を並列取得（自分も含む）
        final allIds = [...receiverIds, myUserId];
        final pkResults = await Future.wait(
          allIds.map((id) => E2eeService.fetchPublicKey(id)),
        );

        if (pkResults.every((pk) => pk != null)) {
          final receivers = allIds.asMap().entries.map((e) {
            return ReceiverKey(
              userId: allIds[e.key],
              publicKey: pkResults[e.key]!,
            );
          }).toList();

          // 音声バイト列を暗号化
          final audioBytes = await voiceFile.readAsBytes();
          final payload = await E2eeService.encryptForReceivers(
            audioBytes,
            receivers,
          );

          // 暗号化済みバイト列を一時ファイルに保存
          final tempDir = await getTemporaryDirectory();
          final encFile = File(
            '${tempDir.path}/enc_${DateTime.now().millisecondsSinceEpoch}.m4a',
          );
          await encFile.writeAsBytes(base64Decode(payload.encryptedContent));
          uploadFile = encFile;

          e2eeContentNonce = payload.contentNonce;
          e2eeEncryptedKeysJson = jsonEncode(
            payload.encryptedKeys.map((k) => k.toJson()).toList(),
          );
        }
      }
    } catch (e) {
      // E2EE 失敗時は暗号化なしでの送信にフォールバック
      print('[E2EE] 暗号化スキップ: $e');
    }

    // ========================================
    // サーバーへ送信（失敗時はオフラインに自動フォールバック）
    // ========================================
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$BASE_URL/messages/send'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // 音声ファイルを添付します（E2EE が有効な場合は暗号化済み）
      request.files.add(
        await http.MultipartFile.fromPath(
          'voice',
          uploadFile.path,
          contentType: MediaType('audio', 'mp4'),
        ),
      );

      if (thumbnailFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'thumbnail',
            thumbnailFile.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      request.fields['receivers'] = jsonEncode(receiverIds);

      if (duration != null) {
        request.fields['duration'] = duration.toString();
      }

      // E2EE メタデータを添付
      if (e2eeContentNonce != null && e2eeEncryptedKeysJson != null) {
        request.fields['isEncrypted'] = 'true';
        request.fields['contentNonce'] = e2eeContentNonce;
        request.fields['encryptedKeys'] = e2eeEncryptedKeysJson;
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
        // 5xxエラー → サーバー側のエラー内容をログに出したうえでオフライン保存
        if (response.statusCode >= 500) {
          print('🔴 サーバーエラー ${response.statusCode}: ${response.body}');
          final id = await _saveMessageOffline(
            voiceFile: voiceFile,
            receiverIds: receiverIds,
            duration: duration,
          );
          throw _OfflineSavedException(id);
        }

        // レスポンスがJSONでない場合（HTMLエラーページなど）に対応
        try {
          final error = jsonDecode(response.body);
          throw Exception(
            error['error'] ?? 'メッセージの送信に失敗しました (${response.statusCode})',
          );
        } on FormatException {
          throw Exception(
            'サーバーエラー (${response.statusCode}): バックエンドのURLを確認してください',
          );
        }
      }
    } catch (e) {
      // SocketException: サーバーに繋がらない場合
      if (e is SocketException) {
        print(
          '🔴 SocketException: ${e.message} (adb reverse / バックエンド起動を確認してください)',
        );
        // オフライン保存してから例外を再スローすることで UI にもエラーを伝える
        final id = await _saveMessageOffline(
          voiceFile: voiceFile,
          receiverIds: receiverIds,
          duration: duration,
        );
        throw _OfflineSavedException(id);
      }
      // タイムアウト
      if (e.toString().contains('タイムアウト')) {
        print('⏱️  送信タイムアウト: オフライン保存にフォールバック');
        final id = await _saveMessageOffline(
          voiceFile: voiceFile,
          receiverIds: receiverIds,
          duration: duration,
        );
        throw _OfflineSavedException(id);
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
    // getMe() は { "user": { "id": "...", ... } } を返す
    final currentUserId = await AuthService.getMe().then((data) {
      final user = data['user'] as Map<String, dynamic>?;
      return (user?['id'] ?? user?['_id'])?.toString() ?? '';
    });

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

    // =====================================
    // E2EE 暗号化
    // =====================================
    String sendText = textContent;
    Map<String, dynamic>? e2eeFields;

    try {
      final myUserId = await AuthService.getCurrentUserId();
      if (myUserId != null) {
        final allIds = [...receiverIds, myUserId];
        final pkResults = await Future.wait(
          allIds.map((id) => E2eeService.fetchPublicKey(id)),
        );

        if (pkResults.every((pk) => pk != null)) {
          final receivers = allIds.asMap().entries.map((e) {
            return ReceiverKey(
              userId: allIds[e.key],
              publicKey: pkResults[e.key]!,
            );
          }).toList();

          // UTF-8 バイト列として暗号化
          final contentBytes = Uint8List.fromList(textContent.codeUnits);
          final payload = await E2eeService.encryptForReceivers(
            contentBytes,
            receivers,
          );

          // textContent に暗号化済みテキスト（Base64）を設定
          sendText = payload.encryptedContent;
          e2eeFields = {
            'isEncrypted': true,
            'contentNonce': payload.contentNonce,
            'encryptedKeys': payload.encryptedKeys
                .map((k) => k.toJson())
                .toList(),
          };
        }
      }
    } catch (e) {
      print('[E2EE] テキスト暗号化スキップ: $e');
    }

    final response = await http.post(
      Uri.parse('$BASE_URL/messages/send-text'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'receivers': receiverIds,
        'textContent': sendText,
        ...(e2eeFields ?? {}),
      }),
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

    final offlineService = OfflineService();

    // ========================================
    // 常にサーバーから最新データ取得を試みる
    // SocketException / タイムアウト時のみキャッシュにフォールバック
    // NOTE: isOnline チェックは connectivity_plus の誤検知を避けるため使用しない
    // ========================================
    try {
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
    } on SocketException {
      // ネットワーク未接続 → キャッシュから取得
      print('💾 SocketException: キャッシュからメッセージを読み込み中...');
      final cachedMessages = await offlineService.getAllCachedMessages();
      if (cachedMessages.isEmpty) {
        print('⚠️  キャッシュされたメッセージがありません');
        return [];
      }
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
    MessageInfo? messageInfo, // E2EE復号用
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
      Uint8List fileBytes = response.bodyBytes;

      // E2EE 復号（暗号化メッセージの場合）
      if (messageInfo?.isEncrypted == true &&
          messageInfo!.contentNonce != null &&
          messageInfo.encryptedKeys.isNotEmpty) {
        final myUserId = await AuthService.getCurrentUserId();
        if (myUserId != null) {
          final decryptedBytes = await E2eeService.decryptBytes(
            encryptedBytes: fileBytes,
            contentNonceB64: messageInfo.contentNonce!,
            encryptedKeys: messageInfo.encryptedKeys,
            myUserId: myUserId,
          );
          if (decryptedBytes != null) {
            fileBytes = decryptedBytes;
          } else {
            print('[E2EE] 音声ファイルの復号に失敗しました');
          }
        }
      }

      final file = File(savePath);
      await file.writeAsBytes(fileBytes);
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
  /// ========================================
  /// メッセージ詳細取得
  /// GET /messages/:id
  /// ========================================
  /// 指定したIDのメッセージ詳細を取得します
  ///
  /// 【パラメータ】
  /// - messageId: 取得するメッセージのID
  static Future<MessageInfo> getMessageById(String messageId) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('認証が必要です');

    try {
      final response = await http
          .get(
            Uri.parse('$BASE_URL/messages/$messageId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return MessageInfo.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'メッセージの取得に失敗しました');
      }
    } on SocketException {
      throw Exception('サーバーに接続できません。バックエンドが起動しているか確認してください。');
    } on TimeoutException {
      throw Exception('接続がタイムアウトしました。再度お試しください。');
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
    String? token = await AuthService.getToken();
    if (token == null) {
      // refreshToken で復帰を試みる
      final refreshed = await AuthService.refreshToken();
      if (!refreshed) throw Exception('ログインし直してください');
      token = await AuthService.getToken();
    }

    try {
      Future<http.Response> doRequest(String t) => http
          .get(
            Uri.parse('$BASE_URL/messages/threads'),
            headers: {'Authorization': 'Bearer $t'},
          )
          .timeout(const Duration(seconds: 10));

      var response = await doRequest(token!);

      // 401 → トークンリフレッシュして1回だけリトライ
      if (response.statusCode == 401) {
        final refreshed = await AuthService.refreshToken();
        if (!refreshed) throw Exception('ログインし直してください');
        final newToken = await AuthService.getToken();
        if (newToken == null) throw Exception('ログインし直してください');
        response = await doRequest(newToken);
      }

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => ThreadInfo.fromJson(json)).toList();
      } else {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(
          body['error'] ??
              body['message'] ??
              'スレッド一覧の取得に失敗しました（${response.statusCode}）',
        );
      }
    } on SocketException {
      throw Exception('サーバーに接続できません。バックエンドが起動しているか確認してください。');
    } on TimeoutException {
      throw Exception('接続がタイムアウトしました。再度お試しください。');
    } on http.ClientException {
      throw Exception('通信エラーが発生しました。ネットワーク接続を確認してください。');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('スレッド一覧の読み込みエラー: $e');
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
  // ========================================
  // リアクション追加
  // POST /messages/:id/reactions
  // ========================================
  static Future<List<MessageReaction>> addReaction({
    required String messageId,
    required String emoji,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('認証が必要です');

    final response = await http
        .post(
          Uri.parse('$BASE_URL/messages/$messageId/reactions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'emoji': emoji}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['reactions'] as List<dynamic>)
          .map((r) => MessageReaction.fromJson(r as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('リアクションの追加に失敗しました');
    }
  }

  // ========================================
  // リアクション削除
  // DELETE /messages/:id/reactions/:emoji
  // ========================================
  static Future<List<MessageReaction>> removeReaction({
    required String messageId,
    required String emoji,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('認証が必要です');

    final response = await http
        .delete(
          Uri.parse(
            '$BASE_URL/messages/$messageId/reactions/${Uri.encodeComponent(emoji)}',
          ),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['reactions'] as List<dynamic>)
          .map((r) => MessageReaction.fromJson(r as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('リアクションの削除に失敗しました');
    }
  }

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
        final messages = jsonList
            .map((json) => MessageInfo.fromJson(json))
            .toList();

        // E2EE テキストメッセージを復号
        final myUserId = await AuthService.getCurrentUserId();
        if (myUserId != null) {
          return await _decryptTextMessages(messages, myUserId);
        }
        return messages;
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

/// ========================================
/// E2EE テキストメッセージ一括復号ヘルパー
/// ========================================
/// テキストメッセージで isEncrypted=true のものを復号して
/// textContent を平文に置き換えた新しい MessageInfo リストを返す
Future<List<MessageInfo>> _decryptTextMessages(
  List<MessageInfo> messages,
  String myUserId,
) async {
  final result = <MessageInfo>[];
  for (final msg in messages) {
    if (msg.isEncrypted &&
        msg.messageType == 'text' &&
        msg.textContent != null &&
        msg.contentNonce != null &&
        msg.encryptedKeys.isNotEmpty) {
      try {
        final plainBytes = await E2eeService.decryptContent(
          encryptedContentB64: msg.textContent!,
          contentNonceB64: msg.contentNonce!,
          encryptedKeys: msg.encryptedKeys,
          myUserId: myUserId,
        );
        if (plainBytes != null) {
          // 復号されたバイト列を UTF-8 文字列に変換して textContent を差し替える
          result.add(
            MessageInfo(
              id: msg.id,
              senderId: msg.senderId,
              senderUsername: msg.senderUsername,
              senderProfileImage: msg.senderProfileImage,
              messageType: msg.messageType,
              textContent: String.fromCharCodes(plainBytes),
              isMine: msg.isMine,
              filePath: msg.filePath,
              fileSize: msg.fileSize,
              duration: msg.duration,
              mimeType: msg.mimeType,
              thumbnailUrl: msg.thumbnailUrl,
              sentAt: msg.sentAt,
              isRead: msg.isRead,
              readAt: msg.readAt,
              reactions: msg.reactions,
              isEncrypted: msg.isEncrypted,
              contentNonce: msg.contentNonce,
              encryptedKeys: msg.encryptedKeys,
            ),
          );
          continue;
        }
      } catch (e) {
        print('[E2EE] テキスト復号エラー (${msg.id}): $e');
      }
    }
    result.add(msg);
  }
  return result;
}

/// sendMessage がオフライン保存にフォールバックした際にスローされる
class _OfflineSavedException implements Exception {
  final String messageId;
  _OfflineSavedException(this.messageId);
  @override
  String toString() => 'offline:$messageId';
}
