// ========================================
// 録音状態管理 Provider
// ========================================
// 録音・再生・送信のビジネスロジックを管理する
// 以前は RecordingScreen の State に直書きしていたロジックを分離
// AnimationController は TickerProvider が必要なため Screen 側に残す

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
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
  bool _isFromFile = false;
  String? _recordedPath;
  String? _thumbnailPath;
  int _recordSeconds = 0;
  int _playSeconds = 0; // 再生中の現在位置（秒）
  Duration _playDuration = Duration.zero; // オーディオ全体尺度
  List<double> _waveformData = []; // 振幅サンプル（0.0～1.0）
  String? _error;
  RecordingQuality _currentQuality = RecordingQuality.medium;
  bool _disposed = false;

  Timer? _timer;
  Timer? _ampTimer; // 振幅サンプリング用
  StreamSubscription? _playerCompleteSub;
  StreamSubscription? _playerPositionSub;
  StreamSubscription? _playerDurationSub;
  final AudioService _audioService = AudioService();

  // ========================================
  // ゲッター
  // ========================================
  bool get isRecording => _isRecording;
  bool get hasRecording => _hasRecording;
  bool get isPlaying => _isPlaying;
  bool get isSending => _isSending;
  bool get isFromFile => _isFromFile;
  String? get recordedPath => _recordedPath;
  String? get thumbnailPath => _thumbnailPath;
  int get recordSeconds => _recordSeconds;
  String? get error => _error;
  RecordingQuality get currentQuality => _currentQuality;

  /// 録音時の振幅サンプルリスト（0.0～1.0）
  List<double> get waveformData => List.unmodifiable(_waveformData);

  /// 再生進捗 0.0～1.0
  double get playProgress {
    final ms = _playDuration.inMilliseconds;
    if (ms == 0) return 0.0;
    return (_playSeconds * 1000 / ms).clamp(0.0, 1.0);
  }

  String get timerText {
    // 再生中は再生位置、録音中は経過秒数を表示
    final secs = _isPlaying ? _playSeconds : _recordSeconds;
    final m = secs ~/ 60;
    final s = secs % 60;
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
    _waveformData = [];

    // 1秒カウントアップ
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _recordSeconds++;
      if (!_disposed) notifyListeners();
    });

    // 150ms ごとに振幅サンプリング
    _ampTimer = Timer.periodic(const Duration(milliseconds: 150), (_) async {
      if (!_isRecording) return;
      final level = await _audioService.getAmplitudeLevel();
      _waveformData.add(level);
      if (!_disposed) notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _ampTimer?.cancel();
    _ampTimer = null;
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
  // ファイルから設定（アップロード用）
  // ========================================
  void setFromFile(String path) {
    _recordedPath = path;
    _hasRecording = true;
    _isFromFile = true;
    _isRecording = false;
    _recordSeconds = 0;
    // ファイルパスのハッシュから安定した疴傾波形を生成
    final rng = math.Random(path.hashCode);
    _waveformData = List.generate(60, (i) {
      // 中央に向かって高くなる包級線（sin)＋ランダム
      final env = math.sin(i / 59 * math.pi);
      return 0.08 + env * 0.55 + rng.nextDouble() * 0.37;
    });
    notifyListeners();
  }

  // ========================================
  // 再録音（リセット）
  // ========================================
  void retake() {
    if (_isPlaying) {
      _playerPositionSub?.cancel();
      _playerDurationSub?.cancel();
      _playerCompleteSub?.cancel();
      _audioService.stopPlaying();
      _isPlaying = false;
      _playSeconds = 0;
      _playDuration = Duration.zero;
    }
    _hasRecording = false;
    _isFromFile = false;
    _recordedPath = null;
    _recordSeconds = 0;
    _waveformData = [];
    notifyListeners();
  }

  // ========================================
  // 再生 / 停止トグル
  // ========================================
  Future<void> togglePlay() async {
    if (_isPlaying) {
      _playerPositionSub?.cancel();
      _playerDurationSub?.cancel();
      _playerCompleteSub?.cancel();
      await _audioService.stopPlaying();
      _isPlaying = false;
      _playSeconds = 0;
      _playDuration = Duration.zero;
      if (!_disposed) notifyListeners();
    } else {
      _playSeconds = 0;
      _playDuration = Duration.zero;
      _isPlaying = true;
      if (!_disposed) notifyListeners();

      // 全体尺度を取得
      _playerDurationSub = _audioService.onDurationChanged.listen((d) {
        _playDuration = d;
        if (!_disposed) notifyListeners();
      });

      // 再生位置を追跡
      _playerPositionSub = _audioService.onPositionChanged.listen((pos) {
        _playSeconds = pos.inSeconds;
        if (!_disposed) notifyListeners();
      });

      // 再生完了
      _playerCompleteSub = _audioService.onPlayerComplete.listen((_) {
        _isPlaying = false;
        _playSeconds = 0;
        _playDuration = Duration.zero;
        _playerPositionSub?.cancel();
        _playerDurationSub?.cancel();
        _playerCompleteSub?.cancel();
        if (!_disposed) notifyListeners();
      });

      try {
        await _audioService.playLocal(_recordedPath!);
      } catch (_) {
        _isPlaying = false;
        _playSeconds = 0;
        _playDuration = Duration.zero;
        _playerPositionSub?.cancel();
        _playerDurationSub?.cancel();
        _playerCompleteSub?.cancel();
        if (!_disposed) notifyListeners();
      }
    }
  }

  // ========================================
  // シーク（タップで再生位置を移動）
  // ========================================
  Future<void> seekTo(double progress) async {
    if (_playDuration == Duration.zero) return;
    final ms = (progress * _playDuration.inMilliseconds).round();
    final position = Duration(milliseconds: ms);
    await _audioService.seekTo(position);
    _playSeconds = position.inSeconds;
    if (!_disposed) notifyListeners();
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
    _disposed = true;
    _stopTimer();
    _playerPositionSub?.cancel();
    _playerDurationSub?.cancel();
    _playerCompleteSub?.cancel();
    _audioService.stopPlaying();
    super.dispose();
  }
}
