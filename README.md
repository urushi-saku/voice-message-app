# ボイスメッセージ送受信アプリ

Flutter製モバイルアプリとNode.js（Express）+ MongoDB バックエンドで構成される、フルスタック音声メッセージングアプリです。

## 🎯 プロジェクト概要

ユーザー認証、フォロー機能、音声メッセージの録音・送信・受信・再生、既読管理など、SNS的な機能を備えた音声コミュニケーションアプリケーションです。

## 📁 ディレクトリ構成

- **voice_message_app/** : Flutterモバイルアプリ（iOS/Android対応）
- **backend/** : Node.js + Express + MongoDB APIサーバー
- **README.md** : このファイル
- **PROJECT_STRUCTURE_AND_ROADMAP.txt** : 詳細な技術仕様とロードマップ

## 📈 プロジェクト進捗

- **フェーズ1（データベース連携＆認証）**: ✅ 完了
- **フェーズ2（フォロワー機能強化）**: ✅ 完了
- **フェーズ3（メッセージング機能強化）**: ✅ **完了** 🎉
- **フェーズ4（高度な機能）**: ✅ **完了**（オフラインモード、プロフィール機能、録音品質設定）
- **フェーズ6（UI/UX改善）**: ✅ **完了**（ダークモード、アニメーション、アクセシビリティ、レスポンシブ）
- **フェーズ5・7**: 未着手

## ✨ 実装済み機能

### 🔐 認証・ユーザー管理

- **ユーザー登録・ログイン**
  - JWT トークンベース認証
  - bcrypt によるパスワード暗号化
  - トークンの永続化（shared_preferences）
  - 自動ログイン機能

- **ユーザー検索**
  - リアルタイム検索（500msデバウンス）
  - 部分一致検索
  - 自分自身を除外

- **フォロー機能**
  - ユーザーのフォロー/アンフォロー
  - フォロワー一覧表示
  - フォロー中一覧表示
  - 自動フォロワーカウント管理
  - 重複フォロー防止

### 🎤 音声メッセージング

- **録音機能**
  - マイク権限管理
  - 音声録音（record パッケージ）
  - リアルタイム録音時間表示
  - m4a形式での保存

- **メッセージ送信**
  - 複数受信者への同時送信
  - フォロー中ユーザーからの選択
  - MultipartRequest でのファイル送信
  - 送信成功通知

- **メッセージ受信**
  - 受信メッセージ一覧表示
  - 既読/未読管理
  - 相対時間表示（「5分前」など、timeago）
  - NEWバッジと赤い点による未読表示
  - 送信者プロフィール情報表示

- **メッセージ操作**
  - スワイプで削除（確認ダイアログ付き）
  - ローカルファイル物理削除（デバイスキャッシュクリア）
  - サーバーファイル物理削除（全ユーザー削除時）
  - 既読マーク（再生時自動）
  - プルダウンで更新
  - メッセージ検索（送信者名）
  - 既読/未読フィルター
  - 日付範囲フィルター

- **プッシュ通知（Firebase Cloud Messaging）** 🆕
  - メッセージ受信時のリアルタイム通知
  - バックグラウンド通知対応
  - 通知タップでアプリ起動
  - FCMトークン自動管理
  - ログアウト時の通知停止

- **メッセージスレッド機能**
  - 送信者別のメッセージスレッド管理
  - スレッド一覧画面（未読バッジ、最新メッセージ表示）
  - スレッド詳細画面
  - リスト表示 ↔ カード表示の切り替え
  - ボイスカード（グラデーション背景、送信者情報付き）

### 👤 プロフィール機能

- **プロフィール表示**
  - ユーザー情報表示（ユーザー名、自己紹介、プロフィール画像）
  - フォロワー数・フォロー中数表示
  - ログアウト機能

- **プロフィール編集** 🆕
  - ユーザー名編集
  - 自己紹介編集
  - プロフィール画像選択・アップロード
  - リアルタイムプレビュー
  - バリデーション機能

### 🎙️ 録音品質設定 🆕

- **品質レベル選択**
  - 低品質（16kHz、32kbps）
  - 中品質（22.05kHz、64kbps）- デフォルト
  - 高品質（44.1kHz、128kbps）

- **設定画面**
  - 品質説明表示
  - 推定ファイルサイズ表示
  - SharedPreferences による永続化

### 🌓 UI/UX改善 🆕

- **テーマカスタマイズ**
  - ダークモード / ライトモード
  - Material Design 3 準拠
  - リアルタイムテーマ切り替え
  - 設定の永続化

- **アニメーション強化**
  - ページ遷移（SlideUp / FadeSlide / ScaleFade）
  - ローディング表示（パルス・回転）
  - ウィジェットエフェクト（SlideIn・PulseInfinity）
  - ボタンタップ効果（スケール 0.95倍）

- **アクセシビリティ改善**
  - スクリーンリーダー対応（Semantics）
  - 最小タッチサイズ確保（48×48dp）
  - 高コントラストモード対応
  - スキップナビゲーション

- **レスポンシブデザイン**
  - Mobile / Tablet / Desktop 対応
  - 画面向き（縦/横）対応
  - テキスト・パディング自動スケール
  - グリッドレイアウト自動調整

### 📱 オフラインモード 🆕

- **ネットワーク接続状態監視**
  - リアルタイム接続状態検出
  - オフラインバナー表示
  - 接続詳細情報表示

- **オフラインメッセージ管理**
  - 接続なしでメッセージ作成・保存
  - ネットワーク復帰時の自動同期
  - 同期失敗時の再試行

- **ローカルキャッシュ**
  - Hive を使用したデータ永続化
  - ユーザー情報キャッシュ
  - メッセージ情報キャッシュ
  - フォロー情報キャッシュ

- **同期統計**
  - 同期状態の表示
  - 待機メッセージ数
  - 最終同期時刻

- **音声再生**
  - 認証付きファイルダウンロード
  - ローカルキャッシュ再生
  - 再生コントロール（再生/一時停止）
  - スライダーでのシーク機能
  - 再生時間表示
  - ローディング/エラー状態管理

### 🎨 UI/UX

- 4タブナビゲーション
  - **メッセージ**: スレッド一覧（相手ごと）
  - **フォロワー**: フォロワー管理・メッセージ送信
  - **受信一覧**: 全受信メッセージ（従来形式）
  - **プロフィール**: ユーザー情報
- Material Design準拠
- ローディングインジケーター
- エラーハンドリングとユーザーフレンドリーなメッセージ
- プロフィール画像表示（未設定時はイニシャル表示）
- ログアウト機能

### 🔧 バックエンド（Node.js + Express + MongoDB）

#### データベース（MongoDB Atlas）

- **User モデル**
  - username（ユニーク）、email（ユニーク）、password（ハッシュ化）
  - profileImage、bio
  - followersCount、followingCount（自動カウント）
  - fcmToken（プッシュ通知用デバイストークン）

- **Follower モデル**
  - user、follower（参照）
  - 複合インデックス（重複防止）
  - followedAt（タイムスタンプ）

- **Message モデル**
  - sender、receivers（配列、複数受信者対応）
  - filePath、fileSize、duration、mimeType
  - readStatus（ユーザーごとの既読状態）
  - isDeleted（論理削除）
  - deletedBy（削除者リスト、全ユーザー削除時にファイル物理削除）

#### API エンドポイント

**認証API (`/auth`)**
- `POST /auth/register` - ユーザー登録
- `POST /auth/login` - ログイン（JWTトークン発行）
- `GET /auth/me` - 現在のユーザー情報取得
- `PUT /auth/fcm-token` - FCMトークン更新（プッシュ通知用）

**ユーザーAPI (`/users`)**
- `GET /users/search?q=keyword` - ユーザー検索
- `GET /users/:id` - ユーザー詳細
- `POST /users/:id/follow` - フォロー
- `DELETE /users/:id/follow` - アンフォロー
- `GET /users/:id/followers` - フォロワー一覧
- `GET /users/:id/following` - フォロー中一覧

**メッセージAPI (`/messages`)**
- `POST /messages/send` - メッセージ送信（multipart/form-data）
- `GET /messages/received` - 受信メッセージ一覧
- `GET /messages/sent` - 送信メッセージ一覧
- `GET /messages/search` - メッセージ検索（送信者名、日付範囲、既読フィルター）
- `GET /messages/threads` - スレッド一覧（送信者ごと、未読数付き）
- `GET /messages/thread/:senderId` - 特定相手とのメッセージ一覧
- `PUT /messages/:id/read` - 既読マーク
- `DELETE /messages/:id` - メッセージ削除（論理削除）
- `GET /messages/:id/download` - ファイルダウンロード（認証必須）

#### セキュリティ

- JWT トークン認証（protect ミドルウェア）
- bcrypt パスワードハッシュ化
- CORS 設定
- ファイルアップロード制限（10MB、audio MIMEタイプのみ）
- アクセス権限チェック（自分宛のメッセージのみダウンロード可能）

#### プッシュ通知

- Firebase Admin SDK統合
- メッセージ送信時に受信者全員へ通知
- FCMトークン管理
- バックグラウンド/フォアグラウンド通知対応

## 🚀 セットアップ手順

### 前提条件

- Node.js 18+ がインストールされていること
- Flutter 3.9.2+ がインストールされていること
- MongoDB Atlas アカウント（または ローカルMongoDB）
- Firebase プロジェクト（プッシュ通知機能を使う場合）

### 1. バックエンドのセットアップ

```bash
cd backend
npm install
```

**環境変数の設定**

`backend/.env` ファイルを作成し、以下を設定：

```env
MONGO_URI=mongodb+srv://your-connection-string
JWT_SECRET=your-secret-key
PORT=3000
```

**Firebase設定（プッシュ通知用）**

Firebase Consoleから秘密鍵をダウンロードし配置：
```bash
# serviceAccountKey.json を backend/config/ に配置
backend/config/serviceAccountKey.json
```

詳細は [FIREBASE_SETUP.md](FIREBASE_SETUP.md) を参照。

**サーバー起動**

```bash
npm start
```

サーバーは `http://localhost:3000` で起動します。

### 2. モバイルアプリのセットアップ

```bash
cd voice_message_app
flutter pub get
```

**Firebase設定（プッシュ通知用）**

FlutterFire CLIで自動設定（推奨）：

```bash
# FlutterFire CLIインストール（初回のみ）
dart pub global activate flutterfire_cli
export PATH="$PATH":"$HOME/.pub-cache/bin"

# Firebase自動設定
cd voice_message_app
flutterfire configure
```

対話的に選択すると、自動的に設定ファイルが配置されます。

詳細な手順は [FIREBASE_SETUP.md](FIREBASE_SETUP.md) を参照。

**定数の設定**

`voice_message_app/lib/constants.dart` の `BASE_URL` をバックエンドのURLに設定：

```dart
const String BASE_URL = 'http://localhost:3000';  // または実際のサーバーURL
```

**アプリ実行**

```bash
flutter run
```

または、VS Code / Android Studio から実行。

## 🧪 テスト

現在、ユニットテストと統合テストは未実装です（フェーズ7で予定）。

## 📋 技術スタック

### フロントエンド
- Flutter 3.9.2+
- Dart
- provider（状態管理）
- http（HTTP通信）
- audioplayers（音声再生）
- record（音声録音）
- shared_preferences（ローカルストレージ）
- timeago（相対時間表示）

### バックエンド
- Node.js 18+
- Express.js 4.18+
- MongoDB（Mongoose）
- JWT（jsonwebtoken）
- bcrypt（パスワードハッシュ化）
- multer（ファイルアップロード）

## 📝 今後の実装予定

詳細は `PROJECT_STRUCTURE_AND_ROADMAP.txt` を参照してください。

### 次の優先事項

1. **フェーズ7：テスト・デプロイメント** ⏳
   - ユニットテスト実装
   - ウィジェットテスト実装
   - 統合テスト実装
   - CI/CD パイプライン構築
   - Docker コンテナ化
   - AWS/Google Cloud デプロイメント
   - App Store/Google Play リリース

2. **フェーズ5：セキュリティ・パフォーマンス** ⏳
   - エンドツーエンド暗号化
   - キャッシング戦略強化
   - パフォーマンス最適化
   - エラーハンドリング強化
   - Sentry導入によるモニタリング

3. **拡張機能**
   - グループメッセージング
   - リアクション機能
   - 音声テキスト化（Speech-to-Text）
   - 音声翻訳機能
   - Webバージョン開発

## 🤝 コントリビューション

プルリクエストを歓迎します！大きな変更の場合は、まずissueを開いて変更内容を議論してください。

## 📄 ライセンス

MIT License

## 👥 作成者

開発中の学習プロジェクトです。

---

**最終更新**: 2026年2月20日
