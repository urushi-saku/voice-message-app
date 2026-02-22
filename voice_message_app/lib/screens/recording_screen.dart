// ========================================
// 録音画面（ボイスメッセージ送信用）
// ========================================

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/audio_service.dart';
import '../services/message_service.dart';
import '../models/recording_config.dart';

class RecordingScreen extends StatefulWidget {
  final List<String> recipientIds;
  final String? recipientUsername;
  final String? recipientProfileImage;

  const RecordingScreen({
    super.key,
    required this.recipientIds,
    this.recipientUsername,
    this.recipientProfileImage,
  });

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with TickerProviderStateMixin {
  bool _isRecording = false;
  bool _hasRecording = false;
  bool _isPlaying = false;
  bool _isSending = false;
  String? _recordedPath;
  String? _thumbnailPath;
  int _recordSeconds = 0;
  Timer? _timer;

  final AudioService _audioService = AudioService();
  final ImagePicker _imagePicker = ImagePicker();
  RecordingQuality _currentQuality = RecordingQuality.medium;

  // アニメーション
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late List<Animation<double>> _waveAnimations;

  @override
  void initState() {
    super.initState();
    _loadRecordingQuality();

    // 同心円パルス（録音中）
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // 波形バーアニメーション（再生中）
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    const barCount = 12;
    _waveAnimations = List.generate(barCount, (i) {
      final start = (i / barCount);
      final end = ((i + 0.6) / barCount).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(
          parent: _waveController,
          curve: Interval(start, end, curve: Curves.easeInOut),
        ),
      );
    });
  }

  Future<void> _loadRecordingQuality() async {
    final prefs = await SharedPreferences.getInstance();
    final qualityIndex = prefs.getInt('recording_quality') ?? 1;
    setState(() {
      _currentQuality = RecordingQuality.values[qualityIndex];
    });
    _audioService.setQuality(_currentQuality);
  }

  // ========================================
  // タイマー
  // ========================================
  void _startTimer() {
    _recordSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordSeconds++);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String get _timerText {
    final m = _recordSeconds ~/ 60;
    final s = _recordSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ========================================
  // 録音開始
  // ========================================
  Future<void> _startRecording() async {
    try {
      await _audioService.startRecording();
      _startTimer();
      setState(() {
        _isRecording = true;
        _hasRecording = false;
      });
    } catch (e) {
      _showError('マイクへのアクセスを許可してください');
    }
  }

  // ========================================
  // 録音停止
  // ========================================
  Future<void> _stopRecording() async {
    try {
      final path = await _audioService.stopRecording();
      _stopTimer();
      setState(() {
        _isRecording = false;
        _hasRecording = true;
        _recordedPath = path;
      });
    } catch (e) {
      _showError('録音の停止に失敗しました');
    }
  }

  // ========================================
  // 再録音
  // ========================================
  void _retake() {
    setState(() {
      _hasRecording = false;
      _recordedPath = null;
      _recordSeconds = 0;
    });
  }

  // ========================================
  // 再生 / 停止
  // ========================================
  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _audioService.stopPlaying();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _isPlaying = true);
      try {
        await _audioService.playLocal(_recordedPath!);
      } catch (_) {}
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  // ========================================
  // 送信
  // ========================================
  Future<void> _send() async {
    if (_recordedPath == null) return;
    setState(() => _isSending = true);
    try {
      await MessageService.sendMessage(
        voiceFile: File(_recordedPath!),
        receiverIds: widget.recipientIds,
        duration: _recordSeconds > 0 ? _recordSeconds : null,
        thumbnailFile: _thumbnailPath != null ? File(_thumbnailPath!) : null,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      // オフライン保存にフォールバックした場合（サーバー未接続など）
      if (e.toString().startsWith('offline:')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.cloud_off, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text('サーバーに接続できませんでした。\nネットワーク復帰後に自動送信されます。')),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
        // オフライン保存は成功なので画面を閉じる
        Navigator.pop(context);
        return;
      }
      _showError('送信エラー: $e');
    }
  }

