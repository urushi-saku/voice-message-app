// ========================================
// ボイスメッセージ再生画面
// ========================================
// 初学者向け説明：
// このファイルは、受信したボイスメッセージを再生するための画面です
// サムネイル、再生バー、再生/停止ボタンを表示します

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/message_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class VoicePlaybackScreen extends StatefulWidget {
  final MessageInfo message;

  const VoicePlaybackScreen({super.key, required this.message});

  @override
  State<VoicePlaybackScreen> createState() => _VoicePlaybackScreenState();
}

class _VoicePlaybackScreenState extends State<VoicePlaybackScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = true;
  String? _error;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _localFilePath;

  @override
  void initState() {
    super.initState();
    _downloadAndPrepare();
  }

  // ========================================
  // 音声ファイルをダウンロードして準備
  // ========================================
  Future<void> _downloadAndPrepare() async {
    try {
      // 一時ディレクトリを取得
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/${widget.message.id}.m4a';

      // ファイルが既に存在するかチェック
      final file = File(savePath);
      if (!await file.exists()) {
        // ダウンロード
        await MessageService.downloadMessage(
          messageId: widget.message.id,
          savePath: savePath,
        );
      }

      setState(() {
        _localFilePath = savePath;
        _isLoading = false;
      });

      _initAudioPlayer();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _initAudioPlayer() async {
    if (_localFilePath == null) return;

    // 再生状態の変更を監視
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    // 再生時間の変更を監視
    _player.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    // 再生位置の変更を監視
    _player.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });

    // 再生終了時の処理
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _position = Duration.zero;
          _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  // 再生・一時停止の切り替え
  Future<void> _togglePlay() async {
    if (_localFilePath == null) return;

    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play(DeviceFileSource(_localFilePath!));
    }
  }

  // 時間を 00:00 形式にフォーマット
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ボイスメッセージ'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('エラー: $_error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('戻る'),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ========================================
                  // 送信者アイコン
                  // ========================================
                  CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.deepPurple,
                    backgroundImage: widget.message.senderProfileImage != null
                        ? NetworkImage(widget.message.senderProfileImage!)
                        : null,
                    child: widget.message.senderProfileImage == null
                        ? Text(
                            widget.message.senderUsername[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),

                  const SizedBox(height: 24),

                  // 送信者名
                  Text(
                    widget.message.senderUsername,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  // ========================================
                  // 再生バー（スライダー）
                  // ========================================
                  Slider(
                    min: 0,
                    max: _duration.inSeconds.toDouble(),
                    value: _position.inSeconds.toDouble().clamp(
                      0,
                      _duration.inSeconds.toDouble(),
                    ),
                    activeColor: Colors.deepPurple,
                    onChanged: (value) async {
                      final position = Duration(seconds: value.toInt());
                      await _player.seek(position);
                    },
                  ),

                  // 時間表示
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(_position)),
                        Text(_formatDuration(_duration)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ========================================
                  // 再生・停止ボタン
                  // ========================================
                  IconButton(
                    iconSize: 80,
                    icon: Icon(
                      _isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: Colors.deepPurple,
                    ),
                    onPressed: _togglePlay,
                  ),
                ],
              ),
            ),
    );
  }
}
