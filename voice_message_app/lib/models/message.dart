// ========================================
// メッセージモデル
// ========================================
// MessageInfo / ThreadInfo を一元管理するモデルファイル
// 以前は message_service.dart に同居していたが、
// モデルとサービスの責務を分離するために独立させた

import '../services/auth_service.dart'; // BASE_URL のみ使用

// ========================================
// リアクション情報
// ========================================
class MessageReaction {
  final String emoji;
  final String userId;
  final String username;

  const MessageReaction({
    required this.emoji,
    required this.userId,
    required this.username,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      emoji: json['emoji'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'emoji': emoji,
    'userId': userId,
    'username': username,
  };
}

// ========================================
// メッセージ情報
// ========================================
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
  final String? thumbnailUrl;
  final DateTime sentAt;
  final bool isRead;
  final DateTime? readAt;
  final List<MessageReaction> reactions;

  // E2EE フィールド
  final bool isEncrypted; // 暗号化されているか
  final String? contentNonce; // Base64: secretbox 用ノンス
  /// 受信者ごとの暗号化済み鍵エントリリスト
  /// 内容: [{userId, encryptedKey, ephemeralPublicKey, keyNonce}]
  final List<Map<String, dynamic>> encryptedKeys;

  const MessageInfo({
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
    this.thumbnailUrl,
    required this.sentAt,
    required this.isRead,
    this.readAt,
    this.reactions = const [],
    this.isEncrypted = false,
    this.contentNonce,
    this.encryptedKeys = const [],
  });

  factory MessageInfo.fromJson(Map<String, dynamic> json) {
    final rawAttached = json['attachedImage'] as String?;
    final thumbnailUrl = rawAttached != null && rawAttached.isNotEmpty
        ? '$BASE_URL/voice/${rawAttached.split('/').last}'
        : null;
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
      thumbnailUrl: thumbnailUrl,
      sentAt: DateTime.parse(json['sentAt']),
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      reactions: (json['reactions'] as List<dynamic>? ?? [])
          .map((r) => MessageReaction.fromJson(r as Map<String, dynamic>))
          .toList(),
      // E2EE フィールド
      isEncrypted: json['isEncrypted'] as bool? ?? false,
      contentNonce: json['contentNonce'] as String?,
      encryptedKeys: (json['encryptedKeys'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .toList(),
    );
  }
}

// ========================================
// スレッド情報（送信者ごとにグループ化されたメッセージ）
// ========================================
class ThreadInfo {
  final String senderId;
  final String senderUsername;
  final String? senderProfileImage;
  final MessageInfo lastMessage;
  final int unreadCount;
  final int totalCount;
  final DateTime lastMessageAt;

  const ThreadInfo({
    required this.senderId,
    required this.senderUsername,
    this.senderProfileImage,
    required this.lastMessage,
    required this.unreadCount,
    required this.totalCount,
    required this.lastMessageAt,
  });

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