  // ========================================
  // サムネイル選択
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
        setState(() => _thumbnailPath = image.path);
      }
    } catch (e) {
      _showError('画像選択エラー: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _stopTimer();
    _audioService.stopPlaying();
    super.dispose();
  }

  // ========================================
  // ビルド
  // ========================================
  @override
  Widget build(BuildContext context) {
    final recipientName = widget.recipientUsername ?? '送信先';
    final recipientImage = widget.recipientProfileImage;

    return Scaffold(
      backgroundColor: const Color(0xFF1A0050),
      appBar: _buildAppBar(recipientName, recipientImage),
      body: Column(
        children: [
          Expanded(child: _buildVisualArea()),
          _buildControlPanel(),
        ],
      ),
    );
  }

  // ========================================
  // AppBar
  // ========================================
  PreferredSizeWidget _buildAppBar(String name, String? imageUrl) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Colors.white,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withOpacity(0.25),
            backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
            child: imageUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'ボイスメッセージ',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // メインビジュアルエリア
  // ========================================
  Widget _buildVisualArea() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0050), Color(0xFF3A1080), Color(0xFF5C2DA8)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ステータスラベル
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _isRecording
                    ? '録音中'
                    : _hasRecording
                    ? '録音完了'
                    : '録音を開始',
                key: ValueKey('$_isRecording$_hasRecording'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.65),
                  letterSpacing: 3,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // サムネイル（録音中以外で表示）
            if (!_isRecording) _buildThumbnailPicker(),

            if (!_isRecording) const SizedBox(height: 20),

            // マイクボタン or 波形ビジュアル
            if (!_hasRecording) _buildMicButton() else _buildWaveformDisplay(),

            const SizedBox(height: 28),

            // タイマー
            AnimatedOpacity(
              opacity: (_isRecording || _hasRecording) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Text(
                _timerText,
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w200,
                  color: Colors.white,
                  letterSpacing: 6,
                ),
              ),
            ),

            if (!_isRecording && !_hasRecording) ...[
              const SizedBox(height: 52),
              Text(
                'マイクをタップして録音開始',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.45),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ========================================
  // サムネイルピッカー
  // ========================================
  Widget _buildThumbnailPicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _thumbnailPath != null
                ? Colors.purple.shade200
                : Colors.white.withOpacity(0.3),
            width: _thumbnailPath != null ? 2 : 1,
          ),
          boxShadow: _thumbnailPath != null
              ? [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: _thumbnailPath != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    kIsWeb
                        ? Image.network(_thumbnailPath!, fit: BoxFit.cover)
                        : Image.file(File(_thumbnailPath!), fit: BoxFit.cover),
                    // 変更ボタン
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 32,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'カバー',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ========================================
  // マイクボタン
  // ========================================
  Widget _buildMicButton() {
    return GestureDetector(
      onTap: _isRecording ? _stopRecording : _startRecording,
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 同心円パルス（録音中のみ）
            if (_isRecording)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      for (int i = 0; i < 3; i++)
                        _buildPulseRing((_pulseController.value + i / 3) % 1.0),
                    ],
                  );
                },
              ),

            // メインボタン
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _isRecording ? 88 : 80,
              height: _isRecording ? 88 : 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isRecording
                      ? [const Color(0xFFFF5252), const Color(0xFFD32F2F)]
                      : [const Color(0xFF9C6FFF), const Color(0xFF6C2FEF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        (_isRecording
                                ? const Color(0xFFFF5252)
                                : const Color(0xFF7C4DFF))
                            .withOpacity(0.55),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPulseRing(double progress) {
    final size = 88.0 + progress * 112;
    final opacity = (1.0 - progress) * 0.35;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFFF5252).withOpacity(opacity),
          width: 2,
        ),
      ),
    );
  }

  // ========================================
  // 録音完了後の波形ビジュアル
  // ========================================
  Widget _buildWaveformDisplay() {
    const barCount = 28;
    const barHeights = [
      18.0,
      28.0,
      22.0,
      38.0,
      30.0,
      50.0,
      42.0,
      60.0,
      48.0,
      55.0,
      38.0,
      62.0,
      44.0,
      58.0,
      36.0,
      50.0,
      40.0,
      56.0,
      32.0,
      46.0,
      38.0,
      28.0,
      42.0,
      30.0,
      22.0,
      34.0,
      20.0,
      16.0,
    ];

    return Container(
      width: 260,
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(barCount, (i) {
          final h = barHeights[i % barHeights.length];
          return AnimatedBuilder(
            animation: _waveController,
            builder: (_, __) {
              final scale = _isPlaying
                  ? _waveAnimations[i % _waveAnimations.length].value
                  : 1.0;
              return Container(
                width: 4,
                height: h * scale,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFF9C6FFF).withOpacity(0.5),
                      const Color(0xFFCE93D8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  // ========================================
  // コントロールパネル（下部白エリア）
  // ========================================
  Widget _buildControlPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 40),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _hasRecording
            ? _buildPostRecordControls()
            : _buildPreRecordInfo(),
      ),
    );
  }

  // ========================================
  // 録音前の情報パネル
  // ========================================
  Widget _buildPreRecordInfo() {
    final config = RecordingConfig.fromQuality(_currentQuality);
    return Column(
      key: const ValueKey('pre'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 14, color: Colors.grey[400]),
            const SizedBox(width: 6),
            Text(
              '録音中にボタンをタップすると停止します',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3EDFF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.graphic_eq, size: 16, color: Color(0xFF7C4DFF)),
              const SizedBox(width: 6),
              Text(
                '録音品質: ${config.displayName}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7C4DFF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ========================================
  // 録音後のコントロール
  // ========================================
  Widget _buildPostRecordControls() {
    return Column(
      key: const ValueKey('post'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // 再生ボタン（大）
        GestureDetector(
          onTap: _togglePlay,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF9C6FFF), Color(0xFF6C2FEF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C4DFF).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _isPlaying ? '再生中...' : '確認再生',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),

        const SizedBox(height: 28),

        // 撮り直す & 送信
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSending ? null : _retake,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('撮り直す'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey[300]!),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _send,
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(_isSending ? '送信中...' : '送信する'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C4DFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 4,
                  shadowColor: const Color(0xFF7C4DFF).withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
