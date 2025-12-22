// ========================================
// アプリ全体で使用する定数
// ========================================
// 初学者向け説明：
// このファイルには、アプリ全体で共通して使う値を定義します
// 定数を一箇所にまとめることで、変更が必要な時に1箇所を修正するだけで済みます

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
