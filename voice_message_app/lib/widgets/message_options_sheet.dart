// ========================================
// メッセージオプションボトムシート
// ========================================
// ThreadDetailScreen の _showMessageOptions / _confirmDeleteMessage を分離
// showMessageOptionsSheet() を呼び出すだけで使用可能

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/message.dart';

/// メッセージ長押し時のオプションシートを表示する
///
/// 【パラメータ】
/// - context: BuildContext（Navigator・ScaffoldMessenger 用）
/// - message: 対象メッセージ
/// - onPlayback: 再生ボタンタップ時コールバック
/// - onDelete: 削除確定後に呼ばれる非同期処理（MessageProvider.deleteMessage など）
Future<void> showMessageOptionsSheet({
  required BuildContext context,
  required MessageInfo message,
  required VoidCallback onPlayback,
  required Future<void> Function() onDelete,
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
