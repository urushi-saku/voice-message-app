// ============================================================================
// オフラインサービス
// ============================================================================
// 目的：Hiveを使ったローカルストレージ管理
//       メッセージ、ユーザー情報、フォロー情報などをローカルに保存・取得

import 'package:hive_flutter/hive_flutter.dart';
import 'package:voice_message_app/models/offline_model.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();

  factory OfflineService() {
    return _instance;
  }

  OfflineService._internal();

  // ============================================================================
  // Hive ボックス名定数
  // ============================================================================
  static const String offlineMessagesBox = 'offline_messages';
  static const String cachedUsersBox = 'cached_users';
  static const String cachedMessagesBox = 'cached_messages';
  static const String cachedFollowBox = 'cached_follow';
  static const String offlineConfigBox = 'offline_config';
  static const String syncStatisticsBox = 'sync_statistics';

  // ============================================================================
  // 初期化
  // ============================================================================

  /// Hiveを初期化してボックスを開く
  /// アプリ起動時に一度だけ呼び出す
  static Future<void> initialize() async {
    // Hiveを初期化
    await Hive.initFlutter();

    // カスタムモデルをHiveに登録
    Hive.registerAdapter(OfflineMessageAdapter());
    Hive.registerAdapter(CachedUserInfoAdapter());
    Hive.registerAdapter(CachedMessageInfoAdapter());
    Hive.registerAdapter(CachedFollowInfoAdapter());
    Hive.registerAdapter(OfflineConfigAdapter());
    Hive.registerAdapter(SyncStatisticsAdapter());
    Hive.registerAdapter(SyncStatusAdapter());

    // 各ボックスを開く
    await Hive.openBox<OfflineMessage>(offlineMessagesBox);
    await Hive.openBox<CachedUserInfo>(cachedUsersBox);
    await Hive.openBox<dynamic>(cachedMessagesBox);
    await Hive.openBox<dynamic>(cachedFollowBox);
    await Hive.openBox<OfflineConfig>(offlineConfigBox);
    await Hive.openBox<SyncStatistics>(syncStatisticsBox);

    // デフォルト設定を初期化
    await _initializeDefaultConfig();
  }

  /// デフォルト設定を初期化
  static Future<void> _initializeDefaultConfig() async {
    final configBox = Hive.box<OfflineConfig>(offlineConfigBox);
    if (configBox.isEmpty) {
      await configBox.put('default', OfflineConfig());
    }
  }

  // ============================================================================
  // オフラインメッセージ管理
  // ============================================================================

  /// オフラインメッセージを保存（送信待機中）
  Future<void> saveOfflineMessage(OfflineMessage message) async {
    final box = Hive.box<OfflineMessage>(offlineMessagesBox);
    await box.put(message.id, message);
  }

  /// すべてのオフラインメッセージを取得
  Future<List<OfflineMessage>> getAllOfflineMessages() async {
    final box = Hive.box<OfflineMessage>(offlineMessagesBox);
    return box.values.toList();
  }

  /// オフラインメッセージを取得（ID指定）
  Future<OfflineMessage?> getOfflineMessage(String id) async {
    final box = Hive.box<OfflineMessage>(offlineMessagesBox);
    return box.get(id);
  }

  /// 同期待機中のメッセージを取得
  Future<List<OfflineMessage>> getPendingMessages() async {
    final box = Hive.box<OfflineMessage>(offlineMessagesBox);
    return box.values
        .where((msg) => msg.syncStatus == SyncStatus.pending)
        .toList();
  }

  /// 同期失敗したメッセージを取得
  Future<List<OfflineMessage>> getFailedMessages() async {
    final box = Hive.box<OfflineMessage>(offlineMessagesBox);
    return box.values
        .where((msg) => msg.syncStatus == SyncStatus.failed)
        .toList();
  }

  /// オフラインメッセージで同期中のものを取得
  Future<List<OfflineMessage>> getSyncingMessages() async {
    final box = Hive.box<OfflineMessage>(offlineMessagesBox);
    return box.values
        .where((msg) => msg.syncStatus == SyncStatus.syncing)
        .toList();
  }

  /// オフラインメッセージの同期状態を更新
  Future<void> updateMessageSyncStatus(
    String messageId,
    SyncStatus status,
  ) async {
    final box = Hive.box<OfflineMessage>(offlineMessagesBox);
    final message = box.get(messageId);
    if (message != null) {
      message.syncStatus = status;
      await message.save();
    }
  }

  /// オフラインメッセージを削除
  Future<void> deleteOfflineMessage(String id) async {
    final box = Hive.box<OfflineMessage>(offlineMessagesBox);
    await box.delete(id);
  }

  /// すべてのオフラインメッセージを削除
  Future<void> clearAllOfflineMessages() async {
    final box = Hive.box<OfflineMessage>(offlineMessagesBox);
    await box.clear();
  }

  // ============================================================================
  // ユーザー情報キャッシュ管理
  // ============================================================================

  /// ユーザー情報をキャッシュに保存
  Future<void> cacheUserInfo(CachedUserInfo user) async {
    final box = Hive.box<CachedUserInfo>(cachedUsersBox);
    await box.put(user.id, user);
  }

  /// キャッシュされたユーザー情報を取得
  Future<CachedUserInfo?> getCachedUserInfo(String userId) async {
    final box = Hive.box<CachedUserInfo>(cachedUsersBox);
    return box.get(userId);
  }

  /// すべてのキャッシュユーザーを取得
  Future<List<CachedUserInfo>> getAllCachedUsers() async {
    final box = Hive.box<CachedUserInfo>(cachedUsersBox);
    return box.values.toList();
  }

  /// 複数のユーザー情報をキャッシュに保存
  Future<void> cacheMultipleUsers(List<CachedUserInfo> users) async {
    final box = Hive.box<CachedUserInfo>(cachedUsersBox);
    for (final user in users) {
      await box.put(user.id, user);
    }
  }

  /// キャッシュされたユーザーを削除
  Future<void> deleteCachedUser(String userId) async {
    final box = Hive.box<CachedUserInfo>(cachedUsersBox);
    await box.delete(userId);
  }

  /// すべてのキャッシュユーザーを削除
  Future<void> clearCachedUsers() async {
    final box = Hive.box<CachedUserInfo>(cachedUsersBox);
    await box.clear();
  }

  // ============================================================================
  // メッセージ情報キャッシュ管理
  // ============================================================================

  /// メッセージ情報をキャッシュに保存
  Future<void> cacheMessageInfo(CachedMessageInfo message) async {
    final box = Hive.box<dynamic>(cachedMessagesBox);
    await box.put(message.id, message);
  }

  /// キャッシュされたメッセージ情報を取得
  Future<CachedMessageInfo?> getCachedMessageInfo(String messageId) async {
    final box = Hive.box<dynamic>(cachedMessagesBox);
    final data = box.get(messageId);
    if (data is CachedMessageInfo) {
      return data;
    }
    return null;
  }

  /// すべてのキャッシュメッセージを取得
  Future<List<CachedMessageInfo>> getAllCachedMessages() async {
    final box = Hive.box<dynamic>(cachedMessagesBox);
    return box.values.whereType<CachedMessageInfo>().toList();
  }

  /// 複数のメッセージ情報をキャッシュに保存
  Future<void> cacheMultipleMessages(List<CachedMessageInfo> messages) async {
    final box = Hive.box<dynamic>(cachedMessagesBox);
    for (final message in messages) {
      await box.put(message.id, message);
    }
  }

  /// キャッシュされたメッセージを削除
  Future<void> deleteCachedMessage(String messageId) async {
    final box = Hive.box<dynamic>(cachedMessagesBox);
    await box.delete(messageId);
  }

  /// すべてのキャッシュメッセージを削除
  Future<void> clearCachedMessages() async {
    final box = Hive.box<dynamic>(cachedMessagesBox);
    await box.clear();
  }

  // ============================================================================
  // フォロー情報キャッシュ管理
  // ============================================================================

  /// フォロー情報をキャッシュに保存
  Future<void> cachedFollowInfo(CachedFollowInfo followInfo) async {
    final box = Hive.box<dynamic>(cachedFollowBox);
    await box.put(followInfo.userId, followInfo);
  }

  /// キャッシュされたフォロー情報を取得
  Future<CachedFollowInfo?> getCachedFollowInfo(String userId) async {
    final box = Hive.box<dynamic>(cachedFollowBox);
    final data = box.get(userId);
    if (data is CachedFollowInfo) {
      return data;
    }
    return null;
  }

  /// すべてのキャッシュフォロー情報を取得
  Future<List<CachedFollowInfo>> getAllCachedFollowInfo() async {
    final box = Hive.box<dynamic>(cachedFollowBox);
    return box.values.whereType<CachedFollowInfo>().toList();
  }

  /// キャッシュされたフォロー情報を削除
  Future<void> deleteCachedFollowInfo(String userId) async {
    final box = Hive.box<dynamic>(cachedFollowBox);
    await box.delete(userId);
  }

  /// すべてのキャッシュフォロー情報を削除
  Future<void> clearCachedFollowInfo() async {
    final box = Hive.box<dynamic>(cachedFollowBox);
    await box.clear();
  }

  // ============================================================================
  // オフライン設定管理
  // ============================================================================

  /// オフライン設定を取得
  Future<OfflineConfig> getOfflineConfig() async {
    final box = Hive.box<OfflineConfig>(offlineConfigBox);
    return box.get('default') ?? OfflineConfig();
  }

  /// オフライン設定を更新
  Future<void> updateOfflineConfig(OfflineConfig config) async {
    final box = Hive.box<OfflineConfig>(offlineConfigBox);
    await box.put('default', config);
  }

  /// オフラインモードを有効化
  Future<void> enableOfflineMode() async {
    final config = await getOfflineConfig();
    config.enableOfflineMode = true;
    await updateOfflineConfig(config);
  }

  /// オフラインモードを無効化
  Future<void> disableOfflineMode() async {
    final config = await getOfflineConfig();
    config.enableOfflineMode = false;
    await updateOfflineConfig(config);
  }

  // ============================================================================
  // 同期統計情報管理
  // ============================================================================

  /// 同期統計情報を取得
  Future<SyncStatistics> getSyncStatistics() async {
    final box = Hive.box<SyncStatistics>(syncStatisticsBox);
    return box.get('stats') ?? SyncStatistics(lastSyncTime: DateTime.now());
  }

  /// 同期統計情報を更新
  Future<void> updateSyncStatistics(SyncStatistics stats) async {
    final box = Hive.box<SyncStatistics>(syncStatisticsBox);
    await box.put('stats', stats);
  }

  /// 同期成功数をインクリメント
  Future<void> incrementSyncedCount() async {
    final stats = await getSyncStatistics();
    stats.totalMessagesSynced++;
    stats.lastSyncTime = DateTime.now();
    await updateSyncStatistics(stats);
  }

  /// 同期失敗数をインクリメント
  Future<void> incrementFailedCount() async {
    final stats = await getSyncStatistics();
    stats.failedSyncCount++;
    await updateSyncStatistics(stats);
  }

  /// オフライン送信数をインクリメント
  Future<void> incrementOfflineSentCount() async {
    final stats = await getSyncStatistics();
    stats.totalOfflineSent++;
    await updateSyncStatistics(stats);
  }

  // ============================================================================
  // ストレージクリーンアップ
  // ============================================================================

  /// 古いキャッシュを削除
  Future<void> cleanupExpiredCache() async {
    // 古いユーザー情報を削除
    final users = await getAllCachedUsers();
    for (final user in users) {
      if (user.isExpired) {
        await deleteCachedUser(user.id);
      }
    }

    // 古いメッセージを削除
    final messages = await getAllCachedMessages();
    for (final message in messages) {
      if (message.isExpired) {
        await deleteCachedMessage(message.id);
      }
    }

    // 古いフォロー情報を削除
    final followInfos = await getAllCachedFollowInfo();
    for (final followInfo in followInfos) {
      if (followInfo.isExpired) {
        await deleteCachedFollowInfo(followInfo.userId);
      }
    }
  }

  /// すべてのオフラインデータを削除
  Future<void> clearAllOfflineData() async {
    await clearAllOfflineMessages();
    await clearCachedUsers();
    await clearCachedMessages();
    await clearCachedFollowInfo();
  }

  /// ストレージサイズ情報を取得
  Future<Map<String, int>> getStorageInfo() async {
    final messageCount = (await getAllOfflineMessages()).length;
    final userCount = (await getAllCachedUsers()).length;
    final cachedMessageCount = (await getAllCachedMessages()).length;
    final followCount = (await getAllCachedFollowInfo()).length;

    return {
      'offlineMessages': messageCount,
      'cachedUsers': userCount,
      'cachedMessages': cachedMessageCount,
      'followInfo': followCount,
    };
  }
}
