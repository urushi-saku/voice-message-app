// ========================================
// 録音画面（ボイスメッセージ送信用）
// ========================================
// 【責務】
// - 録音・再生のアニメーション表示（UI）
// - AppBar・ビジュアルエリア・コントロールパネルのレイアウト
// - 送信結果に応じた SnackBar 表示 / 画面遷移
//
// 【委譲先】
// - RecordingProvider : 録音・再生・送信のビジネスロジック・状態管理

import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/recording_provider.dart';
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
  // ========================================
  // ビジネスロジック（Provider）
  // ========================================
  late final RecordingProvider _provider;

  // ========================================
  // UI 専用: アニメーション
  // ========================================
  late AnimationController _pulseController; // 同心円パルス（録音中）

  final ImagePicker _imagePicker = ImagePicker();

  // ========================================
  // ライフサイクル
  // ========================================
  @override
  void initState() {
    super.initState();

    // Provider 生成・変更通知を受けて setState
    _provider = RecordingProvider();
    _provider.addListener(_onProviderChanged);
    _provider.loadRecordingQuality();

    // 同心円パルス（録音中に repeat）
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  void _onProviderChanged() {
    if (mounted) {
      setState(() {});
      // エラーが発生した場合は SnackBar 表示
      if (_provider.error != null) {
        _showError(_provider.error!);
      }
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    _provider.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ========================================
  // 音声ファイル選択（UI操作のため Screen に残す）
  // ========================================
  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'aac', 'wav', 'ogg', 'flac', 'opus'],
      );
      if (result != null && result.files.single.path != null) {
        _provider.setFromFile(result.files.single.path!);
      }
    } catch (e) {
      _showError('ファイル選択エラー: $e');
    }
  }

  // ========================================
  // サムネイル選択（UI 操作のため Screen に残す）
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
        _provider.setThumbnailPath(image.path);
      }
    } catch (e) {
      _showError('画像選択エラー: $e');
    }
  }

  // ========================================
  // 送信（結果ハンドリングは Screen、ロジックは Provider）
  // ========================================
  Future<void> _send() async {
    try {
      await _provider.send(widget.recipientIds);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      // オフライン保存にフォールバックした場合
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
        Navigator.pop(context);
        return;
      }
      _showError('送信エラー: $e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
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
                _provider.isRecording
                    ? '録音中'
                    : _provider.hasRecording
                    ? (_provider.isFromFile ? 'ファイル選択済み' : '録音完了')
                    : '録音を開始',
                key: ValueKey(
                  '${_provider.isRecording}${_provider.hasRecording}',
                ),
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
            if (!_provider.isRecording) _buildThumbnailPicker(),
            if (!_provider.isRecording) const SizedBox(height: 20),

            // マイクボタン or 波形ビジュアル
            if (!_provider.hasRecording)
              _buildMicButton()
            else
              _buildWaveformDisplay(),
            // 録音中はリアルタイム波形を下に表示
            if (_provider.isRecording && _provider.waveformData.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: 280,
                height: 48,
                child: CustomPaint(
                  painter: _WaveformPainter(
                    samples: _provider.waveformData,
                    progress: 0.0,
                  ),
                ),
              ),
            ],
            // ファイル選択ボタン（録音前のみ表示）
            if (!_provider.hasRecording && !_provider.isRecording) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickAudioFile,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.upload_file_rounded,
                        size: 18,
                        color: Colors.white.withOpacity(0.85),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ファイルを選択',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),

            // タイマー
            AnimatedOpacity(
              opacity: (_provider.isRecording || _provider.hasRecording)
                  ? 1.0
                  : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Text(
                _provider.timerText,
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w200,
                  color: Colors.white,
                  letterSpacing: 6,
                ),
              ),
            ),

            if (!_provider.isRecording && !_provider.hasRecording) ...[
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
    final thumbnailPath = _provider.thumbnailPath;
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
            color: thumbnailPath != null
                ? Colors.purple.shade200
                : Colors.white.withOpacity(0.3),
            width: thumbnailPath != null ? 2 : 1,
          ),
          boxShadow: thumbnailPath != null
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
          child: thumbnailPath != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    kIsWeb
                        ? Image.network(thumbnailPath, fit: BoxFit.cover)
                        : Image.file(File(thumbnailPath), fit: BoxFit.cover),
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
  // マイクボタン（録音前）
  // ========================================
  Widget _buildMicButton() {
    return GestureDetector(
      onTap: _provider.isRecording
          ? _provider.stopRecording
          : _provider.startRecording,
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 同心円パルス（録音中のみ）
            if (_provider.isRecording)
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
              width: _provider.isRecording ? 88 : 80,
              height: _provider.isRecording ? 88 : 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _provider.isRecording
                      ? [const Color(0xFFFF5252), const Color(0xFFD32F2F)]
                      : [const Color(0xFF9C6FFF), const Color(0xFF6C2FEF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        (_provider.isRecording
                                ? const Color(0xFFFF5252)
                                : const Color(0xFF7C4DFF))
                            .withOpacity(0.55),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                _provider.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
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
  // 録音完了後の波形ビジュアル（実波形 + 再生進捗）
  // ========================================
  Widget _buildWaveformDisplay() {
    const w = 280.0;
    const h = 80.0;
    return GestureDetector(
      // タップ / ドラッグでシーク
      onTapDown: (d) =>
          _provider.seekTo((d.localPosition.dx / w).clamp(0.0, 1.0)),
      onHorizontalDragUpdate: (d) =>
          _provider.seekTo((d.localPosition.dx / w).clamp(0.0, 1.0)),
      child: SizedBox(
        width: w,
        height: h,
        child: CustomPaint(
          painter: _WaveformPainter(
            samples: _provider.waveformData,
            progress: _provider.playProgress,
          ),
        ),
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
        child: _provider.hasRecording
            ? _buildPostRecordControls()
            : _buildPreRecordInfo(),
      ),
    );
  }

  // ========================================
  // 録音前の情報パネル
  // ========================================
  Widget _buildPreRecordInfo() {
    final config = RecordingConfig.fromQuality(_provider.currentQuality);
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
        // ファイルアップロード時のファイル名表示
        if (_provider.isFromFile) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.audio_file_rounded,
                size: 16,
                color: Colors.deepPurple[300],
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _provider.recordedPath?.split('/').last ?? 'audio file',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        // 再生ボタン
        GestureDetector(
          onTap: _provider.togglePlay,
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
              _provider.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _provider.isPlaying ? '再生中...' : '確認再生',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),

        const SizedBox(height: 28),

        // 撮り直す & 送信
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _provider.isSending ? null : _provider.retake,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(_provider.isFromFile ? '選び直す' : '撮り直す'),
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
                onPressed: _provider.isSending ? null : _send,
                icon: _provider.isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(_provider.isSending ? '送信中...' : '送信する'),
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

// ============================================================
// 波形 CustomPainter
// ============================================================
/// 録音時にサンプリングした振幅データを棒グラフ形式で描画する。
/// [progress] 0.0〜1.0 で再生済み部分を紫、未再生をグレーで塗り分ける。
class _WaveformPainter extends CustomPainter {
  final List<double> samples;
  final double progress;

  static const _barCount = 44;
  static const _barWidth = 3.0;
  static const _minHeight = 3.0;

  const _WaveformPainter({required this.samples, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final resampled = _resample(samples, _barCount);
    final gap = (size.width - _barCount * _barWidth) / (_barCount + 1);
    final cy = size.height / 2;

    final playedPaint = Paint()
      ..color = const Color.fromARGB(255, 145, 95, 254)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _barWidth;

    final unplayedPaint = Paint()
      ..color = Colors.white.withOpacity(0.38)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _barWidth;

    for (int i = 0; i < _barCount; i++) {
      final x = gap * (i + 1) + _barWidth * i + _barWidth / 2;
      final h = (_minHeight + resampled[i] * (size.height - _minHeight)).clamp(
        _minHeight,
        size.height,
      );
      final played = i / _barCount < progress;
      final paint = played ? playedPaint : unplayedPaint;
      canvas.drawLine(Offset(x, cy - h / 2), Offset(x, cy + h / 2), paint);
    }
  }

  /// [data] を [count] 本にリサンプリング（ブロック平均）
  List<double> _resample(List<double> data, int count) {
    if (data.isEmpty) {
      // データなし → 両端が低く中央が高い山型を返す
      return List.generate(count, (i) {
        final env = math.sin(i / (count - 1) * math.pi);
        return 0.08 + env * 0.35;
      });
    }
    if (data.length <= count) {
      // データが少ない場合はそのまま（右埋め）
      return [...data, ...List.filled(count - data.length, data.last)];
    }
    // ブロック平均でダウンサンプリング
    final blockSize = data.length / count;
    return List.generate(count, (i) {
      final start = (i * blockSize).floor();
      final end = ((i + 1) * blockSize).ceil().clamp(start + 1, data.length);
      final slice = data.sublist(start, end);
      return slice.reduce((a, b) => a + b) / slice.length;
    });
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress || old.samples.length != samples.length;
}
