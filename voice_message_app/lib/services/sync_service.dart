// ============================================================================
// 同期処理サービス
// ============================================================================
// 目的：オフラインで保存されたデータをサーバーと同期
//       ネットワーク復帰時に自動的にデータを同期

import 'package:flutter/foundation.dart';
import 'package:voice_message_app/models/offline_model.dart';
import 'package:voice_message_app/services/offline_service.dart';
import 'package:voice_message_app/services/message_service.dart';
import 'package:voice_message_app/services/network_connectivity_service.dart';

class SyncService extends ChangeNotifier {
  // ============================================================================
  // シングルトンパターン
  // ============================================================================
  static final SyncService _instance = SyncService._internal();

  factory SyncService() {
    return _instance;
  }

  SyncService._internal();

  // ============================================================================
  // 依存関係
  // ============================================================================

  final OfflineService _offlineService = OfflineService();
  // ignore: unused_field
  late MessageService _messageService;
  late NetworkConnectivityService _networkService;

  // ============================================================================
  // プロパティ
  // ============================================================================

  bool _isSyncing = false;
  int _syncedCount = 0;
  int _syncFailedCount = 0;
  DateTime? _lastSyncTime;

  // ============================================================================
  // ゲッター
  // ============================================================================

  /// 現在同期中か
  bool get isSyncing => _isSyncing;

  /// 同期済みメッセージ数
  int get syncedCount => _syncedCount;

  /// 同期失敗メッセージ数
  int get syncFailedCount => _syncFailedCount;

  /// 最後の同期時刻
  DateTime? get lastSyncTime => _lastSyncTime;

  // ============================================================================
  // 初期化
  // ============================================================================

  /// 同期サービスを初期化
  /// ネットワーク監視サービスの設定後に呼び出す
  Future<void> initialize(
    MessageService messageService,
    NetworkConnectivityService networkService,
  ) async {
    _messageService = messageService;
    _networkService = networkService;

    // 統計情報を読み込み
    final stats = await _offlineService.getSyncStatistics();
    _syncedCount = stats.totalMessagesSynced;
    _syncFailedCount = stats.failedSyncCount;
    _lastSyncTime = stats.lastSyncTime;

    // ネットワーク接続復帰時に同期を開始
    _networkService.addOnOnlineCallback(() {
      _onNetworkOnline();
    });

    // オフラインになった時の処理
    _networkService.addOnOfflineCallback(() {
      _onNetworkOffline();
    });

    if (kDebugMode) {
      print('[同期] SyncService初期化完了');
    }
  }

  // ============================================================================
  // 同期処理
  // ============================================================================

  /// ネットワーク接続復帰時の処理
  void _onNetworkOnline() {
    if (kDebugMode) {
      print('[同期] ネットワーク復帰を検出 - 同期開始');
    }

    // 自動同期設定を確認
    _performAutoSync();
  }

