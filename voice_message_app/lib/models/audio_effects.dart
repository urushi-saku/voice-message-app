// ========================================
// 音声エフェクトモデル
// ========================================
// 初学者向け説明：
// このファイルは、音声再生に適用できるエフェクト設定を管理します。
// 音量、再生速度、エコー/リバーブ、ピッチ変更の設定を保持します。

/// 音声エフェクトの設定を保持するクラス
class AudioEffects {
  // ========================================
  // エフェクトパラメータ
  // ========================================

  /// 音量（0.0 ～ 2.0、デフォルト 1.0）
  final double volume;

  /// 再生速度（0.5 ～ 2.0、デフォルト 1.0）
  final double playbackSpeed;

  /// エコーの有効/無効
  final bool echoEnabled;

  /// エコー強度（0.0 ～ 1.0、デフォルト 0.3）
  final double echoIntensity;

  /// リバーブの有効/無効
  final bool reverbEnabled;

  /// リバーブ強度（0.0 ～ 1.0、デフォルト 0.3）
  final double reverbIntensity;

  /// ピッチ変更タイプ
  final PitchType pitchType;

  // ========================================
  // コンストラクタ
  // ========================================
  const AudioEffects({
    this.volume = 1.0,
    this.playbackSpeed = 1.0,
    this.echoEnabled = false,
    this.echoIntensity = 0.3,
    this.reverbEnabled = false,
    this.reverbIntensity = 0.3,
    this.pitchType = PitchType.normal,
  });

  /// デフォルト設定（エフェクトなし）
  static const AudioEffects defaultEffects = AudioEffects();

  // ========================================
  // コピーメソッド（一部だけ変更したい場合に使用）
  // ========================================
  AudioEffects copyWith({
    double? volume,
    double? playbackSpeed,
    bool? echoEnabled,
    double? echoIntensity,
    bool? reverbEnabled,
    double? reverbIntensity,
    PitchType? pitchType,
  }) {
    return AudioEffects(
      volume: volume ?? this.volume,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      echoEnabled: echoEnabled ?? this.echoEnabled,
      echoIntensity: echoIntensity ?? this.echoIntensity,
      reverbEnabled: reverbEnabled ?? this.reverbEnabled,
      reverbIntensity: reverbIntensity ?? this.reverbIntensity,
      pitchType: pitchType ?? this.pitchType,
    );
  }

  // ========================================
  // 表示用ヘルパー
  // ========================================

  /// 再生速度のラベルを返す（例："1.5x"）
  String get speedLabel => '${playbackSpeed.toStringAsFixed(1)}x';

  /// 音量のパーセント表示を返す（例："100%"）
  String get volumePercent => '${(volume * 100).round()}%';

  /// エフェクトが何か適用されているか
  bool get hasEffects =>
      volume != 1.0 ||
      playbackSpeed != 1.0 ||
      echoEnabled ||
      reverbEnabled ||
      pitchType != PitchType.normal;
}

// ========================================
// ピッチタイプの列挙（ボイスチェンジャー）
// ========================================
/// 声のキャラクターを変えるピッチ設定
enum PitchType {
  /// 変更なし
  normal,

  /// 高い声（子供・女性っぽく）
  high,

  /// 低い声（男性・怪物っぽく）
  low,

  /// ロボット声
  robot,

  /// ヘリウム声（極端に高い）
  chipmunk,
}

/// PitchTypeの情報を提供する拡張
extension PitchTypeExtension on PitchType {
  /// 表示名
  String get label {
    switch (this) {
      case PitchType.normal:
        return 'ノーマル';
      case PitchType.high:
        return '高い声';
      case PitchType.low:
        return '低い声';
      case PitchType.robot:
        return 'ロボット';
      case PitchType.chipmunk:
        return 'ヘリウム';
    }
  }

  /// アイコン
  String get emoji {
    switch (this) {
      case PitchType.normal:
        return '🎤';
      case PitchType.high:
        return '🔼';
      case PitchType.low:
        return '🔽';
      case PitchType.robot:
        return '🤖';
      case PitchType.chipmunk:
        return '🎈';
    }
  }

  /// audioplayers の pitch 係数（再生速度で代替）
  double get pitchFactor {
    switch (this) {
      case PitchType.normal:
        return 1.0;
      case PitchType.high:
        return 1.3;
      case PitchType.low:
        return 0.75;
      case PitchType.robot:
        return 1.0; // ロボット効果はUI側でビジュアル表現
      case PitchType.chipmunk:
        return 1.6;
    }
  }
}
