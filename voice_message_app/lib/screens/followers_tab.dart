// ========================================
// フォロワー一覧タブ
// ========================================
// 初学者向け説明：
// このファイルは、フォロワー（ユーザーをフォローしている人）の
// 一覧を表示するタブです

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import 'user_profile_screen.dart';

/// フォロワー一覧を表示するウィジェット
class FollowersTab extends StatefulWidget {
  // 0: フォロワー, 1: フォロー中
  final int initialTabIndex;

  /// 指定した場合、そのユーザーのフォロワー/フォロー一覧を表示
  /// null の場合はログイン中ユーザーのリストを表示
  final String? targetUserId;

  const FollowersTab({super.key, this.initialTabIndex = 0, this.targetUserId});

  @override
  State<FollowersTab> createState() => _FollowersTabState();
}

class _FollowersTabState extends State<FollowersTab> {
  // ========================================
  // 状態変数
  // ========================================
  List<UserInfo> _followers = [];
  List<UserInfo> _following = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  // ========================================
  // フォロワー・フォロー中リストを読み込み
  // ========================================
  Future<void> _loadFollowers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = widget.targetUserId ?? authProvider.user?.id;

      if (userId == null) {
        throw Exception('ユーザー情報が取得できません');
      }

      // フォロワーとフォロー中を並行取得
      final results = await Future.wait([
        UserService.getFollowers(userId),
        UserService.getFollowing(userId),
      ]);

      setState(() {
        _followers = results[0];
        _following = results[1];
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
  // ユーザー検索画面を開く
  // ========================================
  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserSearchScreen()),
    ).then((_) => _loadFollowers()); // 戻ってきたらリロード
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('フォロワー'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'フォロワー'),
              Tab(text: 'フォロー中'),
            ],
          ),
          actions: [
            // ========================================
            // ユーザー検索ボタン
            // ========================================
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'ユーザー検索',
              onPressed: _openSearch,
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
                      onPressed: _loadFollowers,
                      child: const Text('再読み込み'),
                    ),
                  ],
                ),
              )
            : TabBarView(
                children: [
                  _buildFollowerList(_followers),
                  _buildFollowerList(_following),
                ],
              ),
      ),
    );
  }

  // ========================================
  // フォロワーリスト表示
  // ========================================
  Widget _buildFollowerList(List<UserInfo> users) {
    if (users.isEmpty) {
      return const Center(child: Text('ユーザーがいません'));
    }

    return RefreshIndicator(
      onRefresh: _loadFollowers,
      child: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];

          return ListTile(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => UserProfileScreen(user: user)),
            ),
            // ========================================
            // ユーザーアイコン
            // ========================================
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple,
              backgroundImage: user.profileImage != null
                  ? NetworkImage(user.profileImage!)
                  : null,
              child: user.profileImage == null
                  ? Text(
                      user.username[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),

            // ========================================
            // ユーザー名・ID・自己紹介
            // ========================================
            title: Text(user.username),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@${user.handle}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                if (user.bio.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.bio,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ========================================
// ユーザー検索画面
// ========================================
class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _searchController = TextEditingController();
  List<UserInfo> _searchResults = [];
  List<UserInfo> _following = []; // フォロー中のユーザーリスト（フォロー状態判定用）
  bool _isSearching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFollowingList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ========================================
  // フォロー中のリストを読み込み
  // ========================================
  Future<void> _loadFollowingList() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;
      if (userId != null) {
        final following = await UserService.getFollowing(userId);
        if (mounted) {
          setState(() {
            _following = following;
          });
        }
      }
    } catch (e) {
      print('フォロー中リスト読み込みエラー: $e');
    }
  }

  // ========================================
  // ユーザー検索
  // ========================================
  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final results = await UserService.searchUsers(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSearching = false;
      });
    }
  }

  // ========================================
  // フォロー/フォロー解除
  // ========================================
  Future<void> _toggleFollow(UserInfo user, bool isFollowing) async {
    try {
      if (isFollowing) {
        await UserService.unfollowUser(user.id);
        if (mounted) {
          setState(() {
            _following.removeWhere((u) => u.id == user.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.username}のフォローを解除しました')),
          );
        }
      } else {
        await UserService.followUser(user.id);
        if (mounted) {
          setState(() {
            _following.add(user);
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${user.username}をフォローしました')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラー: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ユーザー検索')),
      body: Column(
        children: [
          // ========================================
          // 検索フィールド
          // ========================================
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ユーザー名で検索',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {}); // UI更新トリガー（クリアボタン表示用）
                // デバウンス処理（0.5秒待ってから検索）
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted && _searchController.text == value) {
                    _searchUsers(value);
                  }
                });
              },
            ),
          ),

          // ========================================
          // 検索結果
          // ========================================
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text('エラー: $_error'))
                : _searchResults.isEmpty
                ? const Center(child: Text('ユーザーが見つかりません'))
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      // フォロー状態を判定
                      final isFollowing = _following.any(
                        (u) => u.id == user.id,
                      );

                      return ListTile(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserProfileScreen(user: user),
                          ),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple,
                          backgroundImage: user.profileImage != null
                              ? NetworkImage(user.profileImage!)
                              : null,
                          child: user.profileImage == null
                              ? Text(
                                  user.username[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(user.username),
                        subtitle: Text(
                          '@${user.handle}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _toggleFollow(user, isFollowing),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFollowing
                                ? Colors.grey
                                : Colors.deepPurple,
                          ),
                          child: Text(
                            isFollowing ? 'フォロー中' : 'フォロー',
                            style: const TextStyle(color: Colors.white),
                          ),
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
