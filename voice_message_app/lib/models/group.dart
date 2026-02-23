// ========================================
// グループモデル
// ========================================
// グループ情報・メンバー情報のデータクラス定義

import '../services/auth_service.dart'; // BASE_URL のみ使用

// ========================================
// グループメンバー情報
// ========================================
class GroupMember {
  final String id;
  final String username;
  final String handle;
  final String? profileImage;

  const GroupMember({
    required this.id,
    required this.username,
    required this.handle,
    this.profileImage,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['_id']?.toString() ?? '',
      username: json['username'] as String? ?? '',
      handle: json['handle'] as String? ?? '',
      profileImage: json['profileImage']?.toString(),
    );
  }

  String? get profileImageUrl {
    if (profileImage == null || profileImage!.isEmpty) return null;
    // サーバーの相対パスをURLに変換
    if (profileImage!.startsWith('http')) return profileImage;
    return '$BASE_URL/${profileImage!.replaceAll('\\', '/')}';
  }
}

// ========================================
// グループの最新メッセージ（サマリー）
// ========================================
class GroupLastMessage {
  final String messageType; // 'voice' | 'text'
  final String? textContent;
  final String senderUsername;
  final DateTime sentAt;

  const GroupLastMessage({
    required this.messageType,
    this.textContent,
    required this.senderUsername,
    required this.sentAt,
  });

  factory GroupLastMessage.fromJson(Map<String, dynamic> json) {
    return GroupLastMessage(
      messageType: json['messageType'] as String? ?? 'text',
      textContent: json['textContent']?.toString(),
      senderUsername: json['senderUsername'] as String? ?? '不明',
      sentAt: DateTime.parse(json['sentAt'] as String),
    );
  }

  String get preview {
    if (messageType == 'voice') {
      return '$senderUsername: 🎤 ボイスメッセージ';
    }
    return '$senderUsername: ${textContent ?? ''}';
  }
}

// ========================================
// グループ情報
// ========================================
class GroupInfo {
  final String id;
  final String name;
  final String description;
  final String? iconImage;
  final GroupMember admin;
  final List<GroupMember> members;
  final int membersCount;
  final GroupLastMessage? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GroupInfo({
    required this.id,
    required this.name,
    required this.description,
    this.iconImage,
    required this.admin,
    required this.members,
    required this.membersCount,
    this.lastMessage,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroupInfo.fromJson(Map<String, dynamic> json) {
    final membersJson = json['members'] as List<dynamic>? ?? [];
    return GroupInfo(
      id: json['_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      iconImage: json['iconImage']?.toString(),
      admin: GroupMember.fromJson(json['admin'] as Map<String, dynamic>),
      members: membersJson
          .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
          .toList(),
      membersCount: json['membersCount'] as int? ?? membersJson.length,
      lastMessage: json['lastMessage'] != null
          ? GroupLastMessage.fromJson(
              json['lastMessage'] as Map<String, dynamic>,
            )
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  String? get iconImageUrl {
    if (iconImage == null || iconImage!.isEmpty) return null;
    if (iconImage!.startsWith('http')) return iconImage;
    return '$BASE_URL/${iconImage!.replaceAll('\\', '/')}';
  }
}

// ========================================
// グループメッセージ情報
// ========================================
class GroupMessageInfo {
  final String id;
  final GroupMember sender;
  final String messageType; // 'voice' | 'text'
  final String? textContent;
  final String? filePath;
  final int fileSize;
  final int? duration;
  final String mimeType;
  final DateTime sentAt;
  final bool isMine;
  final bool isRead;

  const GroupMessageInfo({
    required this.id,
    required this.sender,
    required this.messageType,
    this.textContent,
    this.filePath,
    required this.fileSize,
    this.duration,
    required this.mimeType,
    required this.sentAt,
    required this.isMine,
    required this.isRead,
  });

  factory GroupMessageInfo.fromJson(Map<String, dynamic> json) {
    return GroupMessageInfo(
      id: json['_id']?.toString() ?? '',
      sender: GroupMember.fromJson(json['sender'] as Map<String, dynamic>),
      messageType: json['messageType'] as String? ?? 'text',
      textContent: json['textContent']?.toString(),
      filePath: json['filePath']?.toString(),
      fileSize: json['fileSize'] as int? ?? 0,
      duration: json['duration'] as int?,
      mimeType: json['mimeType'] as String? ?? 'audio/m4a',
      sentAt: DateTime.parse(json['sentAt'] as String),
      isMine: json['isMine'] as bool? ?? false,
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  String get downloadUrl {
    if (filePath == null) return '';
    final filename = filePath!.replaceAll('\\', '/').split('/').last;
    return '$BASE_URL/voice/$filename';
  }
}
