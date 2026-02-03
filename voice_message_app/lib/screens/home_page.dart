// ========================================
// ホームページ - メイン画面（タブ管理）
// ========================================
// 初学者向け説明：
// このファイルは、アプリのメイン画面を表示します
// 3つのタブ（ボイスメッセージ、フォロワー、受信ファイル）を管理します

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'profile_page.dart';
import 'followers_tab.dart';
import 'received_files_tab.dart';

/// ホームページウィジェット（タブナビゲーション）
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ========================================
  // タブの状態管理
  // ========================================
  int _currentTabIndex = 0; // 現在選択中のタブ（0=メッセージ, 1=フォロワー, 2=受信）

  // ========================================
  // サービスとデータ
  // ========================================
  final AudioService _audioService = AudioService();
  List<String> _serverVoices = []; // サーバーの音声リスト
  String? _playingVoice; // 現在再生中の音声
  bool _isLoadingVoices = false; // 読み込み中フラグ

  @override
  void initState() {
    super.initState();
    _loadVoices(); // 初回ロード
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  // ========================================
  // 音声一覧を読み込み
  // ========================================
  Future<void> _loadVoices() async {
    setState(() {
      _isLoadingVoices = true;
    });

    final voices = await ApiService.fetchVoices();

    setState(() {
      _serverVoices = voices;
      _isLoadingVoices = false;
    });
  }

  // ========================================
  // マイク権限をリクエスト
  // ========================================
  Future<bool> _requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // ========================================
  // 録音を開始/停止
  // ========================================
  Future<void> _toggleRecording() async {
    if (_audioService.isRecording) {
      // 録音停止
      final path = await _audioService.stopRecording();
      if (path != null) {
        _showUploadDialog(path);
      }
    } else {
      // 録音開始
      if (await _requestPermission()) {
        final started = await _audioService.startRecording();
        if (!started) {
          _showError('録音を開始できませんでした');
        }
      } else {
        _showError('マイク権限が必要です');
      }
    }

    setState(() {}); // UIを更新
  }

  // ========================================
  // アップロード確認ダイアログ
  // ========================================
  void _showUploadDialog(String path) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('録音完了'),
        content: const Text('サーバーにアップロードしますか？'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _uploadVoice(path);
            },
            child: const Text('アップロード'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 音声をアップロード
  // ========================================
  Future<void> _uploadVoice(String path) async {
    final success = await ApiService.uploadVoice(path);

    if (success) {
      _showSuccess('アップロード成功');
      _loadVoices(); // 一覧を更新
    } else {
      _showError('アップロード失敗');
    }
  }

  // ========================================
  // 音声を再生
  // ========================================
  Future<void> _playVoice(String filename) async {
    final url = ApiService.getVoiceUrl(filename);
    await _audioService.playRemote(url);

    setState(() {
      _playingVoice = filename;
    });
  }

  // ========================================
  // 再生を停止
  // ========================================
  Future<void> _stopPlaying() async {
    await _audioService.stopPlaying();

    setState(() {
      _playingVoice = null;
    });
  }

  // ========================================
  // エラーメッセージを表示
  // ========================================
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ========================================
  // 成功メッセージを表示
  // ========================================
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // ========================================
  // タブに応じたタイトルを返す
  // ========================================
  String _getTabTitle() {
    switch (_currentTabIndex) {
      case 0:
        return 'ボイスメッセージ';
      case 1:
        return 'フォロワー';
      case 2:
        return '受信メッセージ';
      default:
        return 'ボイスメッセージ';
    }
  }

  // ========================================
  // 各タブの内容を返す
  // ========================================
  Widget _getCurrentTab() {
    switch (_currentTabIndex) {
      case 0:
        return _buildMessagesTab(); // ボイスメッセージタブ
      case 1:
        return const FollowersTab(); // フォロワータブ
      case 2:
        return const ReceivedFilesTab(); // 受信ファイルタブ
      default:
        return _buildMessagesTab();
    }
  }

  // ========================================
  // ボイスメッセージタブの内容
  // ========================================
  Widget _buildMessagesTab() {
    return Column(
      children: [
        // ========================================
        // 録音ボタン
        // ========================================
        Container(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton.icon(
            icon: Icon(
              _audioService.isRecording ? Icons.stop : Icons.mic,
              size: 30,
            ),
            label: Text(
              _audioService.isRecording ? '録音停止' : '録音開始',
              style: const TextStyle(fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              backgroundColor: _audioService.isRecording
                  ? Colors.red
                  : Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: _toggleRecording,
          ),
        ),

        const Divider(),

        // ========================================
        // 音声リスト
        // ========================================
        Expanded(
          child: _isLoadingVoices
              ? const Center(child: CircularProgressIndicator())
              : _serverVoices.isEmpty
              ? const Center(child: Text('音声がありません'))
              : ListView.builder(
                  itemCount: _serverVoices.length,
                  itemBuilder: (context, index) {
                    final voice = _serverVoices[index];
                    final isPlaying = _playingVoice == voice;

                    return ListTile(
                      leading: Icon(
                        isPlaying ? Icons.volume_up : Icons.audiotrack,
                        color: isPlaying ? Colors.green : Colors.grey,
                      ),
                      title: Text(voice),
                      trailing: IconButton(
                        icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
                        onPressed: () {
                          if (isPlaying) {
                            _stopPlaying();
                          } else {
                            _playVoice(voice);
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ========================================
  // UIを構築
  // ========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTabTitle()), // タブに応じたタイトル
        actions: [
          // ========================================
          // プロフィールボタン（右上）
          // ========================================
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'プロフィール',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          // リフレッシュボタン（メッセージタブのみ表示）
          if (_currentTabIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '更新',
              onPressed: _loadVoices,
            ),
        ],
      ),
      body: _getCurrentTab(), // 現在選択中のタブを表示
      // ========================================
      // 下部ナビゲーションバー
      // ========================================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'メッセージ'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'フォロワー'),
          BottomNavigationBarItem(icon: Icon(Icons.inbox), label: '受信'),
        ],
      ),
    );
  }
}
