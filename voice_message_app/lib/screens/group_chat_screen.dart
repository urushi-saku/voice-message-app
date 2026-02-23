// ========================================
// グループチャット画面
// ========================================
// グループ内のメッセージ送受信・メンバー管理を行う画面

import 'package:flutter/material.dart';
import '../models/group.dart';
import '../services/group_service.dart';
import 'group_members_screen.dart';
import 'voice_playback_screen.dart';
import '../models/message.dart';

class GroupChatScreen extends StatefulWidget {
  final GroupInfo group;

  const GroupChatScreen({super.key, required this.group});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  // ========================================
  // 状態変数
  // ========================================
  late GroupInfo _group;
  List<GroupMessageInfo> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _group = widget.group;
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
      final messages = await GroupService.getGroupMessages(_group.id);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
      await GroupService.sendTextMessage(_group.id, text);
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
  // スクロール制御
  // ========================================
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  // ========================================
  // メンバー管理画面を開く
  // ========================================
  void _openMembers() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GroupMembersScreen(group: _group)),
    ).then((_) async {
      // グループ情報を再取得
      try {
        final updated = await GroupService.getGroupById(_group.id);
        if (mounted) setState(() => _group = updated);
      } catch (_) {}
    });
  }

  // ========================================
  // ボイスメッセージ再生
  // ========================================
  void _playVoiceMessage(GroupMessageInfo msg) {
    // GroupMessageInfo を MessageInfo に変換して再生
    final messageInfo = MessageInfo(
      id: msg.id,
      senderId: msg.sender.id,
      senderUsername: msg.sender.username,
      senderProfileImage: msg.sender.profileImage,
      messageType: msg.messageType,
      textContent: msg.textContent,
      isMine: msg.isMine,
      filePath: msg.downloadUrl,
      fileSize: msg.fileSize,
      duration: msg.duration,
      mimeType: msg.mimeType,
      sentAt: msg.sentAt,
      isRead: msg.isRead,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VoicePlaybackScreen(message: messageInfo),
      ),
    );
  }

  // ========================================
  // ビルド
  // ========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ========================================
      // AppBar
      // ========================================
      appBar: AppBar(
        titleSpacing: 0,
        title: GestureDetector(
          onTap: _openMembers,
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.deepPurple.shade300,
                backgroundImage: _group.iconImageUrl != null
                    ? NetworkImage(_group.iconImageUrl!)
                    : null,
                child: _group.iconImageUrl == null
                    ? Text(
                        _group.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _group.name,
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'メンバー ${_group.membersCount}人',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '再読み込み',
            onPressed: _loadMessages,
          ),
          IconButton(
            icon: const Icon(Icons.group),
            tooltip: 'メンバー',
            onPressed: _openMembers,
          ),
        ],
      ),

      // ========================================
      // メッセージ一覧
      // ========================================
      body: Column(
        children: [
          Expanded(
            child: _isLoading
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
                ? const Center(
                    child: Text(
                      'まだメッセージがありません\n最初のメッセージを送ってみましょう！',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // ========================================
          // テキスト入力エリア
          // ========================================
          _buildInputArea(),
        ],
      ),
    );
  }

  // ========================================
  // メッセージバブル
  // ========================================
  Widget _buildMessageBubble(GroupMessageInfo msg) {
    final isMine = msg.isMine;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 相手のアバター
          if (!isMine) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.deepPurple.shade200,
              backgroundImage: msg.sender.profileImageUrl != null
                  ? NetworkImage(msg.sender.profileImageUrl!)
                  : null,
              child: msg.sender.profileImageUrl == null
                  ? Text(
                      msg.sender.username[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 6),
          ],

          // バブル
          Flexible(
            child: Column(
              crossAxisAlignment: isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // 送信者名（相手のみ表示）
                if (!isMine)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(
                      msg.sender.username,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ),

                // バブル本体
                GestureDetector(
                  onTap: msg.messageType == 'voice'
                      ? () => _playVoiceMessage(msg)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                    decoration: BoxDecoration(
                      color: isMine
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMine ? 18 : 4),
                        bottomRight: Radius.circular(isMine ? 4 : 18),
                      ),
                    ),
                    child: msg.messageType == 'voice'
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_circle_filled,
                                color: isMine
                                    ? Colors.white
                                    : theme.colorScheme.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'ボイスメッセージ',
                                    style: TextStyle(
                                      color: isMine
                                          ? Colors.white
                                          : theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (msg.duration != null)
                                    Text(
                                      _formatDuration(msg.duration!),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isMine
                                            ? Colors.white70
                                            : Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          )
                        : Text(
                            msg.textContent ?? '',
                            style: TextStyle(
                              color: isMine
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),

                // 送信時刻
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                  child: Text(
                    _formatTime(msg.sentAt),
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ),
              ],
            ),
          ),

          if (isMine) const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ========================================
  // 入力エリア
  // ========================================
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // テキスト入力
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'メッセージを入力...',
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendText(),
              ),
            ),

            const SizedBox(width: 8),

            // 送信ボタン
            _isSending
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton.filled(
                    onPressed: _sendText,
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // ユーティリティ
  // ========================================
  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'たった今';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24)
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    return '${dt.month}/${dt.day}';
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
