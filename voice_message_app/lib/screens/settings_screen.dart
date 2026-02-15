// ========================================
// アプリ設定画面
// ========================================
// 録音品質などのアプリケーション設定を管理する画面です

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recording_config.dart';

/// アプリケーション設定画面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  RecordingQuality _selectedQuality = RecordingQuality.medium;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// ========================================
  /// 設定を読み込む
  /// ========================================
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final qualityIndex =
        prefs.getInt('recording_quality') ?? 1; // デフォルト: medium

    setState(() {
      _selectedQuality = RecordingQuality.values[qualityIndex];
      _isLoading = false;
    });
  }

  /// ========================================
  /// 録音品質を保存
  /// ========================================
  Future<void> _saveQuality(RecordingQuality quality) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('recording_quality', quality.index);

    setState(() {
      _selectedQuality = quality;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('録音品質を保存しました')));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('設定'), elevation: 0),
      body: ListView(
        children: [
          // ========================================
          // 録音品質設定セクション
          // ========================================
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '録音設定',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '音声メッセージの録音品質を選択してください',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),

          const SizedBox(height: 16),

          // ========================================
          // 録音品質選択リスト
          // ========================================
          ...RecordingQuality.values.map((quality) {
            final config = RecordingConfig.fromQuality(quality);
            final isSelected = _selectedQuality == quality;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              elevation: isSelected ? 4 : 1,
              color: isSelected ? Colors.deepPurple.shade50 : null,
              child: ListTile(
                leading: Radio<RecordingQuality>(
                  value: quality,
                  groupValue: _selectedQuality,
                  onChanged: (value) {
                    if (value != null) {
                      _saveQuality(value);
                    }
                  },
                ),
                title: Text(
                  config.displayName,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(config.description),
                    const SizedBox(height: 4),
                    Text(
                      'サンプルレート: ${config.sampleRate}Hz | '
                      'ビットレート: ${config.bitRate ~/ 1000}kbps',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Text(
                      '推定ファイルサイズ: 約${config.estimatedSizePerMinute.toStringAsFixed(0)}KB/分',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                onTap: () => _saveQuality(quality),
              ),
            );
          }).toList(),

          const SizedBox(height: 24),

          // ========================================
          // 説明セクション
          // ========================================
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      '録音品質について',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '• 低品質：通話の録音に最適。データ通信量を節約できます。\n'
                  '• 中品質：バランスが良く、ほとんどの用途に適しています。（推奨）\n'
                  '• 高品質：音楽や高品質な録音が必要な場合に使用してください。',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
