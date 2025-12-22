// Flutterの基本ウィジェットを使うためのimport（おまじない）
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

// サーバーのURL（開発環境用）
const String serverUrl = 'http://localhost:3000';

// アプリのエントリーポイント（最初に実行される関数）
void main() {
  runApp(const MyApp());
}

// アプリ全体の設定やテーマを管理するウィジェット
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ボイスメッセージアプリ', // アプリのタイトル（日本語）
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), // 色のテーマ
      ),
      home: const HomePage(), // 最初に表示する画面
    );
  }
}

// ボイスメッセージの一覧や録音ボタンを表示する画面
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordedFilePath;
  List<String> _uploadedFiles = [];
  List<String> _serverVoices = []; // サーバーから取得した音声リスト
  String? _playingVoice; // 現在再生中の音声ファイル名
  bool _isLoadingVoices = false;

  @override
  void initState() {
    super.initState();
    _loadVoicesFromServer(); // 初回ロード
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // サーバーから音声ファイル一覧を取得
  Future<void> _loadVoicesFromServer() async {
    setState(() {
      _isLoadingVoices = true;
    });

    try {
      final response = await http.get(Uri.parse('$serverUrl/voices'));
      if (response.statusCode == 200) {
        // 簡易的なJSONパース（dart:convertを使わない方法）
        final data = response.body;
        
        // {"files":["file1.m4a","file2.m4a"]} の形式を想定
        final startIndex = data.indexOf('[');
        final endIndex = data.lastIndexOf(']');
        
        if (startIndex != -1 && endIndex != -1) {
          final filesString = data.substring(startIndex + 1, endIndex);
          if (filesString.trim().isEmpty) {
            setState(() {
              _serverVoices = [];
            });
          } else {
            final files = filesString
                .split(',')
                .map((f) => f.trim().replaceAll('"', ''))
                .where((f) => f.isNotEmpty)
                .toList();
            setState(() {
              _serverVoices = files;
            });
          }
        } else {
          setState(() {
            _serverVoices = [];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('一覧取得エラー: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingVoices = false;
      });
    }
  }

  // マイクのパーミッションをリクエスト
  Future<bool> _requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // 録音開始
  Future<void> _startRecording() async {
    final hasPermission = await _requestPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('マイクの許可が必要です')),
        );
      }
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: filePath,
    );

    setState(() {
      _isRecording = true;
      _recordedFilePath = filePath;
    });
  }

  // 録音停止
  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _recordedFilePath = path;
    });

    if (mounted && path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('録音完了しました')),
      );
    }
  }

  // 録音した音声を再生
  Future<void> _playRecording() async {
    if (_recordedFilePath == null) return;

    if (_isPlaying) {
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
      });
    } else {
      await _audioPlayer.play(DeviceFileSource(_recordedFilePath!));
      setState(() {
        _isPlaying = true;
      });

      // 再生完了時にステータスをリセット
      _audioPlayer.onPlayerComplete.listen((_) {
        setState(() {
          _isPlaying = false;
        });
      });
    }
  }

  // サーバーにアップロード
  Future<void> _uploadToServer() async {
    if (_recordedFilePath == null) return;

    try {
      final file = File(_recordedFilePath!);
      final request = http.MultipartRequest('POST', Uri.parse('$serverUrl/upload'));
      request.files.add(await http.MultipartFile.fromPath('voice', file.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('アップロード成功！')),
          );
          setState(() {
            _uploadedFiles.add(_recordedFilePath!);
            _recordedFilePath = null;
          });
          // アップロード後に一覧を更新
          _loadVoicesFromServer();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('アップロード失敗: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  // サーバーから音声を再生
  Future<void> _playServerVoice(String filename) async {
    if (_playingVoice == filename) {
      // 再生中の場合は停止
      await _audioPlayer.stop();
      setState(() {
        _playingVoice = null;
      });
    } else {
      // サーバーから音声を再生
      await _audioPlayer.stop();
      final url = '$serverUrl/voice/$filename';
      await _audioPlayer.play(UrlSource(url));
      setState(() {
        _playingVoice = filename;
      });

      // 再生完了時にステータスをリセット
      _audioPlayer.onPlayerComplete.listen((_) {
        setState(() {
          _playingVoice = null;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ボイスメッセージ'),
        actions: [
          // 右上のプロフィールアイコンボタン
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // プロフィール画面へ遷移
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // サーバーの音声メッセージ一覧
          Expanded(
            child: _isLoadingVoices
                ? const Center(child: CircularProgressIndicator())
                : _serverVoices.isEmpty
                    ? const Center(child: Text('まだメッセージがありません'))
                    : RefreshIndicator(
                        onRefresh: _loadVoicesFromServer,
                        child: ListView.builder(
                          itemCount: _serverVoices.length,
                          itemBuilder: (context, index) {
                            final voice = _serverVoices[index];
                            final isPlaying = _playingVoice == voice;
                // 録音ボタン
                ElevatedButton.icon(
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  label: Text(_isRecording ? '録音停止' : '録音開始'),
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRecording ? Colors.red : null,
                    foregroundColor: _isRecording ? Colors.white : null,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // 再生・アップロードボタン（録音済みファイルがある場合のみ表示）
                if (_recordedFilePath != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                        label: Text(_isPlaying ? '停止' : '再生'),
                        onPressed: _playRecording,
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('送信'),
                        onPressed: _uploadToServer,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ]         blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            
            // 録音ボタン
            ElevatedButton.icon(
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              label: Text(_isRecording ? '録音停止' : '録音開始'),
              onPressed: _isRecording ? _stopRecording : _startRecording,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRecording ? Colors.red : null,
                foregroundColor: _isRecording ? Colors.white : null,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 再生・アップロードボタン（録音済みファイルがある場合のみ表示）
            if (_recordedFilePath != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    label: Text(_isPlaying ? '停止' : '再生'),
                    onPressed: _playRecording,
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('送信'),
                    onPressed: _uploadToServer,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// プロフィール情報を表示・編集する画面
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ユーザーアイコン（仮）
            const CircleAvatar(
              radius: 40,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 16),
            // ユーザー名（仮）
            const Text('ユーザー名'),
            const SizedBox(height: 16),
            // プロフィール編集ボタン
            ElevatedButton(
              onPressed: () {
                // プロフィール編集機能は後で実装します
              },
              child: const Text('プロフィール編集'),
            ),
          ],
        ),
      ),
    );
  }
}
