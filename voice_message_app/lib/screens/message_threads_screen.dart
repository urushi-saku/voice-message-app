// ========================================
// メッセージスレッド一覧画面
// ========================================
// 送信者ごとにグループ化されたメッセージの一覧を表示します

import 'package:flutter/material.dart';
import '../services/message_service.dart';
import 'select_follower_screen.dart';
import 'thread_detail_screen.dart';
import 'followers_tab.dart';
import 'package:timeago/timeago.dart' as timeago;

/// メッセージスレッド一覧画面
class MessageThreadsScreen extends StatefulWidget {
  const MessageThreadsScreen({super.key});

  @override
  State<MessageThreadsScreen> createState() => _MessageThreadsScreenState();
}

class _MessageThreadsScreenState extends State<MessageThreadsScreen> {
  // ========================================
  // 状態変数
  // ========================================
  List<ThreadInfo> _threads = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('ja', timeago.JaMessages());
    _loadThreads();
  }

  // ========================================
  // スレッド一覧を読み込み
  // ========================================
  Future<void> _loadThreads() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final threads = await MessageService.getMessageThreads();

      setState(() {
        _threads = threads;
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
  // 時間表示をフォーマット
  // ========================================
  String _formatTime(DateTime dateTime) {
    return timeago.format(dateTime, locale: 'ja');
  }

  // ========================================
  // スレッド詳細画面を開く
  // ========================================
  void _openThreadDetail(ThreadInfo thread) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ThreadDetailScreen(
          senderId: thread.senderId,
          senderUsername: thread.senderUsername,
          senderProfileImage: thread.senderProfileImage,
        ),
      ),
    ).then((_) {
      // 戻ってきたら更新
      _loadThreads();
    });
  }

  // ========================================
  // ユーザー検索画面を開く
  // ========================================
  void _openUserSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserSearchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('メッセージ'),
        actions: [
          // ========================================
          // ユーザー検索ボタン
          // ========================================
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'ユーザー検索',
            onPressed: _openUserSearch,
          ),
          // ========================================
          // 再読み込みボタン
          // ========================================
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '再読み込み',
            onPressed: _loadThreads,
          ),
        ],
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
                    onPressed: _loadThreads,
                    child: const Text('再読み込み'),
                  ),
                ],
              ),
            )
          : _threads.isEmpty
          ? const Center(child: Text('メッセージがありません'))
          : RefreshIndicator(
              onRefresh: _loadThreads,
              child: ListView.builder(
                itemCount: _threads.length,
                itemBuilder: (context, index) {
                  final thread = _threads[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListTile(
                      // ========================================
                      // 送信者アイコン
                      // ========================================
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.deepPurple,
                            backgroundImage: thread.senderProfileImage != null
                                ? NetworkImage(thread.senderProfileImage!)
                                : null,
                            child: thread.senderProfileImage == null
                                ? Text(
                                    thread.senderUsername[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  )
                                : null,
                          ),
                          // 未読バッジ
                          if (thread.unreadCount > 0)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Text(
                                  thread.unreadCount > 99
                                      ? '99+'
                                      : thread.unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),

                      // ========================================
                      // 送信者名・メッセージ情報
                      // ========================================
                      title: Text(
                        thread.senderUsername,
                        style: TextStyle(
                          fontWeight: thread.unreadCount > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                thread.lastMessage.messageType == 'text'
                                    ? Icons.chat_bubble_outline
                                    : Icons.mic,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  thread.lastMessage.messageType == 'text'
                                      ? (thread.lastMessage.textContent ?? '')
                                      : 'ボイスメッセージ (${thread.totalCount}件)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: thread.unreadCount > 0
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTime(thread.lastMessageAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),

                      // ========================================
                      // 矢印アイコン
                      // ========================================
                      trailing: const Icon(Icons.chevron_right),

                      onTap: () => _openThreadDetail(thread),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SelectFollowerScreen()),
        ).then((_) => _loadThreads()),
        backgroundColor: Colors.deepPurple,
        tooltip: 'メッセージを送る',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
