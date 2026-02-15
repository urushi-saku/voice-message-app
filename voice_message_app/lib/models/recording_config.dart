// ========================================
// 録音設定モデル
// ========================================
// 音声録音の品質設定を管理するモデルです

/// 録音品質の列挙型
enum RecordingQuality {
  low, // 低品質（小さいファイルサイズ）
  medium, // 中品質（バランス）
  high, // 高品質（大きいファイルサイズ）
}

/// 録音品質設定クラス
class RecordingConfig {
  final RecordingQuality quality;
  final int sampleRate;
  final int bitRate;

  const RecordingConfig({
    required this.quality,
    required this.sampleRate,
    required this.bitRate,
  });

  /// 品質レベルに応じた設定を取得
  factory RecordingConfig.fromQuality(RecordingQuality quality) {
    switch (quality) {
      case RecordingQuality.low:
        return const RecordingConfig(
          quality: RecordingQuality.low,
          sampleRate: 16000, // 16kHz
          bitRate: 32000, // 32kbps
        );
      case RecordingQuality.medium:
        return const RecordingConfig(
          quality: RecordingQuality.medium,
          sampleRate: 22050, // 22.05kHz
          bitRate: 64000, // 64kbps
        );
      case RecordingQuality.high:
        return const RecordingConfig(
          quality: RecordingQuality.high,
          sampleRate: 44100, // 44.1kHz (CD品質)
          bitRate: 128000, // 128kbps
        );
    }
  }

  /// 品質の表示名を取得
  String get displayName {
    switch (quality) {
      case RecordingQuality.low:
        return '低品質（小）';
      case RecordingQuality.medium:
        return '中品質（標準）';
      case RecordingQuality.high:
        return '高品質（大）';
    }
  }

  /// 品質の説明を取得
  String get description {
    switch (quality) {
      case RecordingQuality.low:
        return 'ファイルサイズ: 小、音質: 基本的な会話向け';
      case RecordingQuality.medium:
        return 'ファイルサイズ: 中、音質: 標準的な録音（推奨）';
      case RecordingQuality.high:
        return 'ファイルサイズ: 大、音質: 高品質録音（音楽向け）';
    }
  }

  /// 推定ファイルサイズを取得（1分あたりのKB）
  double get estimatedSizePerMinute {
    // ビットレート（bps）を分に変換し、KBに変換
    // bitRate / 8 (ビット→バイト) * 60 (秒) / 1024 (KB)
    return (bitRate / 8 * 60) / 1024;
  }
}
