// ========================================
// スレッド詳細画面（チャットUI）
// ========================================

import 'package:flutter/material.dart';
import '../services/message_service.dart';
import 'recording_screen.dart';
import 'voice_playback_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

/// スレッド詳細画面（チャット形式）
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
  List<MessageInfo> _messages = [];
  bool _isLoading = true;
  String? _error;
  bool _isSending = false;
  bool _hasMarkedAsRead = false; // 既読処理済みフラグ（重複実行防止）

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('ja', timeago.JaMessages());
    _loadMessages();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ========================================
  // メッセージ読み込み
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
      _scrollToBottom();
      
      // 初回読み込み時のみ、未読メッセージを自動で既読にする
      if (!_hasMarkedAsRead) {
        _hasMarkedAsRead = true;
        _markAllAsRead();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ========================================
  // すべての未読メッセージを既読にする
  // ========================================
  Future<void> _markAllAsRead() async {
    // 相手が送ったメッセージのみ対象（isMine == false）
    // かつ未読（isRead == false）のメッセージを既読にする
    for (final message in _messages) {
      if (!message.isMine && !message.isRead) {
        try {
          await MessageService.markAsRead(message.id);
        } catch (e) {
          print('既読マーク失敗: ${message.id}, error: $e');
        }
      }
    }
    // 既読完了後、メッセージリストを再読み込みして画面を更新
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      _loadMessagesWithoutMarkingRead();
    }
  }

  // ========================================
  // メッセージ再読み込み（既読処理なし）
  // ========================================
  Future<void> _loadMessagesWithoutMarkingRead() async {
    try {
      final messages = await MessageService.getThreadMessages(widget.senderId);
      if (mounted) {
        setState(() {
          _messages = messages;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('メッセージ再読み込みエラー: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ========================================
  // テキストメッセージ送信
  // ========================================
  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    setState(() => _isSending = true);
    try {
      await MessageService.sendTextMessage(
        receiverIds: [widget.senderId],
        textContent: text,
      );
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('送信失敗: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ========================================
  // 音声メッセージ再生
  // ========================================
  void _openPlayback(MessageInfo message) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VoicePlaybackScreen(message: message)),
    );
  }

  // ========================================
  // ボイスメッセージ録音
  // ========================================
  void _openRecording() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordingScreen(recipientIds: [widget.senderId]),
      ),
    ).then((_) => _loadMessages());
  }

  // ========================================
  // チャットバブル構築
  // ========================================
  Widget _buildBubble(MessageInfo message) {
    final isMe = message.isMine;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.deepPurple,
              backgroundImage: widget.senderProfileImage != null
                  ? NetworkImage(widget.senderProfileImage!)
                  : null,
              child: widget.senderProfileImage == null
                  ? Text(
                      widget.senderUsername[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.deepPurple : Colors.grey.shade200,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  padding: message.messageType == 'text'
                      ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
                      : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: message.messageType == 'text'
                      ? Text(
                          message.textContent ?? '',
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontSize: 15,
                          ),
                        )
                      : _buildVoiceBubble(message, isMe),
                ),
                const SizedBox(height: 2),
                Text(
                  timeago.format(message.sentAt, locale: 'ja'),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildVoiceBubble(MessageInfo message, bool isMe) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          message.isRead ? Icons.volume_up : Icons.volume_off,
          color: isMe ? Colors.white70 : Colors.deepPurple,
          size: 22,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ボイスメッセージ',
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (message.duration != null)
                Text(
                  '${message.duration}秒',
                  style: TextStyle(
                    fontSize: 12,
                    color: isMe ? Colors.white60 : Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _openPlayback(message),
          child: Icon(
            Icons.play_circle_filled,
            color: isMe ? Colors.white : Colors.deepPurple,
            size: 36,
          ),
        ),
        if (!message.isRead && !isMe) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'NEW',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 画面を戻る時にスレッド一覧を確実に更新するため、true を返す
        // これにより親画面の .then((_) => _loadThreads()) が実行される
        return true;
      },
      child: Scaffold(
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
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadMessages,
                    child: _messages.isEmpty
                        ? const Center(child: Text('まだメッセージはありません'))
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _messages.length,
                            itemBuilder: (_, i) => _buildBubble(_messages[i]),
                          ),
                  ),
                ),
                _buildInputArea(),
              ],
            ),      ),    );
  }

  // ========================================
  // 入力エリア
  // ========================================
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.mic, color: Colors.deepPurple),
              tooltip: 'ボイスメッセージ',
              onPressed: _openRecording,
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'メッセージを入力',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: Colors.deepPurple,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
            ),
            const SizedBox(width: 4),
            _isSending
                ? const SizedBox(
                    width: 40,
                    height: 40,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.send, color: Colors.deepPurple),
                    onPressed: _sendText,
                    tooltip: '送信',
                  ),
          ],
        ),
      ),
    );
  }
}
