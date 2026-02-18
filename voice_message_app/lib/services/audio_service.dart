// ========================================
// オーディオサービス - 録音と再生を管理
// ========================================
// 初学者向け説明：
// このファイルは、音声の録音と再生に関するロジックをすべて管理します
// 録音や再生の複雑な処理をここに集約することで、UIのコードがシンプルになります

import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../models/recording_config.dart';
import '../models/audio_effects.dart';

/// 音声の録音と再生を担当するサービスクラス
class AudioService {
  // ========================================
  // プライベート変数（内部で使用）
  // ========================================
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  String? _recordingPath; // 録音中のファイルのパス
  bool _isRecording = false; // 録音中かどうか
  RecordingQuality _quality = RecordingQuality.medium; // デフォルト品質
  AudioEffects _effects = AudioEffects.defaultEffects; // 音声エフェクト設定

  // ========================================
  // ゲッター（状態を外部から取得）
  // ========================================
  bool get isRecording => _isRecording;
  String? get recordingPath => _recordingPath;
  RecordingQuality get quality => _quality;
  AudioEffects get effects => _effects;

  // ========================================
  // 録音品質を設定
  // ========================================
  /// 録音品質を設定します
  ///
  /// パラメータ:
  ///   - quality: 設定する品質レベル
  void setQuality(RecordingQuality quality) {
    _quality = quality;
  }

  // ========================================
  // 音声エフェクトを設定
  // ========================================
  /// 音声エフェクト全体を設定します
  ///
  /// パラメータ:
  ///   - effects: 適用するエフェクト設定
  Future<void> setEffects(AudioEffects effects) async {
    _effects = effects;
    await _applyEffectsToPlayer();
  }

  /// エフェクトをリセット（デフォルトに戻す）
  Future<void> resetEffects() async {
    _effects = AudioEffects.defaultEffects;
    await _applyEffectsToPlayer();
  }

  /// 現在のプレイヤーにエフェクトを適用（内部メソッド）
  Future<void> _applyEffectsToPlayer() async {
    try {
      // 音量を適用
      await _player.setVolume(_effects.volume);

      // 再生速度を適用（ピッチタイプによって速度を調整）
      final speedWithPitch =
          _effects.playbackSpeed * _effects.pitchType.pitchFactor;
      await _player.setPlaybackRate(speedWithPitch.clamp(0.5, 2.0));
    } catch (e) {
      print('エフェクト適用エラー: $e');
    }
  }

  // ========================================
  // 録音を開始
  // ========================================
  /// 音声の録音を開始します
  ///
  /// 戻り値:
  ///   - true: 録音開始成功
  ///   - false: 録音開始失敗（権限がない、既に録音中など）
  Future<bool> startRecording() async {
    if (_isRecording) {
      return false; // すでに録音中
    }

    try {
      // マイク権限をチェック
      if (await _recorder.hasPermission()) {
        // 保存先のディレクトリを取得
        final directory = await getApplicationDocumentsDirectory();

        // ファイル名を生成（現在時刻をミリ秒で）
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        _recordingPath = '${directory.path}/voice_$timestamp.m4a';

        // 録音品質設定を取得
        final config = RecordingConfig.fromQuality(_quality);

        // 録音を開始（品質設定を適用）
        await _recorder.start(
          RecordConfig(
            encoder: AudioEncoder.aacLc,
            sampleRate: config.sampleRate,
            bitRate: config.bitRate,
          ),
          path: _recordingPath!,
        );

        _isRecording = true;
        return true;
      }

      return false;
    } catch (e) {
      print('録音開始エラー: $e');
      return false;
    }
  }

  // ========================================
  // 録音を停止
  // ========================================
  /// 音声の録音を停止します
  ///
  /// 戻り値: 録音されたファイルのパス（録音していない場合はnull）
  Future<String?> stopRecording() async {
    if (!_isRecording) {
      return null; // 録音していない
    }

    try {
      final path = await _recorder.stop();
      _isRecording = false;
      return path;
    } catch (e) {
      print('録音停止エラー: $e');
      _isRecording = false;
      return null;
    }
  }

  // ========================================
  // ローカル音声ファイルを再生
  // ========================================
  /// 録音した音声ファイルをローカルで再生します
  ///
  /// パラメータ:
  ///   - path: 再生する音声ファイルのパス
  Future<void> playLocal(String path) async {
    try {
      await _player.play(DeviceFileSource(path));
      await _applyEffectsToPlayer();
    } catch (e) {
      print('ローカル再生エラー: $e');
    }
  }

  // ========================================
  // サーバー上の音声ファイルを再生
  // ========================================
  /// サーバーにアップロードされた音声ファイルを再生します
  ///
  /// パラメータ:
  ///   - url: 音声ファイルのURL
  Future<void> playRemote(String url) async {
    try {
      await _player.play(UrlSource(url));
      await _applyEffectsToPlayer();
    } catch (e) {
      print('リモート再生エラー: $e');
    }
  }

  // ========================================
  // 再生を停止
  // ========================================
  /// 現在再生中の音声を停止します
  Future<void> stopPlaying() async {
    try {
      await _player.stop();
    } catch (e) {
      print('再生停止エラー: $e');
    }
  }

  // ========================================
  // リソースを解放
  // ========================================
  /// サービスを破棄する際に呼び出してリソースを解放します
  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}
