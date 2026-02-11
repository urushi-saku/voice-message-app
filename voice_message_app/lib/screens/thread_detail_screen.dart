// ========================================
// スレッド詳細画面（特定の相手とのメッセージ一覧）
// ========================================
// 特定の送信者からのメッセージを一覧表示し、
// リスト表示とカード表示を切り替えできます

import 'package:flutter/material.dart';
import '../services/message_service.dart';
import 'voice_playback_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

/// スレッド詳細画面
class ThreadDetailScreen extends StatefulWidget {
  final String senderId;
  final String senderUsername;
  final String? senderProfileImage;

  const ThreadDetailScreen({
    super.key,
    required this.senderId,
    required this.senderUsername,
    this.senderProfileImage,
  });

  @override
  State<ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends State<ThreadDetailScreen> {
  // ========================================
  // 状態変数
  // ========================================
  List<MessageInfo> _messages = [];
  bool _isLoading = true;
  String? _error;
  bool _isGridView = false; // false: リスト表示, true: カード表示

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('ja', timeago.JaMessages());
    _loadMessages();
  }

  // ========================================
  // メッセージを読み込み
  // ========================================
  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final messages = await MessageService.getThreadMessages(widget.senderId);

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
  // 音声再生画面を開く
  // ========================================
  void _openPlaybackScreen(MessageInfo message) {
    _markAsRead(message);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VoicePlaybackScreen(message: message),
      ),
    );
  }

  // ========================================
  // メッセージ削除
  // ========================================
  Future<void> _deleteMessage(MessageInfo message) async {
    final confirm = await showDialog<bool>(
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

    if (confirm == true) {
      try {
        await MessageService.deleteMessage(message.id);
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
  // 時間表示をフォーマット
  // ========================================
  String _formatTime(DateTime dateTime) {
    return timeago.format(dateTime, locale: 'ja');
  }

  // ========================================
  // リスト表示
  // ========================================
  Widget _buildListView() {
    return ListView.builder(
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
            leading: CircleAvatar(
              backgroundColor: message.isRead ? Colors.grey : Colors.deepPurple,
              child: Icon(
                message.isRead ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
              ),
            ),
            title: Row(
              children: [
                const Icon(Icons.mic, size: 16),
                const SizedBox(width: 4),
                Text(_formatTime(message.sentAt)),
                if (!message.isRead) ...[
                  const SizedBox(width: 8),
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
              ],
            ),
            subtitle: message.duration != null
                ? Text('長さ: ${message.duration}秒')
                : null,
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
    );
  }

  // ========================================
  // カード表示（グリッド）
  // ========================================
  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];

        return GestureDetector(
          onTap: () => _openPlaybackScreen(message),
          onLongPress: () => _deleteMessage(message),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // ========================================
                // カード背景
                // ========================================
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.deepPurple.shade300,
                        Colors.deepPurple.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                // ========================================
                // カード内容
                // ========================================
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 送信者アイコン
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white,
                        backgroundImage: widget.senderProfileImage != null
                            ? NetworkImage(widget.senderProfileImage!)
                            : null,
                        child: widget.senderProfileImage == null
                            ? Text(
                                widget.senderUsername[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              )
                            : null,
                      ),

                      const Spacer(),

                      // 送信者名
                      Text(
                        widget.senderUsername,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // 日時
                      Text(
                        _formatTime(message.sentAt),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),

                      if (message.duration != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.mic,
                              size: 12,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${message.duration}秒',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // ========================================
                // 未読バッジ
                // ========================================
                if (!message.isRead)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'N',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                // ========================================
                // 再生アイコン（中央）
                // ========================================
                Center(
                  child: Icon(
                    Icons.play_circle_filled,
                    color: Colors.white.withOpacity(0.8),
                    size: 48,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              backgroundImage: widget.senderProfileImage != null
                  ? NetworkImage(widget.senderProfileImage!)
                  : null,
              child: widget.senderProfileImage == null
                  ? Text(
                      widget.senderUsername[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.senderUsername,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // ========================================
          // 表示切り替えボタン
          // ========================================
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            tooltip: _isGridView ? 'リスト表示' : 'カード表示',
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
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
          ? const Center(child: Text('メッセージがありません'))
          : RefreshIndicator(
              onRefresh: _loadMessages,
              child: _isGridView ? _buildGridView() : _buildListView(),
            ),
    );
  }
}