  /// オフライン移行時の処理
  void _onNetworkOffline() {
    if (kDebugMode) {
      print('[同期] ネットワーク切断を検出');
    }

    // 同期中の場合はキャンセル
    if (_isSyncing) {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// 自動同期を実行
  Future<void> _performAutoSync() async {
    final config = await _offlineService.getOfflineConfig();

    if (!config.autoSyncOnReconnect) {
      if (kDebugMode) {
        print('[同期] 自動同期が無効化されています');
      }
      return;
    }

    await syncOfflineMessages();
  }

  /// オフラインメッセージを同期
  Future<void> syncOfflineMessages() async {
    // 既に同期中の場合は実行しない
    if (_isSyncing) {
      if (kDebugMode) {
        print('[同期] 既に同期処理が進行中です');
      }
      return;
    }

    // ネットワークが接続していない場合は実行しない
    if (!_networkService.isOnline) {
      if (kDebugMode) {
        print('[同期] ネットワーク接続がないため同期スキップ');
      }
      return;
    }

    _isSyncing = true;
    notifyListeners();

    try {
      // 同期待機中のメッセージを取得
      final pendingMessages = await _offlineService.getPendingMessages();

      if (pendingMessages.isEmpty) {
        if (kDebugMode) {
          print('[同期] 同期待機中のメッセージなし');
        }
        _isSyncing = false;
        notifyListeners();
        return;
      }

      if (kDebugMode) {
        print('[同期] ${pendingMessages.length}件のメッセージを同期開始');
      }

      // 各メッセージを同期
      for (final message in pendingMessages) {
        await _syncSingleMessage(message);
      }

      // 統計情報を更新
      final stats = await _offlineService.getSyncStatistics();
      _lastSyncTime = DateTime.now();
      await _offlineService.updateSyncStatistics(stats);

      if (kDebugMode) {
        print('[同期] 同期完了 (成功: $_syncedCount, 失敗: $_syncFailedCount)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[同期] エラーが発生: $e');
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// 単一のメッセージを同期
  Future<void> _syncSingleMessage(OfflineMessage message) async {
    try {
      // 同期状態を「同期中」に更新
      await _offlineService.updateMessageSyncStatus(
        message.id,
        SyncStatus.syncing,
      );

      // サーバーにメッセージを送信
      // NOTE: MessageServiceのsendMessageメソッドを使用
      //       ファイルパスとメタデータをサーバーに送信

      // 実装例: await _messageService.sendMessage(...)

      // 同期成功
      await _offlineService.updateMessageSyncStatus(
        message.id,
        SyncStatus.synced,
      );

      _syncedCount++;
      await _offlineService.incrementSyncedCount();

      if (kDebugMode) {
        print('[同期] メッセージ同期成功: ${message.id}');
      }
    } catch (e) {
      // 同期失敗
      await _offlineService.updateMessageSyncStatus(
        message.id,
        SyncStatus.failed,
      );

      _syncFailedCount++;
      await _offlineService.incrementFailedCount();

      if (kDebugMode) {
        print('[同期] メッセージ同期失敗: ${message.id} - エラー: $e');
      }
    }
  }

  /// 失敗したメッセージを再同期
  Future<void> retrySyncFailedMessages() async {
    final failedMessages = await _offlineService.getFailedMessages();

    if (failedMessages.isEmpty) {
      if (kDebugMode) {
        print('[同期] 再同期対象のメッセージなし');
      }
      return;
    }

    if (kDebugMode) {
      print('[同期] ${failedMessages.length}件の失敗メッセージを再同期');
    }

    for (final message in failedMessages) {
      // 状態をリセットして再同期
      await _offlineService.updateMessageSyncStatus(
        message.id,
        SyncStatus.pending,
      );
    }

    // 同期を実行
    await syncOfflineMessages();
  }

  // ============================================================================
  // キャッシュ更新
  // ============================================================================

  /// ユーザー情報キャッシュを更新
  Future<void> updateUserCache(String userId) async {
    try {
      // NOTE: UserServiceから最新情報を取得してキャッシュに保存
      // 実装例:
      // final userInfo = await _userService.getUserById(userId);
      // await _offlineService.cacheUserInfo(userInfo);
    } catch (e) {
      if (kDebugMode) {
        print('[同期] ユーザー情報キャッシュ更新失敗: $e');
      }
    }
  }

  /// メッセージキャッシュを更新
  Future<void> updateMessageCache() async {
    try {
      // NOTE: MessageServiceから最新メッセージを取得してキャッシュに保存
      // 実装例:
      // final messages = await _messageService.getReceivedMessages();
      // await _offlineService.cacheMultipleMessages(messages);
    } catch (e) {
      if (kDebugMode) {
        print('[同期] メッセージキャッシュ更新失敗: $e');
      }
    }
  }

  /// フォロー情報キャッシュを更新
  Future<void> updateFollowCache(String userId) async {
    try {
      // NOTE: UserServiceから最新フォロー情報を取得してキャッシュに保存
      // 実装例:
      // final followers = await _userService.getFollowers(userId);
      // final following = await _userService.getFollowing(userId);
      // await _offlineService.cachedFollowInfo(...);
    } catch (e) {
      if (kDebugMode) {
        print('[同期] フォロー情報キャッシュ更新失敗: $e');
      }
    }
  }

  // ============================================================================
  // キャッシュクリーンアップ
  // ============================================================================

  /// 古いキャッシュを削除
  Future<void> cleanupExpiredCache() async {
    try {
      await _offlineService.cleanupExpiredCache();

      if (kDebugMode) {
        print('[同期] 古いキャッシュを削除');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[同期] キャッシュクリーンアップエラー: $e');
      }
    }
  }

  // ============================================================================
  // ストレージ管理
  // ============================================================================

  /// ストレージ情報を取得
  Future<Map<String, int>> getStorageInfo() async {
    return _offlineService.getStorageInfo();
  }

  /// すべてのオフラインデータをクリア
  Future<void> clearAllOfflineData() async {
    try {
      await _offlineService.clearAllOfflineData();

      if (kDebugMode) {
        print('[同期] すべてのオフラインデータをクリア');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[同期] データクリアエラー: $e');
      }
    }
  }
}
