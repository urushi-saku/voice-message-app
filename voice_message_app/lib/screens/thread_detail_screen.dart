// ========================================
// スレッド詳細画面（チャットUI）
// ========================================

import 'package:flutter/material.dart';
import '../services/message_service.dart';
import 'recording_screen.dart';
import 'voice_playback_screen.dart';

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

  // 送信者の表示情報（通知の初期値をAPIで上書きする）
  late String _displayName;
  String? _displayProfileImage;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _displayName = widget.senderUsername;
    _displayProfileImage = widget.senderProfileImage;
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
        builder: (_) => RecordingScreen(
          recipientIds: [widget.senderId],
          recipientUsername: _displayName,
          recipientProfileImage: _displayProfileImage,
        ),
      ),
    ).then((_) => _loadMessages());
  }

  // ========================================
  // チャットバブル構築
  // ========================================
  Widget _buildBubble(MessageInfo message, int index) {
    final isMe = message.isMine;
    // 4件ごとのグループ先頭（index=0,4,8...）にアイコンを表示
    final showAvatar = !isMe && index % 4 == 0;
    // 送受信両方ともグループ先頭にしっぽを表示
    final showTail = index % 4 == 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, showTail ? 10 : 2, 12, 2),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            if (showAvatar)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF7C4DFF),
                  backgroundImage: _displayProfileImage != null
                      ? NetworkImage(_displayProfileImage!)
                      : null,
                  child: _displayProfileImage == null
                      ? Text(
                          _displayName.isNotEmpty
                              ? _displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              )
            else
              const SizedBox(width: 36), // アイコン非表示時のインデント補完
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Row(
              mainAxisAlignment: isMe
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 自分のメッセージ：タイムスタンプ＋既読をバブルの左に
                if (isMe) ...[
                  _buildTimestamp(message, isMe),
                  const SizedBox(width: 6),
                ],
                IntrinsicWidth(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.65,
                        ),
                        decoration: isMe
                            ? BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF7C4DFF),
                                    Color(0xFF512DA8),
                                  ],
                                ),
                                borderRadius: showTail
                                    ? const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.zero,
                                        bottomLeft: Radius.circular(16),
                                        bottomRight: Radius.circular(16),
                                      )
                                    : BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.deepPurple.withOpacity(0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              )
                            : BoxDecoration(
                                color: Colors.white,
                                borderRadius: showTail
                                    ? const BorderRadius.only(
                                        topLeft: Radius.zero,
                                        topRight: Radius.circular(16),
                                        bottomLeft: Radius.circular(16),
                                        bottomRight: Radius.circular(16),
                                      )
                                    : BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.07),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: message.messageType == 'text'
                              ? Text(
                                  message.textContent ?? '',
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black87,
                                    fontSize: 15,
                                    height: 1.4,
                                  ),
                                )
                              : _buildVoiceBubble(message, isMe),
                        ),
                      ),
                      // 吹き出しのしっぽ（グループ先頭のみ・上側）
                      if (showTail)
                        Positioned(
                          top: 0,
                          left: isMe ? null : -10,
                          right: isMe ? -10 : null,
                          child: CustomPaint(
                            size: const Size(10, 10),
                            painter: _TailPainter(
                              isMe: isMe,
                              color: isMe
                                  ? const Color(0xFF7C4DFF)
                                  : Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // 相手のメッセージ：タイムスタンプをバブルの右に
                if (!isMe) ...[
                  const SizedBox(width: 6),
                  _buildTimestamp(message, isMe),
                ],
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildTimestamp(MessageInfo message, bool isMe) {
    final time =
        '${message.sentAt.hour.toString().padLeft(2, '0')}:${message.sentAt.minute.toString().padLeft(2, '0')}';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (isMe && message.isRead)
          Text(
            '既読',
            style: TextStyle(
              fontSize: 10,
              color: Colors.deepPurple.shade300,
              fontWeight: FontWeight.w500,
            ),
          ),
        Text(time, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _buildVoiceBubble(MessageInfo message, bool isMe) {
    const barHeights = [
      10.0,
      18.0,
      14.0,
      22.0,
      16.0,
      20.0,
      12.0,
      18.0,
      24.0,
      14.0,
      18.0,
      10.0,
    ];
    final barColor = isMe
        ? Colors.white.withOpacity(0.9)
        : const Color(0xFF7C4DFF);
    final inactiveColor = isMe
        ? Colors.white.withOpacity(0.35)
        : Colors.grey.shade300;

    return GestureDetector(
      onTap: () => _openPlayback(message),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 再生ボタン
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMe
                  ? Colors.white.withOpacity(0.2)
                  : const Color(0xFF7C4DFF).withOpacity(0.12),
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              color: isMe ? Colors.white : const Color(0xFF7C4DFF),
              size: 22,
            ),
          ),
          const SizedBox(width: 8),
          // 波形バー
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(barHeights.length, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Container(
                  width: 3,
                  height: barHeights[i],
                  decoration: BoxDecoration(
                    color: i < 5 ? barColor : inactiveColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(width: 8),
          // 再生時間
          if (message.duration != null)
            Text(
              '${message.duration}s',
              style: TextStyle(
                fontSize: 12,
                color: isMe ? Colors.white70 : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          // 未読ドット
          if (!message.isRead && !isMe) ...[
            const SizedBox(width: 6),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFFF5252),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
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
        backgroundColor: const Color(0xFFF0F2F5),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7C4DFF), Color(0xFF512DA8)],
              ),
            ),
          ),
          foregroundColor: Colors.white,
          title: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withOpacity(0.3),
                backgroundImage: _displayProfileImage != null
                    ? NetworkImage(_displayProfileImage!)
                    : null,
                child: _displayProfileImage == null
                    ? Text(
                        _displayName.isNotEmpty
                            ? _displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _displayName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
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
                              itemBuilder: (_, i) =>
                                  _buildBubble(_messages[i], i),
                            ),
                    ),
                  ),
                  _buildInputArea(),
                ],
              ),
      ),
    );
  }

  // ========================================
  // 入力エリア
  // ========================================
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // マイクボタン（丸型）
            Material(
              color: const Color(0xFFEDE7F6),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _openRecording,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.mic, color: Color(0xFF7C4DFF), size: 22),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // テキスト入力フィールド
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _textController,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'メッセージを入力',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 送信ボタン（グラデーション丸型）
            _isSending
                ? const SizedBox(
                    width: 42,
                    height: 42,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF7C4DFF),
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: _sendText,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF7C4DFF), Color(0xFF512DA8)],
                        ),
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

/// 吹き出しのしっぽを描画するCustomPainter
class _TailPainter extends CustomPainter {
  final bool isMe;
  final Color color;

  const _TailPainter({required this.isMe, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    if (isMe) {
      // 右上に伸びる（自分のメッセージ）: 右角が先端
      path.moveTo(0, 0); // 左上（バブル右上角に接続）
      path.lineTo(0, size.height); // 左下
      path.lineTo(size.width, 0); // 右上（先端）
    } else {
      // 左上に伸びる（相手のメッセージ）: 左角が先端
      path.moveTo(size.width, 0); // 右上（バブル左上角に接続）
      path.lineTo(size.width, size.height); // 右下
      path.lineTo(0, 0); // 左上（先端）
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TailPainter old) =>
      old.isMe != isMe || old.color != color;
}
