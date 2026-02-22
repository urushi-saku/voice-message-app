// ========================================
// スレッド詳細画面（チャットUI）
// ========================================

import 'package:flutter/material.dart';
import '../services/message_service.dart';
import '../services/user_service.dart';
import 'recording_screen.dart';
import 'user_profile_screen.dart';
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

class _ThreadDetailScreenState extends State<ThreadDetailScreen>
    with SingleTickerProviderStateMixin {
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

  // ボイスメッセージパネル（右スワイプで表示）
  bool _showVoicePanel = false;
  late AnimationController _panelController;
  late Animation<Offset> _panelSlide;

  @override
  void initState() {
    super.initState();
    _displayName = widget.senderUsername;
    _displayProfileImage = widget.senderProfileImage;
    _loadMessages();

    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _panelSlide = Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _panelController, curve: Curves.easeOutCubic),
        );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _panelController.dispose();
    super.dispose();
  }

  void _openVoicePanel() {
    setState(() => _showVoicePanel = true);
    _panelController.forward();
  }

  void _closeVoicePanel() {
    _panelController.reverse().then((_) {
      if (mounted) setState(() => _showVoicePanel = false);
    });
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
  // 送信者のプロフィール画面を開く
  // ========================================
  void _openSenderProfile() {
    final user = UserInfo(
      id: widget.senderId,
      username: _displayName,
      handle: _displayName,
      email: '',
      profileImage: _displayProfileImage,
      bio: '',
      followersCount: 0,
      followingCount: 0,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserProfileScreen(user: user)),
    );
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
              GestureDetector(
                onTap: () => _openSenderProfile(),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withValues(alpha: 0.3),
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
                ),
              )
            else
              const SizedBox(width: 36),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Row(
              mainAxisAlignment: isMe
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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
                                    color: Colors.deepPurple.withValues(
                                      alpha: 0.35,
                                    ),
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
                                    color: Colors.black.withValues(alpha: 0.07),
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
        ? Colors.white.withValues(alpha: 0.9)
        : const Color(0xFF7C4DFF);
    final inactiveColor = isMe
        ? Colors.white.withValues(alpha: 0.35)
        : Colors.grey.shade300;

    return GestureDetector(
      onTap: () => _openPlayback(message),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.thumbnailUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                message.thumbnailUrl!,
                width: 180,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.2)
                      : const Color(0xFF7C4DFF).withValues(alpha: 0.12),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: isMe ? Colors.white : const Color(0xFF7C4DFF),
                  size: 22,
                ),
              ),
              const SizedBox(width: 8),
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
              if (message.duration != null)
                Text(
                  '${message.duration}s',
                  style: TextStyle(
                    fontSize: 12,
                    color: isMe ? Colors.white70 : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
        backgroundColor: const Color(0xFFF5F7FA),
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
          title: GestureDetector(
            onTap: _openSenderProfile,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
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
          actions: [
            Tooltip(
              message: 'ボイスメッセージ一覧',
              child: IconButton(
                icon: const Icon(Icons.mic_none_rounded, color: Colors.white),
                onPressed: _showVoicePanel ? _closeVoicePanel : _openVoicePanel,
              ),
            ),
          ],
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: (details) {
            final v = details.primaryVelocity ?? 0;
            if (v < -400) _openVoicePanel();
            if (v > 400) _closeVoicePanel();
          },
          child: Stack(
            children: [
              // チャット本体
              _isLoading
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    itemCount: _messages.length,
                                    itemBuilder: (_, i) =>
                                        _buildBubble(_messages[i], i),
                                  ),
                          ),
                        ),
                        _buildInputArea(),
                      ],
                    ),
              // ボイスメッセージパネル（右スワイプで表示）
              if (_showVoicePanel)
                SlideTransition(
                  position: _panelSlide,
                  child: _buildVoicePanel(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================
  // ボイスメッセージ一覧パネル（右スワイプで表示）
  // ========================================
  Widget _buildVoicePanel() {
    final voiceMessages = _messages
        .where((m) => m.messageType != 'text')
        .toList()
        .reversed
        .toList();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF5F0FF),
          borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 24,
              offset: Offset(-6, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // ---- ヘッダー ----
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  children: [
                    const Icon(Icons.mic, color: Color(0xFF7C4DFF), size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'ボイスメッセージ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF512DA8),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Color(0xFF7C4DFF),
                        size: 22,
                      ),
                      onPressed: _closeVoicePanel,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE0D7FF)),
            // ---- グリッド ----
            Expanded(
              child: voiceMessages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mic_none,
                            size: 56,
                            color: Colors.purple.shade200,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'ボイスメッセージはまだありません',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(10, 12, 10, 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 14,
                            childAspectRatio: 3 / 4.8,
                          ),
                      itemCount: voiceMessages.length,
                      itemBuilder: (_, i) => _buildVoiceCard(voiceMessages[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // ボイスメッセージカード（パネル内 3列グリッド）
  // ========================================

  // グラデーション定義
  static const List<List<Color>> _panelGradients = [
    [Color(0xFF667eea), Color(0xFF764ba2)],
    [Color(0xFFf093fb), Color(0xFFf5576c)],
    [Color(0xFF4facfe), Color(0xFF00f2fe)],
    [Color(0xFF43e97b), Color(0xFF38f9d7)],
    [Color(0xFFfa709a), Color(0xFFfee140)],
    [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
  ];
  static const List<Color> _myPanelGradient = [
    Color(0xFF7C4DFF),
    Color(0xFF512DA8),
  ];

  Widget _buildVoiceCard(MessageInfo message) {
    final isMe = message.isMine;
    final displayName = isMe ? 'あなた' : _displayName;
    final displayImage = isMe ? null : _displayProfileImage;

    final List<Color> gradColors = isMe
        ? _myPanelGradient
        : _panelGradients[_displayName.isEmpty
              ? 0
              : _displayName.codeUnitAt(0) % _panelGradients.length];

    final dateStr =
        '${message.sentAt.year}.${message.sentAt.month}.${message.sentAt.day}';

    return GestureDetector(
      onTap: () => _openPlayback(message),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ---- カード本体 ----
          AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // サムネイル or グラデーション
                  if (message.thumbnailUrl != null &&
                      message.thumbnailUrl!.isNotEmpty)
                    Image.network(
                      message.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _panelGradBox(gradColors),
                    )
                  else
                    _panelGradBox(gradColors),

                  // 下部グラデーションオーバーレイ
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.65),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // アバター + ユーザー名（下部）
                  Positioned(
                    bottom: 5,
                    left: 5,
                    right: 5,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 11,
                          backgroundColor: Colors.white,
                          backgroundImage:
                              displayImage != null && displayImage.isNotEmpty
                              ? NetworkImage(displayImage)
                              : null,
                          child: (displayImage == null || displayImage.isEmpty)
                              ? Text(
                                  displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF7C4DFF),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // バッジ（右上）
                  Positioned(
                    top: 5,
                    right: 5,
                    child: !isMe && !message.isRead
                        // 未読「N」バッジ
                        ? Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF6B35),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'N',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : isMe
                        // 送信済みチェック
                        ? Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              message.isRead ? Icons.done_all : Icons.check,
                              size: 11,
                              color: message.isRead
                                  ? const Color(0xFF4CAF50)
                                  : Colors.grey,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
          // ---- 日付 ----
          const SizedBox(height: 3),
          Text(
            dateStr,
            style: const TextStyle(fontSize: 9, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _panelGradBox(List<Color> colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: const Center(
        child: Icon(Icons.mic, size: 32, color: Colors.white54),
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
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
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.transparent),
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
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x407C4DFF),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
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
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, 0);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, 0);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TailPainter old) =>
      old.isMe != isMe || old.color != color;
}
