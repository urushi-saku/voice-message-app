// ========================================
// ボイスメッセージパネル（右スワイプで表示）
// ========================================
// ThreadDetailScreen の _buildVoicePanel / _buildVoiceCard を分離した Widget

import 'package:flutter/material.dart';
import '../models/message.dart';

// ========================================
// ボイスメッセージ一覧パネル
// ========================================
/// 右スワイプで表示されるボイスメッセージのグリッドパネル
class VoiceMessagesPanel extends StatelessWidget {
  /// スレッド内の全メッセージ（テキスト含む）
  final List<MessageInfo> messages;

  /// 送信者の表示名
  final String displayName;

  /// 送信者のプロフィール画像URL
  final String? displayProfileImage;

  /// 閉じるボタンタップ時コールバック
  final VoidCallback onClose;

  /// カードタップ時（再生画面を開く）コールバック
  final void Function(MessageInfo) onPlayback;

  const VoiceMessagesPanel({
    super.key,
    required this.messages,
    required this.displayName,
    this.displayProfileImage,
    required this.onClose,
    required this.onPlayback,
  });

  // ボイスメッセージのみ抽出（日付の新しい順）
  List<MessageInfo> get _voiceMessages =>
      messages.where((m) => m.messageType != 'text').toList().reversed.toList();

  @override
  Widget build(BuildContext context) {
    final voiceMessages = _voiceMessages;

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
            _PanelHeader(onClose: onClose),
            const Divider(height: 1, color: Color(0xFFE0D7FF)),
            Expanded(
              child: voiceMessages.isEmpty
                  ? _EmptyState()
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
                      itemBuilder: (_, i) => VoiceMessageCard(
                        message: voiceMessages[i],
                        displayName: displayName,
                        displayProfileImage: displayProfileImage,
                        onTap: () => onPlayback(voiceMessages[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- ヘッダー ----
class _PanelHeader extends StatelessWidget {
  final VoidCallback onClose;
  const _PanelHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
              icon: const Icon(Icons.close, color: Color(0xFF7C4DFF), size: 22),
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}

// ---- 空状態 ----
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mic_none, size: 56, color: Colors.purple.shade200),
          const SizedBox(height: 12),
          Text(
            'ボイスメッセージはまだありません',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ========================================
// ボイスメッセージカード（グリッド内 1枚）
// ========================================
class VoiceMessageCard extends StatelessWidget {
  final MessageInfo message;
  final String displayName;
  final String? displayProfileImage;
  final VoidCallback onTap;

  const VoiceMessageCard({
    super.key,
    required this.message,
    required this.displayName,
    this.displayProfileImage,
    required this.onTap,
  });

  // グラデーション定義
  static const List<List<Color>> _gradients = [
    [Color(0xFF667eea), Color(0xFF764ba2)],
    [Color(0xFFf093fb), Color(0xFFf5576c)],
    [Color(0xFF4facfe), Color(0xFF00f2fe)],
    [Color(0xFF43e97b), Color(0xFF38f9d7)],
    [Color(0xFFfa709a), Color(0xFFfee140)],
    [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
  ];
  static const List<Color> _myGradient = [Color(0xFF7C4DFF), Color(0xFF512DA8)];

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMine;
    final name = isMe ? 'あなた' : displayName;
    final image = isMe ? null : displayProfileImage;
    final gradColors = isMe
        ? _myGradient
        : _gradients[displayName.isEmpty
              ? 0
              : displayName.codeUnitAt(0) % _gradients.length];
    final dateStr =
        '${message.sentAt.year}.${message.sentAt.month}.${message.sentAt.day}';

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // サムネイル or グラデーション背景
                  if (message.thumbnailUrl != null &&
                      message.thumbnailUrl!.isNotEmpty)
                    Image.network(
                      message.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _GradBox(gradColors),
                    )
                  else
                    _GradBox(gradColors),

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

                  // アバター + ユーザー名（下部左）
                  Positioned(
                    bottom: 5,
                    left: 5,
                    right: 5,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 11,
                          backgroundColor: Colors.white,
                          backgroundImage: image != null && image.isNotEmpty
                              ? NetworkImage(image)
                              : null,
                          child: (image == null || image.isEmpty)
                              ? Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
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
                            name,
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

                  // 右上バッジ（未読 N / 既読チェック）
                  Positioned(
                    top: 5,
                    right: 5,
                    child: _Badge(message: message, isMe: isMe),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            dateStr,
            style: const TextStyle(fontSize: 9, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ---- グラデーション背景ボックス ----
class _GradBox extends StatelessWidget {
  final List<Color> colors;
  const _GradBox(this.colors);

  @override
  Widget build(BuildContext context) {
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
}

// ---- バッジ（未読 N / 既読チェック） ----
class _Badge extends StatelessWidget {
  final MessageInfo message;
  final bool isMe;

  const _Badge({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    if (!isMe && !message.isRead) {
      // 未読バッジ
      return Container(
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
      );
    }
    if (isMe) {
      // 送信済みチェック
      return Container(
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
          color: message.isRead ? const Color(0xFF4CAF50) : Colors.grey,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
