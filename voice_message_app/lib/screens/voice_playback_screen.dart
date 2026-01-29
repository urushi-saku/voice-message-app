// ========================================
// ボイスメッセージ再生画面
// ========================================
// 初学者向け説明：
// このファイルは、受信したボイスメッセージを再生するための画面です
// サムネイル、再生バー、再生/停止ボタンを表示します

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../constants.dart';

class VoicePlaybackScreen extends StatefulWidget {
  final String voiceUrl;
  final String fileName;
  final VoiceTheme theme;

  const VoicePlaybackScreen({
    super.key,
    required this.voiceUrl,
    required this.fileName,
    required this.theme,
  });

  @override
  State<VoicePlaybackScreen> createState() => _VoicePlaybackScreenState();
}

class _VoicePlaybackScreenState extends State<VoicePlaybackScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
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
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play(UrlSource(widget.voiceUrl));
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ========================================
            // サムネイル（アイコン）
            // ========================================
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: widget.theme.color.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.theme.color,
                  width: 4,
                ),
              ),
              child: Icon(
                widget.theme.icon,
                size: 100,
                color: widget.theme.color,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // ファイル名（タイトル）
            Text(
              widget.fileName,
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
              value: _position.inSeconds.toDouble().clamp(0, _duration.inSeconds.toDouble()),
              activeColor: widget.theme.color,
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
                _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                color: widget.theme.color,
              ),
              onPressed: _togglePlay,
            ),
          ],
        ),
      ),
    );
  }
}
