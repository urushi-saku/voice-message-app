// ========================================
// グループメンバー管理画面
// ========================================
// メンバー一覧の表示・メンバーの追加・削除・退出を行う画面

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/group.dart';
import '../providers/auth_provider.dart';
import '../services/group_service.dart';
import '../services/user_service.dart';

class GroupMembersScreen extends StatefulWidget {
  final GroupInfo group;

  const GroupMembersScreen({super.key, required this.group});

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  late GroupInfo _group;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
  }

  // ========================================
  // グループ情報を再取得
  // ========================================
  Future<void> _refreshGroup() async {
    setState(() => _isLoading = true);
    try {
      final updated = await GroupService.getGroupById(_group.id);
      if (mounted) {
        setState(() {
          _group = updated;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ========================================
  // メンバー削除（管理者操作）
  // ========================================
  Future<void> _removeMember(GroupMember member, String currentUserId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メンバーを削除'),
        content: Text('${member.username} をグループから削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await GroupService.removeMember(_group.id, member.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${member.username} を削除しました')));
        _refreshGroup();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラー: ${e.toString()}')));
      }
    }
  }

  // ========================================
  // グループから退出（自分が退出）
  // ========================================
  Future<void> _leaveGroup(String currentUserId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('グループから退出'),
        content: const Text('このグループから退出しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('退出'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await GroupService.removeMember(_group.id, currentUserId);
      if (mounted) {
        // チャット画面まで戻る（グループ一覧に遷移）
        Navigator.of(context)
          ..pop() // members screen
          ..pop(); // chat screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラー: ${e.toString()}')));
      }
    }
  }

  // ========================================
  // グループ削除（管理者操作）
  // ========================================
  Future<void> _deleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('グループを削除'),
        content: const Text('グループとすべてのメッセージを削除します。この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await GroupService.deleteGroup(_group.id);
      if (mounted) {
        Navigator.of(context)
          ..pop() // members screen
          ..pop(); // chat screen -> group list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラー: ${e.toString()}')));
      }
    }
  }

  // ========================================
  // メンバー追加（ユーザー検索ダイアログ）
  // ========================================
  Future<void> _showAddMemberDialog() async {
    final searchController = TextEditingController();
    List<UserInfo> results = [];
    bool isSearching = false;
    // 外側の ScaffoldMessenger をあらかじめ取得しておく
    final messenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> search(String kw) async {
            if (kw.isEmpty) {
              setDialogState(() => results = []);
              return;
            }
            setDialogState(() => isSearching = true);
            try {
              final users = await UserService.searchUsers(kw);
              // すでにメンバーの人を除外
              setDialogState(() {
                results = users
                    .where((u) => !_group.members.any((m) => m.id == u.id))
                    .toList();
                isSearching = false;
              });
            } catch (_) {
              setDialogState(() => isSearching = false);
            }
          }

          return AlertDialog(
            title: const Text('メンバーを追加'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'ユーザー名で検索',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: search,
                  ),
                  const SizedBox(height: 8),
                  if (isSearching)
                    const CircularProgressIndicator()
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: results.length,
                        itemBuilder: (_, i) {
                          final u = results[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.deepPurple,
                              backgroundImage: u.profileImage != null
                                  ? NetworkImage(u.profileImage!)
                                  : null,
                              child: u.profileImage == null
                                  ? Text(
                                      u.username[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                            title: Text(u.username),
                            subtitle: Text('@${u.handle}'),
                            trailing: const Icon(Icons.add),
                            onTap: () async {
                              Navigator.pop(context);
                              try {
                                await GroupService.addMember(_group.id, u.id);
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('${u.username} を追加しました'),
                                    ),
                                  );
                                  _refreshGroup();
                                }
                              } catch (e) {
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('エラー: ${e.toString()}'),
                                    ),
                                  );
                                }
                              }
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('閉じる'),
              ),
            ],
          );
        },
      ),
    );

    searchController.dispose();
  }

  // ========================================
  // ビルド
  // ========================================
  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().user?.id ?? '';
    final isAdmin = _group.admin.id == currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_group.name} のメンバー'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'メンバーを追加',
              onPressed: _showAddMemberDialog,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ========================================
                // メンバー一覧
                // ========================================
                Expanded(
                  child: ListView.builder(
                    itemCount: _group.members.length,
                    itemBuilder: (context, index) {
                      final member = _group.members[index];
                      final isSelf = member.id == currentUserId;
                      final isMemberAdmin = member.id == _group.admin.id;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple,
                          backgroundImage: member.profileImageUrl != null
                              ? NetworkImage(member.profileImageUrl!)
                              : null,
                          child: member.profileImageUrl == null
                              ? Text(
                                  member.username[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                )
                              : null,
                        ),
                        title: Row(
                          children: [
                            Text(member.username),
                            if (isMemberAdmin) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '管理者',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            if (isSelf) ...[
                              const SizedBox(width: 6),
                              const Text(
                                '（自分）',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text('@${member.handle}'),
                        // 管理者は自分以外のメンバーを削除可
                        trailing: isAdmin && !isSelf && !isMemberAdmin
                            ? IconButton(
                                icon: const Icon(
                                  Icons.remove_circle,
                                  color: Colors.red,
                                ),
                                tooltip: 'メンバーを削除',
                                onPressed: () =>
                                    _removeMember(member, currentUserId),
                              )
                            : null,
                      );
                    },
                  ),
                ),

                // ========================================
                // 下部アクションボタン
                // ========================================
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (!isAdmin)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _leaveGroup(currentUserId),
                            icon: const Icon(
                              Icons.exit_to_app,
                              color: Colors.orange,
                            ),
                            label: const Text(
                              'グループから退出',
                              style: TextStyle(color: Colors.orange),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.orange),
                            ),
                          ),
                        ),
                      if (isAdmin) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _deleteGroup,
                            icon: const Icon(
                              Icons.delete_forever,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'グループを削除',
                              style: TextStyle(color: Colors.red),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
