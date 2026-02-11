// ============================================================================
// オフラインモード用データモデル
// ============================================================================
// 目的：オンライン/オフラインに関わらずアプリを使用可能にするための
//       ローカルストレージに保存するデータ構造を定義します

import 'package:hive/hive.dart';

part 'offline_model.g.dart';

// ============================================================================
// 1. オフラインメッセージモデル
// ============================================================================
/// アプリがオフライン状態で送信しようとしたメッセージを一時保存
/// インターネット接続が復活したら自動的にサーバーに送信
@HiveType(typeId: 1)
class OfflineMessage extends HiveObject {
  @HiveField(0)
  late String id; // ローカルID（一時的）

  @HiveField(1)
  late String senderId; // 送信者ID

  @HiveField(2)
  late List<String> receiverIds; // 受信者IDリスト

  @HiveField(3)
  late String filePath; // ローカルファイルパス

  @HiveField(4)
  late int duration; // 音声の長さ（秒）

  @HiveField(5)
  late int fileSize; // ファイルサイズ（バイト）

  @HiveField(6)
  late DateTime sentAt; // 送信日時

  @HiveField(7)
  late SyncStatus syncStatus; // 同期状態

  @HiveField(8)
  late DateTime createdAt; // ローカル保存日時

  OfflineMessage({
    required this.id,
    required this.senderId,
    required this.receiverIds,
    required this.filePath,
    required this.duration,
    required this.fileSize,
    required this.sentAt,
    this.syncStatus = SyncStatus.pending,
    required this.createdAt,
  });

  /// サーバー同期済みかチェック
  bool get isSynced => syncStatus == SyncStatus.synced;

  /// 同期エラーかチェック
  bool get hasSyncError => syncStatus == SyncStatus.failed;
}

// ============================================================================
// 2. オフラインユーザー情報モデル
// ============================================================================
/// ユーザー情報をローカルにキャッシュ
/// オフライン時も過去に取得したユーザー情報を表示可能にします
@HiveType(typeId: 2)
class CachedUserInfo extends HiveObject {
  @HiveField(0)
  late String id; // ユーザーID

  @HiveField(1)
  late String username; // ユーザー名

  @HiveField(2)
  late String email; // メールアドレス

  @HiveField(3)
  late String? profileImage; // プロフィール画像URL

  @HiveField(4)
  late String? bio; // 自己紹介

  @HiveField(5)
  late int followersCount; // フォロワー数

  @HiveField(6)
  late int followingCount; // フォロー中の数

  @HiveField(7)
  late DateTime cachedAt; // キャッシュ取得日時

  @HiveField(8)
  late bool isFollowing; // 自分がこのユーザーをフォロー中か

  CachedUserInfo({
    required this.id,
    required this.username,
    required this.email,
    this.profileImage,
    this.bio,
    required this.followersCount,
    required this.followingCount,
    required this.cachedAt,
    required this.isFollowing,
  });

  /// キャッシュが古いかチェック（24時間以上前）
  bool get isExpired => DateTime.now().difference(cachedAt).inHours > 24;
}

// ============================================================================
// 3. キャッシュされたメッセージ情報
// ============================================================================
/// 受信メッセージをローカルにキャッシュ
/// オフライン時も過去のメッセージを閲覧可能にします
@HiveType(typeId: 3)
class CachedMessageInfo extends HiveObject {
  @HiveField(0)
  late String id; // メッセージID

  @HiveField(1)
  late String senderId; // 送信者ID

  @HiveField(2)
  late String senderName; // 送信者名

  @HiveField(3)
  late String? senderProfileImage; // 送信者プロフィール画像

  @HiveField(4)
  late List<String> receiverIds; // 受信者ID一覧

  @HiveField(5)
  late String filePath; // ローカルファイルパス（ダウンロード済みの場合）

  @HiveField(6)
  late int duration; // 音声の長さ（秒）

  @HiveField(7)
  late int fileSize; // ファイルサイズ（バイト）

