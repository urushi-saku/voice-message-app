// ========================================
// 音声エフェクトパネルウィジェット
// ========================================
// 初学者向け説明：
// このファイルは、音声再生画面に表示するエフェクト操作UIをまとめたウィジェットです。
// 音量、再生速度、エコー、リバーブ、ボイスチェンジャーの各コントロールを提供します。

import 'package:flutter/material.dart';
import '../models/audio_effects.dart';

/// 音声エフェクト操作パネル
///
/// 使い方:
/// ```dart
/// AudioEffectsPanel(
///   effects: _currentEffects,
///   onEffectsChanged: (newEffects) {
///     setState(() => _currentEffects = newEffects);
///   },
/// )
/// ```
class AudioEffectsPanel extends StatelessWidget {
  /// 現在のエフェクト設定
  final AudioEffects effects;

  /// エフェクトが変更されたときのコールバック
  final ValueChanged<AudioEffects> onEffectsChanged;

  const AudioEffectsPanel({
    super.key,
    required this.effects,
    required this.onEffectsChanged,
  });

  // ========================================
  // ウィジェット構築
  // ========================================
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========== ヘッダー ==========
          _buildHeader(context),
          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ========== 音量調整 ==========
                _buildVolumeSection(),
                const SizedBox(height: 20),

                // ========== 再生速度 ==========
                _buildSpeedSection(),
                const SizedBox(height: 20),

                // ========== エコー/リバーブ ==========
                _buildReverbEchoSection(),
                const SizedBox(height: 20),

                // ========== ボイスチェンジャー ==========
                _buildVoiceChangerSection(),
                const SizedBox(height: 12),

                // ========== リセットボタン ==========
                if (effects.hasEffects) _buildResetButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------
  // ヘッダー
  // ----------------------------------------
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.tune, size: 20, color: Colors.deepPurple),
          const SizedBox(width: 8),
          Text(
            '音声エフェクト',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          if (effects.hasEffects) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ON',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ----------------------------------------
  // 音量調整セクション
  // ----------------------------------------
  Widget _buildVolumeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.volume_up, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              '音量',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const Spacer(),
            Text(
              effects.volumePercent,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: _sliderTheme(),
          child: Slider(
            min: 0.0,
            max: 2.0,
            divisions: 20,
            value: effects.volume,
            onChanged: (value) {
              onEffectsChanged(effects.copyWith(volume: value));
            },
          ),
        ),
        // 音量ラベル
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0%', style: _labelStyle()),
            Text('100%', style: _labelStyle()),
            Text('200%', style: _labelStyle()),
          ],
        ),
      ],
    );
  }

  // ----------------------------------------
  // 再生速度セクション
  // ----------------------------------------
  Widget _buildSpeedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.speed, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              '再生速度',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const Spacer(),
            Text(
              effects.speedLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // 速度プリセットボタン
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
            final isSelected = (effects.playbackSpeed - speed).abs() < 0.01;
            return GestureDetector(
              onTap: () {
                onEffectsChanged(effects.copyWith(playbackSpeed: speed));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.deepPurple : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${speed}x',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: _sliderTheme(),
          child: Slider(
            min: 0.5,
            max: 2.0,
            divisions: 15,
            value: effects.playbackSpeed,
            onChanged: (value) {
              onEffectsChanged(effects.copyWith(playbackSpeed: value));
            },
          ),
        ),
      ],
    );
  }

  // ----------------------------------------
  // エコー/リバーブセクション
  // ----------------------------------------
  Widget _buildReverbEchoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'エフェクト',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 10),

        // エコー
        _buildEffectToggleRow(
          icon: Icons.graphic_eq,
          label: 'エコー',
          emoji: '🏔️',
          enabled: effects.echoEnabled,
          intensity: effects.echoIntensity,
          onToggle: (enabled) {
            onEffectsChanged(effects.copyWith(echoEnabled: enabled));
          },
          onIntensityChanged: (value) {
            onEffectsChanged(effects.copyWith(echoIntensity: value));
          },
        ),
        const SizedBox(height: 10),

        // リバーブ
        _buildEffectToggleRow(
          icon: Icons.waves,
          label: 'リバーブ',
          emoji: '🏟️',
          enabled: effects.reverbEnabled,
          intensity: effects.reverbIntensity,
          onToggle: (enabled) {
            onEffectsChanged(effects.copyWith(reverbEnabled: enabled));
          },
          onIntensityChanged: (value) {
            onEffectsChanged(effects.copyWith(reverbIntensity: value));
          },
        ),
      ],
    );
  }

  /// エフェクトのON/OFF + 強度スライダー行
  Widget _buildEffectToggleRow({
    required IconData icon,
    required String label,
    required String emoji,
    required bool enabled,
    required double intensity,
    required ValueChanged<bool> onToggle,
    required ValueChanged<double> onIntensityChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: enabled ? Colors.deepPurple : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              '$emoji $label',
              style: TextStyle(
                fontSize: 13,
                color: enabled ? Colors.deepPurple : Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            Switch(
              value: enabled,
              activeThumbColor: Colors.deepPurple,
              activeTrackColor: Colors.deepPurple.shade200,
              onChanged: onToggle,
            ),
          ],
        ),
        if (enabled) ...[
          Row(
            children: [
              const SizedBox(width: 26),
              Expanded(
                child: SliderTheme(
                  data: _sliderTheme(),
                  child: Slider(
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    value: intensity,
                    onChanged: onIntensityChanged,
                  ),
                ),
              ),
              Text(
                '${(intensity * 100).round()}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ----------------------------------------
  // ボイスチェンジャーセクション
  // ----------------------------------------
  Widget _buildVoiceChangerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ボイスチェンジャー',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PitchType.values.map((pitch) {
            final isSelected = effects.pitchType == pitch;
            return ChoiceChip(
              label: Text('${pitch.emoji} ${pitch.label}'),
              selected: isSelected,
              selectedColor: Colors.deepPurple.shade100,
              onSelected: (_) {
                onEffectsChanged(effects.copyWith(pitchType: pitch));
              },
              labelStyle: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.deepPurple : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
              ),
              backgroundColor: Colors.white,
            );
          }).toList(),
        ),
        if (effects.pitchType != PitchType.normal) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Colors.deepPurple,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'ピッチ係数: ${effects.pitchType.pitchFactor}x（再生速度と組み合わせで適用）',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ----------------------------------------
  // リセットボタン
  // ----------------------------------------
  Widget _buildResetButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.refresh, size: 16),
        label: const Text('エフェクトをリセット', style: TextStyle(fontSize: 13)),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey.shade600,
          side: BorderSide(color: Colors.grey.shade400),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        onPressed: () {
          onEffectsChanged(AudioEffects.defaultEffects);
        },
      ),
    );
  }

  // ----------------------------------------
  // ヘルパー
  // ----------------------------------------
  SliderThemeData _sliderTheme() {
    return SliderThemeData(
      activeTrackColor: Colors.deepPurple,
      inactiveTrackColor: Colors.deepPurple.shade100,
      thumbColor: Colors.deepPurple,
      overlayColor: Colors.deepPurple.withValues(alpha: 0.1),
      trackHeight: 3,
    );
  }

  TextStyle _labelStyle() {
    return TextStyle(fontSize: 10, color: Colors.grey.shade500);
  }
}
