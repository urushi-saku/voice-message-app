// ========================================
// 受信ファイル一覧タブ
// ========================================
// 初学者向け説明：
// このファイルは、他のユーザーから受信した
// ボイスメッセージの一覧を表示するタブです

import 'package:flutter/material.dart';
import '../services/message_service.dart';
import '../widgets/offline_banner.dart';
import 'voice_playback_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

/// 受信ファイル一覧を表示するウィジェット
class ReceivedFilesTab extends StatefulWidget {
  const ReceivedFilesTab({super.key});

  @override
  State<ReceivedFilesTab> createState() => _ReceivedFilesTabState();
}

class _ReceivedFilesTabState extends State<ReceivedFilesTab> {
  // ========================================
  // 状態変数
  // ========================================
  List<MessageInfo> _messages = [];
  bool _isLoading = true;
  String? _error;

  // 検索・フィルター関連
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool? _readFilter; // null: 全て, true: 既読のみ, false: 未読のみ
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('ja', timeago.JaMessages());
    _loadMessages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ========================================
  // 受信メッセージを読み込み
  // ========================================
  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final messages = await MessageService.getReceivedMessages();

      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ========================================
  // メッセージを検索
  // ========================================
  Future<void> _searchMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final messages = await MessageService.searchMessages(
        searchQuery: _searchController.text.trim(),
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        isRead: _readFilter,
      );

      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ========================================
  // フィルターをリセット
  // ========================================
  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _readFilter = null;
      _dateFrom = null;
      _dateTo = null;
    });
    _loadMessages();
  }

  // ========================================
  // フィルターダイアログを表示
  // ========================================
  Future<void> _showFilterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _FilterDialog(
        initialReadFilter: _readFilter,
        initialDateFrom: _dateFrom,
        initialDateTo: _dateTo,
      ),
    );

    if (result != null) {
      setState(() {
        _readFilter = result['readFilter'];
        _dateFrom = result['dateFrom'];
        _dateTo = result['dateTo'];
      });
      _searchMessages();
    }
  }

  // ========================================
  // メッセージを既読にする
  // ========================================
  Future<void> _markAsRead(MessageInfo message) async {
    if (!message.isRead) {
      try {
        await MessageService.markAsRead(message.id);
        // リストを再読み込み
        _loadMessages();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('既読更新エラー: ${e.toString()}')));
        }
      }
    }
  }

  // ========================================
  // 音声再生画面を開く
  // ========================================
  void _openPlaybackScreen(MessageInfo message) {
    // 既読にする
    _markAsRead(message);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VoicePlaybackScreen(message: message),
      ),
    );
  }

  // ========================================
  // 時間表示をフォーマット
  // ========================================
  String _formatTime(DateTime dateTime) {
    return timeago.format(dateTime, locale: 'ja');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: '送信者名で検索...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _searchMessages(),
              )
            : const Text('受信メッセージ'),
        actions: [
          // ========================================
          // 検索ボタン
          // ========================================
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: '検索実行',
              onPressed: _searchMessages,
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: '検索',
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          // ========================================
          // フィルターボタン
          // ========================================
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color:
                  (_readFilter != null || _dateFrom != null || _dateTo != null)
                  ? Colors.amber
                  : Colors.white,
            ),
            tooltip: 'フィルター',
            onPressed: _showFilterDialog,
          ),
          // ========================================
          // 閉じる/リセットボタン
          // ========================================
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: '閉じる',
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                });
                _resetFilters();
              },
            )
          else
            // ========================================
            // 再読み込みボタン
            // ========================================
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '再読み込み',
              onPressed: _loadMessages,
            ),
        ],
      ),
      body: Column(
        children: [
          // オフラインバナー表示
          const OfflineBanner(),

          // メインコンテンツ
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
                ? const Center(child: Text('受信メッセージがありません'))
                : RefreshIndicator(
                    onRefresh: _loadMessages,
                    child: ListView.builder(
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];

                        return Dismissible(
                          key: Key(message.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('削除確認'),
                                content: const Text('このメッセージを削除してもよろしいですか？'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('キャンセル'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      '削除',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (direction) async {
                            await MessageService.deleteMessage(message.id);
                            _loadMessages();
                          },
                          child: ListTile(
                            // ========================================
                            // 送信者アイコン
                            // ========================================
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.deepPurple,
                                  backgroundImage:
                                      message.senderProfileImage != null
                                      ? NetworkImage(
                                          message.senderProfileImage!,
                                        )
                                      : null,
                                  child: message.senderProfileImage == null
                                      ? Text(
                                          message.senderUsername[0]
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                // 未読バッジ
                                if (!message.isRead)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            // ========================================
                            // 送信者名・日時
                            // ========================================
                            title: Row(
                              children: [
                                Text(
                                  message.senderUsername,
                                  style: TextStyle(
                                    fontWeight: message.isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (!message.isRead)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(8),
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
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_formatTime(message.sentAt)),
                                if (message.duration != null)
                                  Text(
                                    '長さ: ${message.duration}秒',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                              ],
                            ),

                            // ========================================
                            // 再生アイコン
                            // ========================================
                            trailing: IconButton(
                              icon: const Icon(Icons.play_circle_filled),
                              color: Colors.deepPurple,
                              iconSize: 40,
                              onPressed: () => _openPlaybackScreen(message),
                            ),

                            onTap: () => _openPlaybackScreen(message),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ========================================
// フィルターダイアログ
// ========================================
class _FilterDialog extends StatefulWidget {
  final bool? initialReadFilter;
  final DateTime? initialDateFrom;
  final DateTime? initialDateTo;

  const _FilterDialog({
    this.initialReadFilter,
    this.initialDateFrom,
    this.initialDateTo,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late bool? _readFilter;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _readFilter = widget.initialReadFilter;
    _dateFrom = widget.initialDateFrom;
    _dateTo = widget.initialDateTo;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('フィルター'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 既読/未読フィルター
            const Text('既読状態', style: TextStyle(fontWeight: FontWeight.bold)),
            RadioListTile<bool?>(
              title: const Text('全て'),
              value: null,
              groupValue: _readFilter,
              onChanged: (value) {
                setState(() {
                  _readFilter = value;
                });
              },
            ),
            RadioListTile<bool?>(
              title: const Text('未読のみ'),
              value: false,
              groupValue: _readFilter,
              onChanged: (value) {
                setState(() {
                  _readFilter = value;
                });
              },
            ),
            RadioListTile<bool?>(
              title: const Text('既読のみ'),
              value: true,
              groupValue: _readFilter,
              onChanged: (value) {
                setState(() {
                  _readFilter = value;
                });
              },
            ),
            const Divider(),
            // 日付範囲フィルター
            const Text('日付範囲', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              title: Text(
                _dateFrom == null
                    ? '開始日: 未設定'
                    : '開始日: ${_dateFrom!.year}/${_dateFrom!.month}/${_dateFrom!.day}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dateFrom ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _dateFrom = date;
                  });
                }
              },
            ),
            ListTile(
              title: Text(
                _dateTo == null
                    ? '終了日: 未設定'
                    : '終了日: ${_dateTo!.year}/${_dateTo!.month}/${_dateTo!.day}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dateTo ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _dateTo = date;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _readFilter = null;
              _dateFrom = null;
              _dateTo = null;
            });
          },
          child: const Text('リセット'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'readFilter': _readFilter,
              'dateFrom': _dateFrom,
              'dateTo': _dateTo,
            });
          },
          child: const Text('適用'),
        ),
      ],
    );
  }
}
