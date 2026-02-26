// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OfflineMessageAdapter extends TypeAdapter<OfflineMessage> {
  @override
  final int typeId = 1;

  @override
  OfflineMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineMessage(
      id: fields[0] as String,
      senderId: fields[1] as String,
      receiverIds: (fields[2] as List).cast<String>(),
      filePath: fields[3] as String,
      duration: fields[4] as int,
      fileSize: fields[5] as int,
      sentAt: fields[6] as DateTime,
      syncStatus: fields[7] as SyncStatus,
      createdAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineMessage obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.senderId)
      ..writeByte(2)
      ..write(obj.receiverIds)
      ..writeByte(3)
      ..write(obj.filePath)
      ..writeByte(4)
      ..write(obj.duration)
      ..writeByte(5)
      ..write(obj.fileSize)
      ..writeByte(6)
      ..write(obj.sentAt)
      ..writeByte(7)
      ..write(obj.syncStatus)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedUserInfoAdapter extends TypeAdapter<CachedUserInfo> {
  @override
  final int typeId = 2;

  @override
  CachedUserInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedUserInfo(
      id: fields[0] as String,
      username: fields[1] as String,
      email: fields[2] as String,
      profileImage: fields[3] as String?,
      bio: fields[4] as String?,
      followersCount: fields[5] as int,
      followingCount: fields[6] as int,
      cachedAt: fields[7] as DateTime,
      isFollowing: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CachedUserInfo obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.profileImage)
      ..writeByte(4)
      ..write(obj.bio)
      ..writeByte(5)
      ..write(obj.followersCount)
      ..writeByte(6)
      ..write(obj.followingCount)
      ..writeByte(7)
      ..write(obj.cachedAt)
      ..writeByte(8)
      ..write(obj.isFollowing);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedUserInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedMessageInfoAdapter extends TypeAdapter<CachedMessageInfo> {
  @override
  final int typeId = 3;

  @override
  CachedMessageInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedMessageInfo(
      id: fields[0] as String,
      senderId: fields[1] as String,
      senderName: fields[2] as String,
      senderProfileImage: fields[3] as String?,
      receiverIds: (fields[4] as List).cast<String>(),
      filePath: fields[5] as String,
      duration: fields[6] as int,
      fileSize: fields[7] as int,
      isRead: fields[8] as bool,
      readAt: fields[9] as DateTime?,
      sentAt: fields[10] as DateTime,
      cachedAt: fields[11] as DateTime,
      isDownloaded: fields[12] as bool,
      // 旧データには存在しないフィールド → null 時はデフォルト値にフォールバック
      messageType: (fields[13] as String?) ?? 'voice',
      textContent: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CachedMessageInfo obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.senderId)
      ..writeByte(2)
      ..write(obj.senderName)
      ..writeByte(3)
      ..write(obj.senderProfileImage)
      ..writeByte(4)
      ..write(obj.receiverIds)
      ..writeByte(5)
      ..write(obj.filePath)
      ..writeByte(6)
      ..write(obj.duration)
      ..writeByte(7)
      ..write(obj.fileSize)
      ..writeByte(8)
      ..write(obj.isRead)
      ..writeByte(9)
      ..write(obj.readAt)
      ..writeByte(10)
      ..write(obj.sentAt)
      ..writeByte(11)
      ..write(obj.cachedAt)
      ..writeByte(12)
      ..write(obj.isDownloaded)
      ..writeByte(13)
      ..write(obj.messageType)
      ..writeByte(14)
      ..write(obj.textContent);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedMessageInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedFollowInfoAdapter extends TypeAdapter<CachedFollowInfo> {
  @override
  final int typeId = 4;

  @override
  CachedFollowInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedFollowInfo(
      userId: fields[0] as String,
      followers: (fields[1] as List).cast<CachedUserInfo>(),
      following: (fields[2] as List).cast<CachedUserInfo>(),
      cachedAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CachedFollowInfo obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.followers)
      ..writeByte(2)
      ..write(obj.following)
      ..writeByte(3)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedFollowInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OfflineConfigAdapter extends TypeAdapter<OfflineConfig> {
  @override
  final int typeId = 6;

  @override
  OfflineConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineConfig(
      autoSyncOnReconnect: fields[0] as bool,
      enableOfflineMode: fields[1] as bool,
      cacheMedia: fields[2] as bool,
      maxCacheAgeDays: fields[3] as int,
      maxOfflineMessageCount: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineConfig obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.autoSyncOnReconnect)
      ..writeByte(1)
      ..write(obj.enableOfflineMode)
      ..writeByte(2)
      ..write(obj.cacheMedia)
      ..writeByte(3)
      ..write(obj.maxCacheAgeDays)
      ..writeByte(4)
      ..write(obj.maxOfflineMessageCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncStatisticsAdapter extends TypeAdapter<SyncStatistics> {
  @override
  final int typeId = 7;

  @override
  SyncStatistics read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncStatistics(
      totalMessagesSynced: fields[0] as int,
      failedSyncCount: fields[1] as int,
      lastSyncTime: fields[2] as DateTime,
      totalOfflineSent: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SyncStatistics obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.totalMessagesSynced)
      ..writeByte(1)
      ..write(obj.failedSyncCount)
      ..writeByte(2)
      ..write(obj.lastSyncTime)
      ..writeByte(3)
      ..write(obj.totalOfflineSent);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncStatisticsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncStatusAdapter extends TypeAdapter<SyncStatus> {
  @override
  final int typeId = 5;

  @override
  SyncStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncStatus.pending;
      case 1:
        return SyncStatus.syncing;
      case 2:
        return SyncStatus.synced;
      case 3:
        return SyncStatus.failed;
      case 4:
        return SyncStatus.retrying;
      default:
        return SyncStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, SyncStatus obj) {
    switch (obj) {
      case SyncStatus.pending:
        writer.writeByte(0);
        break;
      case SyncStatus.syncing:
        writer.writeByte(1);
        break;
      case SyncStatus.synced:
        writer.writeByte(2);
        break;
      case SyncStatus.failed:
        writer.writeByte(3);
        break;
      case SyncStatus.retrying:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
