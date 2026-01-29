// ========================================
// アプリ全体で使用する定数
// ========================================
// 初学者向け説明：
// このファイルには、アプリ全体で共通して使う値を定義します
// 定数を一箇所にまとめることで、変更が必要な時に1箇所を修正するだけで済みます

import 'package:flutter/material.dart';

/// バックエンドサーバーのベースURL
/// 開発環境: localhost:3000
/// 本番環境に移行する際は、実際のサーバーURLに変更してください
const String kServerUrl = 'http://localhost:3000';

/// アップロードエンドポイント
const String kUploadEndpoint = '/upload';

/// 音声リスト取得エンドポイント
const String kVoicesEndpoint = '/voices';

/// 音声ファイル取得エンドポイント（ファイル名を後ろに付ける）
const String kVoiceEndpoint = '/voice';

// ========================================
// テーマ設定（サムネイル用）
// ========================================
class VoiceTheme {
  final String id;
  final String name;
  final Color color;
  final IconData icon;

  const VoiceTheme({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });
}

/// 利用可能なテーマのリスト
const List<VoiceTheme> kVoiceThemes = [
  VoiceTheme(
    id: 'blue',
    name: 'ブルー',
    color: Colors.blue,
    icon: Icons.mic,
  ),
  VoiceTheme(
    id: 'red',
    name: 'レッド',
    color: Colors.red,
    icon: Icons.favorite,
  ),
  VoiceTheme(
    id: 'green',
    name: 'グリーン',
    color: Colors.green,
    icon: Icons.nature,
  ),
  VoiceTheme(
    id: 'orange',
    name: 'オレンジ',
    color: Colors.orange,
    icon: Icons.music_note,
  ),
  VoiceTheme(
    id: 'purple',
    name: 'パープル',
    color: Colors.purple,
    icon: Icons.star,
  ),
];

/// IDからテーマを取得するヘルパー関数
VoiceTheme getThemeById(String id) {
  return kVoiceThemes.firstWhere(
    (theme) => theme.id == id,
    orElse: () => kVoiceThemes[0], // 見つからない場合はデフォルト（ブルー）
  );
}
