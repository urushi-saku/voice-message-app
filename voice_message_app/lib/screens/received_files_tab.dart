// ========================================
// 受信ファイル一覧タブ
// ========================================
// 初学者向け説明：
// このファイルは、他のユーザーから受信した
// ボイスメッセージの一覧を表示するタブです

import 'package:flutter/material.dart';
import '../services/message_service.dart';
import 'voice_playback_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

/// 受信ファイル一覧を表示するウィジェット
class ReceivedFilesTab extends StatefulWidget {
  const ReceivedFilesTab({super.key});

  @override
  State<ReceivedFilesTab> createState() => _ReceivedFilesTabState();
}

class _ReceivedFilesTabState extends State<ReceivedFilesTab> {
  // ========================================
  // 状態変数
  // ========================================
  List<MessageInfo> _messages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('ja', timeago.JaMessages());
    _loadMessages();
  }

  // ========================================
  // 受信メッセージを読み込み
  // ========================================
  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final messages = await MessageService.getReceivedMessages();

      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ========================================
  // メッセージを既読にする
  // ========================================
  Future<void> _markAsRead(MessageInfo message) async {
    if (!message.isRead) {
      try {
        await MessageService.markAsRead(message.id);
        // リストを再読み込み
        _loadMessages();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('既読更新エラー: ${e.toString()}')));
        }
      }
    }
  }

  // ========================================
  // メッセージを削除
  // ========================================
  Future<void> _deleteMessage(MessageInfo message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('このメッセージを削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await MessageService.deleteMessage(message.id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('メッセージを削除しました')));
        }
        _loadMessages();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('削除エラー: ${e.toString()}')));
        }
      }
    }
  }

  // ========================================
  // 音声再生画面を開く
  // ========================================
  void _openPlaybackScreen(MessageInfo message) {
    // 既読にする
    _markAsRead(message);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VoicePlaybackScreen(message: message),
      ),
    );
  }

  // ========================================
  // 時間表示をフォーマット
  // ========================================
  String _formatTime(DateTime dateTime) {
    return timeago.format(dateTime, locale: 'ja');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('受信メッセージ'),
        actions: [
          // ========================================
          // 再読み込みボタン
          // ========================================
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '再読み込み',
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('エラー: $_error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadMessages,
                    child: const Text('再読み込み'),
                  ),
                ],
              ),
            )
          : _messages.isEmpty
          ? const Center(child: Text('受信メッセージがありません'))
          : RefreshIndicator(
              onRefresh: _loadMessages,
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];

                  return Dismissible(
                    key: Key(message.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('削除確認'),
                          content: const Text('このメッセージを削除してもよろしいですか？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('キャンセル'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                '削除',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (direction) async {
                      await MessageService.deleteMessage(message.id);
                      _loadMessages();
                    },
                    child: ListTile(
                      // ========================================
                      // 送信者アイコン
                      // ========================================
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.deepPurple,
                            backgroundImage: message.senderProfileImage != null
                                ? NetworkImage(message.senderProfileImage!)
                                : null,
                            child: message.senderProfileImage == null
                                ? Text(
                                    message.senderUsername[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          // 未読バッジ
                          if (!message.isRead)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      // ========================================
                      // 送信者名・日時
                      // ========================================
                      title: Row(
                        children: [
                          Text(
                            message.senderUsername,
                            style: TextStyle(
                              fontWeight: message.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!message.isRead)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_formatTime(message.sentAt)),
                          if (message.duration != null)
                            Text(
                              '長さ: ${message.duration}秒',
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),

                      // ========================================
                      // 再生アイコン
                      // ========================================
                      trailing: IconButton(
                        icon: const Icon(Icons.play_circle_filled),
                        color: Colors.deepPurple,
                        iconSize: 40,
                        onPressed: () => _openPlaybackScreen(message),
                      ),

                      onTap: () => _openPlaybackScreen(message),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
