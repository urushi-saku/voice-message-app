// ========================================
// グループ作成画面
// ========================================
// グループ名・説明・メンバー選択を行う画面

import 'package:flutter/material.dart';
import '../services/group_service.dart';
import '../services/user_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  // ========================================
  // フォームコントローラー
  // ========================================
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _searchController = TextEditingController();

  // ========================================
  // 状態変数
  // ========================================
  List<UserInfo> _searchResults = [];
  final List<UserInfo> _selectedMembers = [];
  bool _isSearching = false;
  bool _isCreating = false;
  String? _searchError;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ========================================
  // ユーザー検索
  // ========================================
  Future<void> _searchUsers(String keyword) async {
    if (keyword.isEmpty) {
      setState(() {
        _searchResults = [];
        _searchError = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final results = await UserService.searchUsers(keyword);
      setState(() {
        // すでに選択済みのメンバーを除外
        _searchResults = results
            .where((u) => !_selectedMembers.any((s) => s.id == u.id))
            .toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchError = e.toString();
        _isSearching = false;
      });
    }
  }

  // ========================================
  // メンバー追加
  // ========================================
  void _addMember(UserInfo user) {
    if (_selectedMembers.any((m) => m.id == user.id)) return;
    setState(() {
      _selectedMembers.add(user);
      _searchResults.removeWhere((u) => u.id == user.id);
    });
  }

  // ========================================
  // メンバー削除
  // ========================================
  void _removeMember(UserInfo user) {
    setState(() {
      _selectedMembers.removeWhere((m) => m.id == user.id);
    });
  }

  // ========================================
  // グループ作成
  // ========================================
  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('グループ名を入力してください')));
      return;
    }
    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('メンバーを1人以上選択してください')));
      return;
    }

    setState(() => _isCreating = true);

    try {
      final group = await GroupService.createGroup(
        name: name,
        description: _descController.text.trim(),
        memberIds: _selectedMembers.map((m) => m.id).toList(),
      );
      if (mounted) {
        Navigator.pop(context, group);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('作成失敗: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  // ========================================
  // ビルド
  // ========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新しいグループ'),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createGroup,
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('作成', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      body: Column(
        children: [
          // ========================================
          // グループ情報入力
          // ========================================
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'グループ名 *',
                    hintText: '例: チームA、友達グループ',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.group),
                  ),
                  maxLength: 50,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'グループの説明（任意）',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                  maxLines: 2,
                  maxLength: 200,
                ),
              ],
            ),
          ),

          const Divider(),

          // ========================================
          // 選択済みメンバー表示
          // ========================================
          if (_selectedMembers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'メンバー (${_selectedMembers.length}人)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _selectedMembers.length,
                itemBuilder: (context, index) {
                  final member = _selectedMembers[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.deepPurple,
                              backgroundImage: member.profileImage != null
                                  ? NetworkImage(member.profileImage!)
                                  : null,
                              child: member.profileImage == null
                                  ? Text(
                                      member.username[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _removeMember(member),
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          member.username,
                          style: const TextStyle(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(),
          ],

          // ========================================
          // ユーザー検索
          // ========================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ユーザーを検索してメンバーに追加',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => _searchUsers(v),
            ),
          ),

          // ========================================
          // 検索結果リスト
          // ========================================
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchError != null
                ? Center(child: Text('エラー: $_searchError'))
                : _searchResults.isEmpty && _searchController.text.isNotEmpty
                ? const Center(child: Text('ユーザーが見つかりません'))
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple,
                          backgroundImage: user.profileImage != null
                              ? NetworkImage(user.profileImage!)
                              : null,
                          child: user.profileImage == null
                              ? Text(
                                  user.username[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                )
                              : null,
                        ),
                        title: Text(user.username),
                        subtitle: Text('@${user.handle}'),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Colors.deepPurple,
                          ),
                          onPressed: () => _addMember(user),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
