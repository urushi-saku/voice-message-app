// ========================================
// チャットバブルウィジェット
// ========================================
// ThreadDetailScreen の _buildBubble / _buildTimestamp /
// _buildVoiceBubble / _TailPainter を独立させたファイル

import 'package:flutter/material.dart';
import '../models/message.dart';

// ========================================
// メッセージバブル
// ========================================
/// 1メッセージ分のチャットUI
/// - 自分のメッセージ: 右寄せ・紫グラデーション
/// - 相手のメッセージ: 左寄せ・白背景
/// - 4件ごとのグループ先頭にアバター・しっぽを表示
class MessageBubble extends StatelessWidget {
  final MessageInfo message;

  /// _messages リスト上の「古い順インデックス」(0=最古)
  /// 4件ごとのグループ判定に使用
  final int index;

  /// 送信者の表示名
  final String displayName;

  /// 送信者のプロフィール画像URL（null なら頭文字アバター）
  final String? displayProfileImage;

  /// 長押し時（オプションシートを開く）
  final VoidCallback onLongPress;

  /// アバタータップ時（プロフィール画面を開く）
  final VoidCallback onAvatarTap;

  /// ボイスメッセージのタップ時（再生画面を開く）
  final VoidCallback onPlaybackTap;

  /// ログイン中のユーザーID（リアクション強調表示用）
  final String currentUserId;

  /// リアクションチップタップ時コールバック
  final void Function(String emoji)? onReactionTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.index,
    required this.displayName,
    this.displayProfileImage,
    required this.onLongPress,
    required this.onAvatarTap,
    required this.onPlaybackTap,
    this.currentUserId = '',
    this.onReactionTap,
  });

  // グループ先頭（しっぽ・アバター表示）
  bool get _showTail => index % 4 == 0;
  bool get _isMe => message.isMine;

  // リアクションを絵文字ごとにグループ化
  Map<String, List<MessageReaction>> get _grouped {
    final map = <String, List<MessageReaction>>{};
    for (final r in message.reactions) {
      map.putIfAbsent(r.emoji, () => []).add(r);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final showAvatar = !_isMe && _showTail;
    final grouped = _grouped;
    final hasReactions = grouped.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
              12, _showTail ? 10 : 2, 12, hasReactions ? 0 : 2),
          child: Row(
            mainAxisAlignment: _isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- 相手側アバター ----
              if (!_isMe) ...[
                if (showAvatar)
                  GestureDetector(
                    onTap: onAvatarTap,
                    child: _SenderAvatar(
                      displayName: displayName,
                      displayProfileImage: displayProfileImage,
                    ),
                  )
                else
                  const SizedBox(width: 36),
                const SizedBox(width: 8),
              ],

              // ---- バブル本体 ----
              Flexible(
                child: Row(
                  mainAxisAlignment: _isMe
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_isMe) ...[
                      MessageTimestamp(message: message, isMe: true),
                      const SizedBox(width: 6),
                    ],
                    GestureDetector(
                      onLongPress: onLongPress,
                      child: IntrinsicWidth(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _BubbleContainer(
                              message: message,
                              isMe: _isMe,
                              showTail: _showTail,
                              onPlaybackTap: onPlaybackTap,
                            ),
                            // しっぽ（グループ先頭のみ・上側）
                            if (_showTail)
                              Positioned(
                                top: 0,
                                left: _isMe ? null : -10,
                                right: _isMe ? -10 : null,
                                child: CustomPaint(
                                  size: const Size(10, 10),
                                  painter: TailPainter(
                                    isMe: _isMe,
                                    color: _isMe
                                        ? const Color(0xFF7C4DFF)
                                        : Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (!_isMe) ...[
                      const SizedBox(width: 6),
                      MessageTimestamp(message: message, isMe: false),
                    ],
                  ],
                ),
              ),

              if (_isMe) const SizedBox(width: 4),
            ],
          ),
        ),

        // ---- リアクションチップ ----
        if (hasReactions)
          Padding(
            padding: EdgeInsets.only(
              left: _isMe ? 12 : 56, // 相手側: avatar(36)+gap(8)+padding(12)
              right: 12,
              top: 3,
              bottom: 4,
            ),
            child: Align(
              alignment:
                  _isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: grouped.entries.map((e) {
                  final hasMe =
                      e.value.any((r) => r.userId == currentUserId);
                  return _ReactionChip(
                    emoji: e.key,
                    count: e.value.length,
                    isHighlighted: hasMe,
                    onTap: () => onReactionTap?.call(e.key),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }
}

// ========================================
// 送信者アバター（左側の丸アイコン）
// ========================================
class _SenderAvatar extends StatelessWidget {
  final String displayName;
  final String? displayProfileImage;

  const _SenderAvatar({required this.displayName, this.displayProfileImage});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        backgroundImage: displayProfileImage != null
            ? NetworkImage(displayProfileImage!)
            : null,
        child: displayProfileImage == null
            ? Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }
}

// ========================================
// バブルコンテナ（背景・角丸・影）
// ========================================
class _BubbleContainer extends StatelessWidget {
  final MessageInfo message;
  final bool isMe;
  final bool showTail;
  final VoidCallback onPlaybackTap;

  const _BubbleContainer({
    required this.message,
    required this.isMe,
    required this.showTail,
    required this.onPlaybackTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.65,
      ),
      decoration: isMe ? _myDecoration : _otherDecoration,
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
            : VoiceBubbleContent(
                message: message,
                isMe: isMe,
                onTap: onPlaybackTap,
              ),
      ),
    );
  }

  BoxDecoration get _myDecoration => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF7C4DFF), Color(0xFF512DA8)],
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
        color: Colors.deepPurple.withValues(alpha: 0.35),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  );

  BoxDecoration get _otherDecoration => BoxDecoration(
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
  );
}

