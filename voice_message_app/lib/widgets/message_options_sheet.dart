// ========================================
// メッセージオプションボトムシート
// ========================================
// ThreadDetailScreen の _showMessageOptions / _confirmDeleteMessage を分離
// showMessageOptionsSheet() を呼び出すだけで使用可能

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/message.dart';

/// クイックリアクション絵文字リスト
const _kQuickEmojis = ['👍', '❤️', '😂', '😮', '😢', '🔥'];

/// メッセージ長押し時のオプションシートを表示する
///
/// 【パラメータ】
/// - context: BuildContext（Navigator・ScaffoldMessenger 用）
/// - message: 対象メッセージ
/// - currentUserId: ログイン中ユーザーのID（リアクション強調表示用）
/// - onPlayback: 再生ボタンタップ時コールバック
/// - onDelete: 削除確定後に呼ばれる非同期処理（MessageProvider.deleteMessage など）
/// - onReactionTap: 絵文字タップ時コールバック（emoji を渡す）
/// - onDownload: ダウンロードボタンタップ時コールバック（voiceのみ表示）
Future<void> showMessageOptionsSheet({
  required BuildContext context,
  required MessageInfo message,
  required VoidCallback onPlayback,
  required Future<void> Function() onDelete,
  String currentUserId = '',
  void Function(String emoji)? onReactionTap,
  VoidCallback? onDownload,
}) async {
  await showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ---- ハンドルバー ----
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // ---- クイックリアクション行 ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _kQuickEmojis.map((emoji) {
                  final alreadyReacted = message.reactions.any(
                    (r) => r.emoji == emoji && r.userId == currentUserId,
                  );
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      onReactionTap?.call(emoji);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: alreadyReacted
                            ? const Color(0xFFEDE7F6)
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                        border: alreadyReacted
                            ? Border.all(
                                color: const Color(0xFF7C4DFF),
                                width: 1.8,
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            // ---- テキストのみ: コピー ----
            if (message.messageType == 'text' && message.textContent != null)
              ListTile(
                leading: const Icon(
                  Icons.copy_rounded,
                  color: Color(0xFF7C4DFF),
                ),
                title: const Text('コピー'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  Clipboard.setData(ClipboardData(text: message.textContent!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('コピーしました'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            // ---- ボイスのみ: 再生 ----
            if (message.messageType == 'voice')
              ListTile(
                leading: const Icon(
                  Icons.play_circle_outline_rounded,
                  color: Color(0xFF7C4DFF),
                ),
                title: const Text('再生'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  onPlayback();
                },
              ),
            // ---- ボイスのみ: ダウンロード ----
            if (message.messageType == 'voice' && onDownload != null)
              ListTile(
                leading: const Icon(
                  Icons.download_rounded,
                  color: Color(0xFF7C4DFF),
                ),
                title: const Text('ダウンロード'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  onDownload();
                },
              ),
            // ---- 削除 / 送信取り消し ----
            ListTile(
              leading: Icon(
                message.isMine
                    ? Icons.undo_rounded
                    : Icons.delete_outline_rounded,
                color: Colors.red.shade400,
              ),
              title: Text(message.isMine ? '送信取り消し' : '削除'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _showDeleteConfirm(context, message, onDelete);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

/// 削除確認ダイアログを表示し、確定時に [onDelete] を呼び出す
Future<void> _showDeleteConfirm(
  BuildContext context,
  MessageInfo message,
  Future<void> Function() onDelete,
) async {
  final isMe = message.isMine;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(isMe ? '送信取り消し' : 'メッセージを削除'),
      content: Text(
        isMe ? 'このメッセージを取り消しますか？\n相手の画面からも消えます。' : 'このメッセージをあなたの画面から削除しますか？',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('キャンセル'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(isMe ? '取り消す' : '削除'),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    try {
      await onDelete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isMe ? '送信を取り消しました' : 'メッセージを削除しました'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('削除に失敗しました: ${e.toString()}')));
      }
    }
  }
}