  @HiveField(8)
  late bool isRead; // 既読フラグ

  @HiveField(9)
  late DateTime? readAt; // 既読日時

  @HiveField(10)
  late DateTime sentAt; // 送信日時

  @HiveField(11)
  late DateTime cachedAt; // キャッシュ取得日時

  @HiveField(12)
  late bool isDownloaded; // ファイルがダウンロード済みか

  CachedMessageInfo({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderProfileImage,
    required this.receiverIds,
    required this.filePath,
    required this.duration,
    required this.fileSize,
    required this.isRead,
    this.readAt,
    required this.sentAt,
    required this.cachedAt,
    required this.isDownloaded,
  });

  /// キャッシュが古いかチェック（7日以上前）
  bool get isExpired => DateTime.now().difference(cachedAt).inDays > 7;
}

// ============================================================================
// 4. フォロー情報キャッシュ
// ============================================================================
/// フォロー情報をローカルにキャッシュ
@HiveType(typeId: 4)
class CachedFollowInfo extends HiveObject {
  @HiveField(0)
  late String userId; // ユーザーID

  @HiveField(1)
  late List<CachedUserInfo> followers; // フォロワーリスト

  @HiveField(2)
  late List<CachedUserInfo> following; // フォロー中のリスト

  @HiveField(3)
  late DateTime cachedAt; // キャッシュ取得日時

  CachedFollowInfo({
    required this.userId,
    required this.followers,
    required this.following,
    required this.cachedAt,
  });

  /// キャッシュが古いかチェック（12時間以上前）
  bool get isExpired => DateTime.now().difference(cachedAt).inHours > 12;
}

// ============================================================================
// 5. 同期状態列挙型
// ============================================================================
/// オフラインメッセージの同期状態を管理
@HiveType(typeId: 5)
enum SyncStatus {
  @HiveField(0)
  pending, // 待機中（未同期）

  @HiveField(1)
  syncing, // 同期中

  @HiveField(2)
  synced, // 同期完了

  @HiveField(3)
  failed, // 同期失敗

  @HiveField(4)
  retrying, // リトライ中
}

// ============================================================================
// 6. オフラインモード設定
// ============================================================================
/// オフラインモードの動作設定
@HiveType(typeId: 6)
class OfflineConfig extends HiveObject {
  @HiveField(0)
  late bool autoSyncOnReconnect; // 接続復帰時に自動同期するか

  @HiveField(1)
  late bool enableOfflineMode; // オフラインモードを有効にするか

  @HiveField(2)
  late bool cacheMedia; // メディアファイルをキャッシュするか

  @HiveField(3)
  late int maxCacheAgeDays; // キャッシュの最大保持日数

  @HiveField(4)
  late int maxOfflineMessageCount; // 保存するオフラインメッセージの最大数

  OfflineConfig({
    this.autoSyncOnReconnect = true,
    this.enableOfflineMode = true,
    this.cacheMedia = true,
    this.maxCacheAgeDays = 30,
    this.maxOfflineMessageCount = 100,
  });
}

// ============================================================================
// 7. 同期統計情報
// ============================================================================
/// データ同期に関する統計情報
@HiveType(typeId: 7)
class SyncStatistics extends HiveObject {
  @HiveField(0)
  late int totalMessagesSynced; // 同期済みメッセージ総数

  @HiveField(1)
  late int failedSyncCount; // 同期失敗数

  @HiveField(2)
  late DateTime lastSyncTime; // 最後の同期時刻

  @HiveField(3)
  late int totalOfflineSent; // オフラインで送信しようとした数

  SyncStatistics({
    this.totalMessagesSynced = 0,
    this.failedSyncCount = 0,
    required this.lastSyncTime,
    this.totalOfflineSent = 0,
  });

  /// 同期成功率を計算（0.0～1.0）
  double get successRate {
    if (totalOfflineSent == 0) return 1.0;
    return (totalOfflineSent - failedSyncCount) / totalOfflineSent;
  }
}
