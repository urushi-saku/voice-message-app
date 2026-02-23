// ========================================
// メッセージ状態管理 Provider
// ========================================
// スレッド内メッセージの取得・送信・削除・既読処理を管理する
// 以前は ThreadDetailScreen の State に直書きしていたロジックを分離

import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../services/message_service.dart';

class MessageProvider extends ChangeNotifier {
  // ========================================
  // 状態変数
  // ========================================
  List<MessageInfo> _messages = [];
  bool _isLoading = false;
  String? _error;
  bool _hasMarkedAsRead = false; // 重複既読処理防止フラグ

  // ========================================
  // ゲッター
  // ========================================
  List<MessageInfo> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ========================================
  // メッセージ読み込み（初回・既読処理付き）
  // ========================================
  Future<void> loadMessages(String senderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _messages = await MessageService.getThreadMessages(senderId);
      _isLoading = false;
      notifyListeners();

      // 初回読み込み時のみ未読メッセージを既読化
      if (!_hasMarkedAsRead) {
        _hasMarkedAsRead = true;
        await _markAllAsRead();
        await Future.delayed(const Duration(milliseconds: 500));
        await loadMessagesWithoutMarkingRead(senderId);
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========================================
  // 未読メッセージを既読にする（内部処理）
  // ========================================
  Future<void> _markAllAsRead() async {
    for (final message in _messages) {
      if (!message.isMine && !message.isRead) {
        try {
          await MessageService.markAsRead(message.id);
        } catch (e) {
          debugPrint('既読マーク失敗: ${message.id}, error: $e');
        }
      }
    }
  }

  // ========================================
  // メッセージ再読み込み（既読処理なし）
  // ========================================
  Future<void> loadMessagesWithoutMarkingRead(String senderId) async {
    try {
      _messages = await MessageService.getThreadMessages(senderId);
      notifyListeners();
    } catch (e) {
      debugPrint('メッセージ再読み込みエラー: $e');
    }
  }

  // ========================================
  // テキストメッセージ送信
  // ========================================
  Future<void> sendText(String senderId, String text) async {
    await MessageService.sendTextMessage(
      receiverIds: [senderId],
      textContent: text,
    );
    await loadMessagesWithoutMarkingRead(senderId);
  }

  // ========================================
  // メッセージ削除
  // ========================================
  Future<void> deleteMessage(String messageId, String senderId) async {
    await MessageService.deleteMessage(messageId);
    await loadMessagesWithoutMarkingRead(senderId);
  }

  // ========================================
  // リアクション トグル（追加/削除）
  // ========================================
  Future<void> toggleReaction({
    required String messageId,
    required String emoji,
    required String currentUserId,
  }) async {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;

    final message = _messages[idx];
    final alreadyReacted = message.reactions.any(
      (r) => r.emoji == emoji && r.userId == currentUserId,
    );

    try {
      final updatedReactions = alreadyReacted
          ? await MessageService.removeReaction(
              messageId: messageId,
              emoji: emoji,
            )
          : await MessageService.addReaction(
              messageId: messageId,
              emoji: emoji,
            );

      _messages[idx] = _rebuildWithReactions(message, updatedReactions);
      notifyListeners();
    } catch (e) {
      debugPrint('リアクション操作エラー: $e');
    }
  }

  MessageInfo _rebuildWithReactions(
    MessageInfo msg,
    List<MessageReaction> reactions,
  ) {
    return MessageInfo(
      id: msg.id,
      senderId: msg.senderId,
      senderUsername: msg.senderUsername,
      senderProfileImage: msg.senderProfileImage,
      messageType: msg.messageType,
      textContent: msg.textContent,
      isMine: msg.isMine,
      filePath: msg.filePath,
      fileSize: msg.fileSize,
      duration: msg.duration,
      mimeType: msg.mimeType,
      thumbnailUrl: msg.thumbnailUrl,
      sentAt: msg.sentAt,
      isRead: msg.isRead,
      readAt: msg.readAt,
      reactions: reactions,
    );
  }
}
