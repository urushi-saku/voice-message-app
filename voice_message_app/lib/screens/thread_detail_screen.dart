// ========================================
// スレッド詳細画面（チャットUI）
// ========================================
// 【責務】
// - AppBar・入力エリア・メッセージリストの表示
// - スクロール・スライドパネルのアニメーション制御
// - ナビゲーション（録音画面・再生画面・プロフィール画面）
//
// 【委譲先】
// - MessageProvider    : メッセージ取得・送信・削除・既読処理
// - MessageBubble      : チャットバブルUI
// - VoiceMessagesPanel : ボイスメッセージ一覧パネル
// - showMessageOptionsSheet : 長押しオプションシート

import 'package:flutter/material.dart';
import '../models/message.dart';
import '../providers/message_provider.dart';
import '../services/user_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_options_sheet.dart';
import '../widgets/voice_messages_panel.dart';
import 'recording_screen.dart';
import 'user_profile_screen.dart';
import 'voice_playback_screen.dart';

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
  // ========================================
  // ビジネスロジック（Provider）
  // ========================================
  late final MessageProvider _messageProvider;

  // ========================================
  // UI 専用ステート
  // ========================================
  late String _displayName;
  String? _displayProfileImage;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  // ボイスメッセージパネル（右スワイプで表示）
  bool _showVoicePanel = false;
  late AnimationController _panelController;
  late Animation<Offset> _panelSlide;

  // ========================================
  // ライフサイクル
  // ========================================
  @override
  void initState() {
    super.initState();
    _displayName = widget.senderUsername;
    _displayProfileImage = widget.senderProfileImage;

    // MessageProvider を生成し、変更時に UI を更新
    _messageProvider = MessageProvider();
    _messageProvider.addListener(_onMessagesChanged);
    _messageProvider.loadMessages(widget.senderId);

    // パネルアニメーション初期化
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _panelSlide = Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _panelController, curve: Curves.easeOutCubic),
        );
  }

  void _onMessagesChanged() {
    if (mounted) {
      setState(() {});
      // 初回ロード完了直後に最下部へスクロール
      if (!_messageProvider.isLoading && _messageProvider.error == null) {
        _scrollToBottom();
      }
    }
  }

  @override
  void dispose() {
    _messageProvider.removeListener(_onMessagesChanged);
    _messageProvider.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _panelController.dispose();
    super.dispose();
  }

  // ========================================
  // パネル開閉
  // ========================================
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
  // スクロール制御
  // ========================================
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
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
      await _messageProvider.sendText(widget.senderId, text);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('送信失敗: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ========================================
  // ナビゲーション
  // ========================================
  void _openPlayback(MessageInfo message) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VoicePlaybackScreen(message: message)),
    );
  }

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
    ).then((_) => _messageProvider.loadMessages(widget.senderId));
  }

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
  // ビルド
  // ========================================
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: _buildAppBar(),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: (details) {
            final v = details.primaryVelocity ?? 0;
            if (v < -400) _openVoicePanel();
            if (v > 400) _closeVoicePanel();
          },
          child: Stack(
            children: [
              _buildChatBody(),
              if (_showVoicePanel)
                SlideTransition(
                  position: _panelSlide,
                  child: VoiceMessagesPanel(
                    messages: _messageProvider.messages,
                    displayName: _displayName,
                    displayProfileImage: _displayProfileImage,
                    onClose: _closeVoicePanel,
                    onPlayback: _openPlayback,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================
  // AppBar
  // ========================================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
    );
  }

  // ========================================
  // チャット本体
  // ========================================
  Widget _buildChatBody() {
    if (_messageProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_messageProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('エラー: ${_messageProvider.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _messageProvider.loadMessages(widget.senderId),
              child: const Text('再読み込み'),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        Expanded(child: _buildMessageList()),
        _buildInputArea(),
      ],
    );
  }

  // ========================================
  // メッセージリスト
  // ========================================
  Widget _buildMessageList() {
    final messages = _messageProvider.messages;
    return RefreshIndicator(
      onRefresh: () => _messageProvider.loadMessages(widget.senderId),
      child: messages.isEmpty
          ? const Center(child: Text('まだメッセージはありません'))
          : ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final idx = messages.length - 1 - i;
                final message = messages[idx];
                return MessageBubble(
                  message: message,
                  index: idx,
                  displayName: _displayName,
                  displayProfileImage: _displayProfileImage,
                  onLongPress: () => showMessageOptionsSheet(
                    context: context,
                    message: message,
                    onPlayback: () => _openPlayback(message),
                    onDelete: () => _messageProvider.deleteMessage(
                      message.id,
                      widget.senderId,
                    ),
                  ),
                  onAvatarTap: _openSenderProfile,
                  onPlaybackTap: () => _openPlayback(message),
                );
              },
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
            // マイクボタン
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
            // 送信ボタン
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
