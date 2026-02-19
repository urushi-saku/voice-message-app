// ========================================
// Firebase Cloud Messaging (FCM) サービス
// ========================================
// プッシュ通知の受信・管理を行うサービス

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// 通知チャンネル定義
const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'voice_messages',
  'ボイスメッセージ',
  description: '音声メッセージとテキストメッセージの通知',
  importance: Importance.max,
);

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

/// バックグラウンド通知ハンドラー
/// アプリが終了している状態で通知が来た時に実行される
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('バックグラウンド通知を受信: ${message.messageId}');
  print('タイトル: ${message.notification?.title}');
  print('本文: ${message.notification?.body}');
}

class FcmService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  /// ========================================
  /// FCMサービスの初期化
  /// ========================================
  /// 【処理フロー】
  /// ①flutter_local_notificationsの初期化＋Androidチャンネル作成
  /// ②通知権限をリクエスト
  /// ③FCMトークンを取得
  /// ④サーバーにトークンを送信
  /// ⑤通知リスナーを設定
  static Future<void> initialize() async {
    try {
      // ① flutter_local_notifications 初期化
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings =
          InitializationSettings(android: androidSettings);
      await _localNotifications.initialize(initSettings);

      // Android 8+ (API 26+) 向けに通知チャンネルを作成
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      print('✅ 通知チャンネル "voice_messages" を作成しました');
      // ②通知権限をリクエスト
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ 通知権限が許可されました');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('⚠️  仮の通知権限が許可されました');
      } else {
        print('❌ 通知権限が拒否されました');
        return;
      }

      // ②FCMトークンを取得
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('📱 FCMトークン取得: $token');
        // ③サーバーにトークンを送信
        await _sendTokenToServer(token);
      }

      // トークン更新時のリスナー
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('🔄 FCMトークンが更新されました: $newToken');
        _sendTokenToServer(newToken);
      });

      // ④通知リスナーを設定
      _setupNotificationListeners();

      // バックグラウンド通知ハンドラーを設定
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      print('✅ FCMサービスの初期化が完了しました');
    } catch (e) {
      print('❌ FCMサービスの初期化に失敗しました: $e');
    }
  }

  /// ========================================
  /// サーバーにFCMトークンを送信
  /// ========================================
  static Future<void> _sendTokenToServer(String token) async {
    try {
      final authToken = await AuthService.getToken();
      if (authToken == null) {
        print('⚠️  認証トークンが見つかりません。ログイン後にFCMトークンを送信してください。');
        return;
      }

      final response = await http.put(
        Uri.parse('$BASE_URL/auth/fcm-token'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'fcmToken': token}),
      );

      if (response.statusCode == 200) {
        print('✅ FCMトークンをサーバーに送信しました');
      } else {
        print('❌ FCMトークン送信失敗: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ FCMトークン送信エラー: $e');
    }
  }

  /// ========================================
  /// ログイン後にFCMトークンをサーバーへ送信（公開メソッド）
  /// ========================================
  /// ログイン・登録・アプリ起動時（既ログイン）に呼び出す
  static Future<void> sendTokenAfterLogin() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token == null) {
        print('⚠️  FCMトークンを取得できません');
        return;
      }
      await _sendTokenToServer(token);
    } catch (e) {
      print('❌ ログイン後FCMトークン送信エラー: $e');
    }
  }

  /// ========================================
  /// 通知リスナーを設定
  /// ========================================
  static void _setupNotificationListeners() {
    // フォアグラウンド通知（アプリが開いている状態）
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📬 フォアグラウンド通知を受信: ${message.messageId}');

      if (message.notification != null) {
        print('通知タイトル: ${message.notification!.title}');
        print('通知本文: ${message.notification!.body}');
      }

      // カスタムデータ
      if (message.data.isNotEmpty) {
        print('カスタムデータ: ${message.data}');
      }

      // ここでローカル通知を表示したり、UI更新したりできる
      _handleNotification(message);
    });

    // 通知タップ（バックグラウンドから開く）
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 通知をタップしてアプリを開きました: ${message.messageId}');
      _handleNotificationTap(message);
    });

    // アプリ起動時に通知から開かれたかチェック
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('🚀 通知からアプリを起動しました: ${message.messageId}');
        _handleNotificationTap(message);
      }
    });
  }

  /// ========================================
  /// 通知を受信した時の処理（フォアグラウンド）
  /// ========================================
  static void _handleNotification(RemoteMessage message) {
    if (kDebugMode) {
      print('🔔 通知内容:');
      print('  - タイトル: ${message.notification?.title}');
      print('  - 本文: ${message.notification?.body}');
      print('  - データ: ${message.data}');
    }

    final notification = message.notification;
    if (notification == null) return;

    // フォアグラウンド時にローカル通知として表示
    _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  /// ========================================
  /// 通知をタップした時の処理
  /// ========================================
  static void _handleNotificationTap(RemoteMessage message) {
    // ここで通知をタップした時の処理を実装
    // 例：特定の画面に遷移する

    final data = message.data;
    if (data.containsKey('type') && data['type'] == 'new_message') {
      final messageId = data['messageId'];
      final senderId = data['senderId'];
      print('📨 メッセージ通知をタップ: messageId=$messageId, senderId=$senderId');

      // ここでメッセージ画面に遷移する処理を追加できる
      // 例：NavigatorService.navigateToMessage(messageId);
    }
  }

  /// ========================================
  /// 現在のFCMトークンを取得
  /// ========================================
  static Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('❌ FCMトークン取得エラー: $e');
      return null;
    }
  }

  /// ========================================
  /// FCMトークンを削除（ログアウト時）
  /// ========================================
  static Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      print('✅ FCMトークンを削除しました');
    } catch (e) {
      print('❌ FCMトークン削除エラー: $e');
    }
  }
}