// ========================================
// タイムスタンプ＋既読表示
// ========================================
class MessageTimestamp extends StatelessWidget {
  final MessageInfo message;
  final bool isMe;

  const MessageTimestamp({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
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
}

// ========================================
// ボイスメッセージバブルの内容
// ========================================
/// テキストでなくボイスメッセージの場合に表示するウィジェット
/// サムネイル画像・再生ボタン・波形バー・時間表示・未読ドットを含む
class VoiceBubbleContent extends StatelessWidget {
  final MessageInfo message;
  final bool isMe;
  final VoidCallback onTap;

  const VoiceBubbleContent({
    super.key,
    required this.message,
    required this.isMe,
    required this.onTap,
  });

  static const _barHeights = [
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

  @override
  Widget build(BuildContext context) {
    final barColor = isMe
        ? Colors.white.withValues(alpha: 0.9)
        : const Color(0xFF7C4DFF);
    final inactiveColor = isMe
        ? Colors.white.withValues(alpha: 0.35)
        : Colors.grey.shade300;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // サムネイル画像（添付あり時）
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
              // 再生ボタン（丸アイコン）
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
              // 波形バー（静的）
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(_barHeights.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Container(
                      width: 3,
                      height: _barHeights[i],
                      decoration: BoxDecoration(
                        color: i < 5 ? barColor : inactiveColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(width: 8),
              // 録音時間
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
        ],
      ),
    );
  }
}

// ========================================
// リアクションチップ
// ========================================
class _ReactionChip extends StatelessWidget {
  final String emoji;
  final int count;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _ReactionChip({
    required this.emoji,
    required this.count,
    required this.isHighlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isHighlighted
              ? const Color(0xFFEDE7F6)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHighlighted
                ? const Color(0xFF7C4DFF)
                : Colors.grey.shade300,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            if (count > 1) ...[
              const SizedBox(width: 3),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isHighlighted
                      ? const Color(0xFF7C4DFF)
                      : Colors.black54,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ========================================
// 吹き出しのしっぽ（CustomPainter）
// ========================================
class TailPainter extends CustomPainter {
  final bool isMe;
  final Color color;

  const TailPainter({required this.isMe, required this.color});

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
  bool shouldRepaint(TailPainter old) => old.isMe != isMe || old.color != color;
}
