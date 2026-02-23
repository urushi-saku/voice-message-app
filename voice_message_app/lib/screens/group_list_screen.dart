// ========================================
// グループ一覧画面
// ========================================
// 自分が参加しているグループの一覧を表示します

import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/group.dart';
import '../services/group_service.dart';
import 'create_group_screen.dart';
import 'group_chat_screen.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  // ========================================
  // 状態変数
  // ========================================
  List<GroupInfo> _groups = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('ja', timeago.JaMessages());
    _loadGroups();
  }

  // ========================================
  // グループ一覧読み込み
  // ========================================
  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final groups = await GroupService.getMyGroups();
      setState(() {
        _groups = groups;
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
  // グループ作成画面を開く
  // ========================================
  Future<void> _openCreateGroup() async {
    final result = await Navigator.push<GroupInfo>(
      context,
      MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
    );
    if (result != null) {
      _loadGroups();
    }
  }

  // ========================================
  // グループチャット画面を開く
  // ========================================
  void _openGroupChat(GroupInfo group) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GroupChatScreen(group: group)),
    ).then((_) => _loadGroups());
  }

  // ========================================
  // 時刻フォーマット
  // ========================================
  String _formatTime(DateTime dateTime) {
    return timeago.format(dateTime, locale: 'ja');
  }

  // ========================================
  // ビルド
  // ========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('グループ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '再読み込み',
            onPressed: _loadGroups,
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
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('エラー: $_error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadGroups,
                    child: const Text('再読み込み'),
                  ),
                ],
              ),
            )
          : _groups.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.group_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'グループがありません',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '右下のボタンからグループを作成しましょう',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadGroups,
              child: ListView.builder(
                itemCount: _groups.length,
                itemBuilder: (context, index) {
                  final group = _groups[index];
                  return _buildGroupTile(group);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateGroup,
        backgroundColor: Colors.deepPurple,
        tooltip: 'グループを作成',
        child: const Icon(Icons.group_add, color: Colors.white),
      ),
    );
  }

  // ========================================
  // グループリストタイル
  // ========================================
  Widget _buildGroupTile(GroupInfo group) {
    final hasUnread = group.unreadCount > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        // グループアイコン
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.deepPurple.shade300,
              backgroundImage: group.iconImageUrl != null
                  ? NetworkImage(group.iconImageUrl!)
                  : null,
              child: group.iconImageUrl == null
                  ? Text(
                      group.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    )
                  : null,
            ),
            // 未読バッジ
            if (hasUnread)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    group.unreadCount > 99
                        ? '99+'
                        : group.unreadCount.toString(),
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

        // グループ名・最新メッセージ
        title: Text(
          group.name,
          style: TextStyle(
            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
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
                  group.lastMessage?.messageType == 'voice'
                      ? Icons.mic
                      : Icons.chat_bubble_outline,
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    group.lastMessage?.preview ?? '${group.membersCount}人のメンバー',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: hasUnread
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            if (group.lastMessage != null)
              Text(
                _formatTime(group.lastMessage!.sentAt),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),

        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openGroupChat(group),
      ),
    );
  }
}
