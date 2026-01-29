// ========================================
// 受信ファイル一覧タブ
// ========================================
// 初学者向け説明：
// このファイルは、他のユーザーから受信した
// ボイスメッセージの一覧を表示するタブです

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants.dart';
import 'voice_playback_screen.dart';

/// 受信ファイル一覧を表示するウィジェット
class ReceivedFilesTab extends StatefulWidget {
  const ReceivedFilesTab({super.key});

  @override
  State<ReceivedFilesTab> createState() => _ReceivedFilesTabState();
}

class _ReceivedFilesTabState extends State<ReceivedFilesTab> {
  // ========================================
  // サンプルデータ（将来的にはサーバーから取得）
  // ========================================
  final List<Map<String, dynamic>> _receivedFiles = [
    {
      'filename': 'voice_001.m4a',
      'sender': '山田太郎',
      'date': '2024/12/22 14:30',
      'duration': '0:15',
      'isNew': true,
    },
    {
      'filename': 'voice_002.m4a',
      'sender': '佐藤花子',
      'date': '2024/12/22 12:15',
      'duration': '0:30',
      'isNew': true,
    },
    {
      'filename': 'voice_003.m4a',
      'sender': '鈴木一郎',
      'date': '2024/12/21 18:45',
      'duration': '0:45',
      'isNew': false,
    },
  ];

  @override
  void dispose() {
    // _audioService.dispose(); // AudioServiceにdisposeがない場合があるため削除
    super.dispose();
  }

  // ========================================
  // 音声を再生画面を開く
  // ========================================
  void _openPlaybackScreen(Map<String, dynamic> file) {
    final filename = file['filename'] as String;
    
    // ファイル名からテーマIDを抽出
    // 例: theme_red_originalName.m4a
    String themeId = 'blue'; // デフォルト
    if (filename.startsWith('theme_')) {
      final parts = filename.split('_');
      if (parts.length >= 2) {
        themeId = parts[1];
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VoicePlaybackScreen(
          voiceUrl: ApiService.getVoiceUrl(filename),
          fileName: file['sender'], // 送信者名を表示
          theme: getThemeById(themeId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('受信メッセージ'),
        actions: [
          // ========================================
          // フィルターボタン（将来の機能）
          // ========================================
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'フィルター',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('フィルター'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CheckboxListTile(
                        title: const Text('未読のみ'),
                        value: false,
                        onChanged: (value) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('フィルター機能は準備中です'),
                            ),
                          );
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('本日の受信'),
                        value: false,
                        onChanged: (value) {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('閉じる'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _receivedFiles.isEmpty
          ? const Center(
              child: Text('まだ受信メッセージがありません'),
            )
          : ListView.builder(
              itemCount: _receivedFiles.length,
              itemBuilder: (context, index) {
                final file = _receivedFiles[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    // ========================================
                    // 送信者のアイコン
                    // ========================================
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            file['sender'][0], // 名前の最初の文字
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // 未読バッジ
                        if (file['isNew'])
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // ========================================
                    // ファイル情報
                    // ========================================
                    title: Row(
                      children: [
                        Text(
                          file['sender'],
                          style: TextStyle(
                            fontWeight:
                                file['isNew'] ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (file['isNew']) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
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
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              file['date'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.timer,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              file['duration'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // ========================================
                    // 再生ボタン（詳細画面へ）
                    // ========================================
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.play_circle_fill,
                            color: Colors.green,
                            size: 32,
                          ),
                          onPressed: () => _openPlaybackScreen(file),
                        ),
                        // メニューボタン
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('削除確認'),
                                  content: const Text('このメッセージを削除しますか？'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('キャンセル'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        setState(() {
                                          _receivedFiles.removeAt(index);
                                        });
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text('削除しました'),
                                          ),
                                        );
                                      },
                                      child: const Text('削除'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'download',
                              child: Row(
                                children: [
                                  Icon(Icons.download),
                                  SizedBox(width: 8),
                                  Text('ダウンロード'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('削除'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
