// ========================================
// 録音状態管理 Provider
// ========================================
// 録音・再生・送信のビジネスロジックを管理する
// 以前は RecordingScreen の State に直書きしていたロジックを分離
// AnimationController は TickerProvider が必要なため Screen 側に残す

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/audio_service.dart';
import '../services/message_service.dart';
import '../models/recording_config.dart';

class RecordingProvider extends ChangeNotifier {
  // ========================================
  // 状態変数
  // ========================================
  bool _isRecording = false;
  bool _hasRecording = false;
  bool _isPlaying = false;
  bool _isSending = false;
  String? _recordedPath;
  String? _thumbnailPath;
  int _recordSeconds = 0;
  String? _error;
  RecordingQuality _currentQuality = RecordingQuality.medium;

  Timer? _timer;
  final AudioService _audioService = AudioService();

  // ========================================
  // ゲッター
  // ========================================
  bool get isRecording => _isRecording;
  bool get hasRecording => _hasRecording;
  bool get isPlaying => _isPlaying;
  bool get isSending => _isSending;
  String? get recordedPath => _recordedPath;
  String? get thumbnailPath => _thumbnailPath;
  int get recordSeconds => _recordSeconds;
  String? get error => _error;
  RecordingQuality get currentQuality => _currentQuality;

  String get timerText {
    final m = _recordSeconds ~/ 60;
    final s = _recordSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ========================================
  // 初期化（録音品質の読み込み）
  // ========================================
  Future<void> loadRecordingQuality() async {
    final prefs = await SharedPreferences.getInstance();
    final qualityIndex = prefs.getInt('recording_quality') ?? 1;
    _currentQuality = RecordingQuality.values[qualityIndex];
    _audioService.setQuality(_currentQuality);
    notifyListeners();
  }

  // ========================================
  // タイマー制御
  // ========================================
  void _startTimer() {
    _recordSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _recordSeconds++;
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // ========================================
  // 録音開始
  // ========================================
  Future<void> startRecording() async {
    _error = null;
    try {
      await _audioService.startRecording();
      _startTimer();
      _isRecording = true;
      _hasRecording = false;
      notifyListeners();
    } catch (e) {
      _error = 'マイクへのアクセスを許可してください';
      notifyListeners();
    }
  }

  // ========================================
  // 録音停止
  // ========================================
  Future<void> stopRecording() async {
    _error = null;
    try {
      final path = await _audioService.stopRecording();
      _stopTimer();
      _isRecording = false;
      _hasRecording = true;
      _recordedPath = path;
      notifyListeners();
    } catch (e) {
      _error = '録音の停止に失敗しました';
      notifyListeners();
    }
  }

  // ========================================
  // 再録音（リセット）
  // ========================================
  void retake() {
    _hasRecording = false;
    _recordedPath = null;
    _recordSeconds = 0;
    notifyListeners();
  }

  // ========================================
  // 再生 / 停止トグル
  // ========================================
  Future<void> togglePlay() async {
    if (_isPlaying) {
      await _audioService.stopPlaying();
      _isPlaying = false;
      notifyListeners();
    } else {
      _isPlaying = true;
      notifyListeners();
      try {
        await _audioService.playLocal(_recordedPath!);
      } catch (_) {}
      _isPlaying = false;
      notifyListeners();
    }
  }

  // ========================================
  // 送信
  // ========================================
  /// 送信ビジネスロジック本体
  /// 成功時は正常終了、オフライン保存は 'offline:xxx' 例外をスロー
  Future<void> send(List<String> receiverIds) async {
    if (_recordedPath == null) throw Exception('録音ファイルがありません');
    _isSending = true;
    _error = null;
    notifyListeners();

    try {
      await MessageService.sendMessage(
        voiceFile: File(_recordedPath!),
        receiverIds: receiverIds,
        duration: _recordSeconds > 0 ? _recordSeconds : null,
        thumbnailFile: _thumbnailPath != null ? File(_thumbnailPath!) : null,
      );
      _isSending = false;
      notifyListeners();
    } catch (e) {
      _isSending = false;
      notifyListeners();
      rethrow;
    }
  }

  // ========================================
  // サムネイル設定
  // ========================================
  void setThumbnailPath(String? path) {
    _thumbnailPath = path;
    notifyListeners();
  }

  // ========================================
  // 解放
  // ========================================
  @override
  void dispose() {
    _stopTimer();
    _audioService.stopPlaying();
    super.dispose();
  }
}
