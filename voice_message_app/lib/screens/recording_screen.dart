// ========================================
// 録音画面（ボイスメッセージ送信用）
// ========================================
// 初学者向け説明：
// このファイルは、選択したフォロワーにボイスメッセージを
// 送信するための録音画面です

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../services/audio_service.dart';
import '../services/message_service.dart';

/// 録音画面ウィジェット
class RecordingScreen extends StatefulWidget {
  /// 送信先のユーザーIDリスト
  final List<String> recipientIds;

  const RecordingScreen({super.key, required this.recipientIds});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  // ========================================
  // 状態管理用の変数
  // ========================================
  bool _isRecording = false; // 録音中かどうか
  bool _hasRecording = false; // 録音済みの音声があるかどうか
  bool _isPlaying = false; // 再生中かどうか
  bool _isSending = false; // 送信中かどうか
  String? _recordedPath; // 録音ファイルのパス
  final AudioService _audioService = AudioService(); // オーディオサービスのインスタンス
  String? _thumbnailPath; // 選択されたサムネイル画像のパス
  final ImagePicker _imagePicker = ImagePicker(); // 画像選択用

  // ========================================
  // サムネイル画像を選択
  // ========================================
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _thumbnailPath = image.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('画像選択エラー: $e')));
    }
  }

  // ========================================
  // 録音開始
  // ========================================
  Future<void> _startRecording() async {
    try {
      await _audioService.startRecording();
      setState(() {
        _isRecording = true;
        _hasRecording = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('録音を開始しました')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('録音開始エラー: $e')));
    }
  }

  // ========================================
  // 録音停止
  // ========================================
  Future<void> _stopRecording() async {
    try {
      final path = await _audioService.stopRecording();
      setState(() {
        _isRecording = false;
        _hasRecording = true;
        _recordedPath = path;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('録音を停止しました')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('録音停止エラー: $e')));
    }
  }

  // ========================================
  // 録音音声を再生
  // ========================================
  Future<void> _playRecording() async {
    if (_recordedPath == null) return;

    try {
      setState(() {
        _isPlaying = true;
      });

      await _audioService.playLocal(_recordedPath!);

      // 再生終了後に状態を更新
      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      setState(() {
        _isPlaying = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('再生エラー: $e')));
    }
  }

  // ========================================
  // 再生停止
  // ========================================
  Future<void> _stopPlaying() async {
    try {
      await _audioService.stopPlaying();
      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('停止エラー: $e')));
    }
  }

  // ========================================
  // ボイスメッセージを送信
  // ========================================
  // ========================================
  // ボイスメッセージを送信
  // ========================================
  Future<void> _sendVoiceMessage() async {
    if (_recordedPath == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      // サーバーに音声ファイルをアップロード
      await MessageService.sendMessage(
        voiceFile: File(_recordedPath!),
        receiverIds: widget.recipientIds,
        duration: null, // TODO: 録音時間を計測して渡す
      );

      if (!mounted) return;

      // 送信成功
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.recipientIds.length}人に送信しました！'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // 前の画面に戻る（2つ戻る：録音画面→選択画面→フォロワー一覧）
      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isSending = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('送信エラー: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ボイスメッセージを録音')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ========================================
            // 送信先の表示
            // ========================================
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '送信先',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.recipientIds.length}人のフォロワー',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ========================================
            // サムネイル選択・表示
            // ========================================
            if (!_isRecording && !_hasRecording) ...[
              const Text(
                'サムネイルを選択（任意）',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: _thumbnailPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb
                              ? Image.network(
                                  _thumbnailPath!,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(_thumbnailPath!),
                                  fit: BoxFit.cover,
                                ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 50,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'タップして選択',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],

            // ========================================
            // 録音状態の表示
            // ========================================
            Center(
              child: Column(
                children: [
                  // 録音中のアニメーション
                  if (_isRecording)
                    const Icon(Icons.mic, size: 100, color: Colors.red),
                  // 録音済みの表示（サムネイルまたはアイコン）
                  if (_hasRecording && !_isRecording)
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: _thumbnailPath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: kIsWeb
                                  ? Image.network(
                                      _thumbnailPath!,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(_thumbnailPath!),
                                      fit: BoxFit.cover,
                                    ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.check_circle,
                                size: 100,
                                color: Colors.green[600],
                              ),
                            ),
                    ),
                  // 初期状態のアイコン
                  if (!_isRecording && !_hasRecording)
                    Icon(Icons.mic_none, size: 100, color: Colors.grey[400]),

                  const SizedBox(height: 16),

                  // 状態テキスト
                  Text(
                    _isRecording
                        ? '録音中...'
                        : _hasRecording
                        ? '録音完了'
                        : '録音ボタンを押して開始',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ========================================
            // 録音ボタン
            // ========================================
            if (!_hasRecording)
              ElevatedButton.icon(
                onPressed: _isRecording ? _stopRecording : _startRecording,
                icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                label: Text(_isRecording ? '録音停止' : '録音開始'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _isRecording ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),

            // ========================================
            // 録音済みの場合のボタン
            // ========================================
            if (_hasRecording) ...[
              // 再生ボタン
              ElevatedButton.icon(
                onPressed: _isPlaying ? _stopPlaying : _playRecording,
                icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                label: Text(_isPlaying ? '停止' : '再生'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // 再録音ボタン
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _hasRecording = false;
                    _recordedPath = null;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('録り直す'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              const SizedBox(height: 16),

              // 送信ボタン
              ElevatedButton.icon(
                onPressed: _isSending ? null : _sendVoiceMessage,
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(_isSending ? '送信中...' : '送信する'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 画面を閉じる時に再生を停止
    _audioService.stopPlaying();
    super.dispose();
  }
}
