// ========================================
// ボイスカード画面
// ========================================
// 受け取ったカード / 送ったカードを
// 横3列グリッドで一覧表示します

import 'package:flutter/material.dart';
import '../services/message_service.dart';
import 'followers_tab.dart';
import 'voice_playback_screen.dart';

class VoiceCardScreen extends StatefulWidget {
  const VoiceCardScreen({super.key});

  @override
  State<VoiceCardScreen> createState() => _VoiceCardScreenState();
}

class _VoiceCardScreenState extends State<VoiceCardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 受け取ったカード
  List<MessageInfo> _receivedCards = [];
  bool _receivedLoading = true;
  String? _receivedError;

  // 送ったカード（raw JSON → 変換後）
  List<_SentCardData> _sentCards = [];
  bool _sentLoading = true;
  String? _sentError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _loadReceived();
    _loadSent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ----------------------------------------
  // 受け取ったカード読み込み
  // ----------------------------------------
  Future<void> _loadReceived() async {
    setState(() {
      _receivedLoading = true;
      _receivedError = null;
    });
    try {
      final msgs = await MessageService.getReceivedMessages();
      if (mounted) {
        setState(() {
          _receivedCards = msgs;
          _receivedLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _receivedError = e.toString();
          _receivedLoading = false;
        });
      }
    }
  }

  // ----------------------------------------
  // 送ったカード読み込み
  // ----------------------------------------
  Future<void> _loadSent() async {
    setState(() {
      _sentLoading = true;
      _sentError = null;
    });
    try {
      final rawList = await MessageService.getSentMessages();
      if (mounted) {
        setState(() {
          _sentCards = rawList
              .map((j) => _SentCardData.fromJson(j as Map<String, dynamic>))
              .toList();
          _sentLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sentError = e.toString();
          _sentLoading = false;
        });
      }
    }
  }

  // ----------------------------------------
  // ボイスカードを送る → フォロワー選択へ遷移
  // ----------------------------------------
  void _onSendCard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserSearchScreen()),
    );
  }

  // ----------------------------------------
  // 日付フォーマット  2025.8.19
  // ----------------------------------------
  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month}.${dt.day}';
  }

  // ----------------------------------------
  // グラデーションプレースホルダー（サムネイルなし時）
  // ----------------------------------------
  static const List<List<Color>> _gradients = [
    [Color(0xFF667eea), Color(0xFF764ba2)],
    [Color(0xFFf093fb), Color(0xFFf5576c)],
    [Color(0xFF4facfe), Color(0xFF00f2fe)],
    [Color(0xFF43e97b), Color(0xFF38f9d7)],
    [Color(0xFFfa709a), Color(0xFFfee140)],
    [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
  ];

  List<Color> _gradientForName(String name) {
    final idx = name.isEmpty ? 0 : name.codeUnitAt(0) % _gradients.length;
    return _gradients[idx];
  }

  // ----------------------------------------
  // 1枚のカードウィジェット（受け取り）
  // ----------------------------------------
  Widget _buildReceivedCard(MessageInfo msg) {
    final grad = _gradientForName(msg.senderUsername);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VoicePlaybackScreen(message: msg)),
      ).then((_) => _loadReceived()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ---- カード本体 ----
          AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // サムネイル or グラデーション
                  if (msg.thumbnailUrl != null && msg.thumbnailUrl!.isNotEmpty)
                    Image.network(
                      msg.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _gradientBox(grad),
                    )
                  else
                    _gradientBox(grad),

                  // 下部グラデーションオーバーレイ
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.65),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 送信者アバター + 名前（下部）
                  Positioned(
                    bottom: 6,
                    left: 6,
                    right: 6,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.white,
                          backgroundImage:
                              msg.senderProfileImage != null &&
                                  msg.senderProfileImage!.isNotEmpty
                              ? NetworkImage(msg.senderProfileImage!)
                              : null,
                          child:
                              (msg.senderProfileImage == null ||
                                  msg.senderProfileImage!.isEmpty)
                              ? Text(
                                  msg.senderUsername.isNotEmpty
                                      ? msg.senderUsername[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            msg.senderUsername,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 未読バッジ「N」（右上）
                  if (!msg.isRead)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6B35),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'N',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // ---- 日付 ----
          const SizedBox(height: 4),
          Text(
            _formatDate(msg.sentAt),
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------
  // 1枚のカードウィジェット（送った）
  // ----------------------------------------
  Widget _buildSentCard(_SentCardData card) {
    final grad = _gradientForName(card.receiverName);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 3 / 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // サムネイル or グラデーション
                if (card.thumbnailUrl != null && card.thumbnailUrl!.isNotEmpty)
                  Image.network(
                    card.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _gradientBox(grad),
                  )
                else
                  _gradientBox(grad),

                // 下部グラデーションオーバーレイ
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.65),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // 受信者アバター + 名前（下部）
                Positioned(
                  bottom: 6,
                  left: 6,
                  right: 6,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.white,
                        backgroundImage:
                            card.receiverProfileImage != null &&
                                card.receiverProfileImage!.isNotEmpty
                            ? NetworkImage(card.receiverProfileImage!)
                            : null,
                        child:
                            (card.receiverProfileImage == null ||
                                card.receiverProfileImage!.isEmpty)
                            ? Text(
                                card.receiverName.isNotEmpty
                                    ? card.receiverName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          card.receiverName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 送信済みマーク（右上）
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.check,
                      size: 13,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatDate(card.sentAt),
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  // ----------------------------------------
  // グラデーションボックス（ヘルパー）
  // ----------------------------------------
  Widget _gradientBox(List<Color> colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: const Center(
        child: Icon(Icons.mic, size: 36, color: Colors.white54),
      ),
    );
  }

  // ----------------------------------------
  // グリッドビュー（共通）
  // ----------------------------------------
  Widget _buildGrid({
    required bool loading,
    required String? error,
    required int count,
    required Widget Function(int) builder,
    required VoidCallback onRefresh,
  }) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('エラー: $error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('再読み込み'),
            ),
          ],
        ),
      );
    }
    if (count == 0) {
      return const Center(
        child: Text('カードがありません', style: TextStyle(color: Colors.grey)),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 6,
          mainAxisSpacing: 12,
          childAspectRatio: 3 / 4.8, // カード + 日付分の高さを確保
        ),
        itemCount: count,
        itemBuilder: (_, i) => builder(i),
      ),
    );
  }

  // ----------------------------------------
  // build
  // ----------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'ボイスカード',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black87,
          indicatorWeight: 2,
          tabs: const [
            Tab(text: '受け取ったカード'),
            Tab(text: '送ったカード'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ---- 受け取ったカード ----
          _buildGrid(
            loading: _receivedLoading,
            error: _receivedError,
            count: _receivedCards.length,
            builder: (i) => _buildReceivedCard(_receivedCards[i]),
            onRefresh: _loadReceived,
          ),
          // ---- 送ったカード ----
          _buildGrid(
            loading: _sentLoading,
            error: _sentError,
            count: _sentCards.length,
            builder: (i) => _buildSentCard(_sentCards[i]),
            onRefresh: _loadSent,
          ),
        ],
      ),
      // ---- ボイスカードを送るボタン ----
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onSendCard,
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        elevation: 4,
        label: const Text(
          'ボイスカードを送る',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        icon: const Icon(Icons.mic, size: 20),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ========================================
// 送ったカードのデータモデル
// ========================================
class _SentCardData {
  final String id;
  final String receiverName;
  final String? receiverProfileImage;
  final String? thumbnailUrl;
  final DateTime sentAt;

  _SentCardData({
    required this.id,
    required this.receiverName,
    this.receiverProfileImage,
    this.thumbnailUrl,
    required this.sentAt,
  });

  factory _SentCardData.fromJson(Map<String, dynamic> json) {
    // receivers[0] の情報を取得
    String receiverName = 'Unknown';
    String? receiverProfileImage;
    final receivers = json['receivers'];
    if (receivers is List && receivers.isNotEmpty) {
      final first = receivers[0] as Map<String, dynamic>;
      receiverName = first['username'] as String? ?? 'Unknown';
      receiverProfileImage = first['profileImage'] as String?;
    }

    // サムネイル URL を組み立て
    const baseUrl = 'http://localhost:3000';
    final rawAttached = json['attachedImage'] as String?;
    final thumbnailUrl = rawAttached != null && rawAttached.isNotEmpty
        ? '$baseUrl/voice/${rawAttached.split('/').last}'
        : null;

    return _SentCardData(
      id: json['_id'] as String? ?? '',
      receiverName: receiverName,
      receiverProfileImage: receiverProfileImage,
      thumbnailUrl: thumbnailUrl,
      sentAt: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'] as String)
          : DateTime.now(),
    );
  }
}
