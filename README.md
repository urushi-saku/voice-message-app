# Vio — ボイスメッセージ送受信アプリ

Flutter製モバイルアプリとNode.js（Express）+ MongoDB バックエンドで構成される、フルスタック音声メッセージングアプリです。**シンプルかつ直感的なUIで、音声による自然なコミュニケーションを実現します。**

> **アプリ名**: Vio（「Vioce」と「I O」のポルマンテュ）

## 🎯 プロジェクト概要

ユーザー認証、フォロー機能、音声メッセージの録音・送信・受信・再生、既読管理など、SNS的な機能を備えた音声コミュニケーションアプリケーションです。

## 📁 ディレクトリ構成

- **voice_message_app/** : Flutterモバイルアプリ（iOS/Android対応）
- **backend/** : Node.js + Express + MongoDB APIサーバー
- **README.md** : このファイル
- **ROADMAP.md** : 詳細な技術仕様とロードマップ

## 📈 プロジェクト進捗

- **フェーズ1（データベース連携＆認証）**: ✅ 完了
- **フェーズ2（フォロワー機能強化）**: ✅ 完了
- **フェーズ3（メッセージング機能強化）**: ✅ 完了 🎉
- **フェーズ4（高度な機能）**: ✅ 完了（オフラインモード、プロフィール機能、録音品質設定）
- **フェーズ5（セキュリティ・パフォーマンス）**: ✅ **完了** 🎉（E2EE、レート制限、HTTPS/TLS、Sentry、Redis キャッシング）
- **フェーズ6（UI/UX改善）**: ✅ 完了（ダークモード、アニメーション、アクセシビリティ、レスポンシブ）
- **コードアーキテクチャ改善**: ✅ 完了（責務分割リファクタリング）
- **リアクション機能**: ✅ 完了（絵文字リアクション・クイックピッカー）
- **ボイスメッセージダウンロード**: ✅ 完了（再生画面・長押しメニュー対応）
- **フォロー通知**: ✅ 完了（FCM push notification + タップで遷移）
- **アカウント削除**: ✅ 完了（設定画面・2段階確認）
- **テキストメッセージ機能**: ✅ **完了** 🆕（音声メッセージとテキスト併用）
- **グループメッセージング**: ✅ **完了** 🆕（グループ作成・メンバー管理・テキスト/ボイス送受信）
- **通知API拡張**: ✅ **完了** 🆕（follow / message / system 通知・未読管理）
- **パスワードリセット機能**: ✅ **完了** 🆕（メール送信・トークン検証）
- **フェーズ7（テスト・デプロイメント）**: ✅ **大部分完了** 🎉（Docker・CI/CD パイプライン・ウィジェットテスト）

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

- **プロフィール管理** 🆕
  - 他ユーザープロフィール表示（Layout: `profile_page.dart` 風）
  - 自分のプロフィール編集機能
  - ユーザー名・自己紹介・プロフィール画像編集
  - **アカウント削除** — 設定画面から削除ボタン（2段階確認付き）

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
  - **リアクション（絵文字）** 🆕
    - 長押しシートのクイックリアクション行（👍❤️😂😮😢🔥）
    - バブル下部にリアクションチップ表示（絵文字・件数・自分は紫強調）
    - チップタップでトグル（追加 / 取り消し）
  - **音声ファイルダウンロード** 🆕
    - 再生画面のAppBar右上にダウンロードボタン
    - 長押しメニューに「ダウンロード」項目
    - Downloadsフォルダへ自動保存（`voice_<送信者名>_<日時>.m4a`形式）

- **プッシュ通知（Firebase Cloud Messaging）** 🆕
  - メッセージ受信時のリアルタイム通知
  - **フォロー通知** — 新しいフォロワーの通知と即座にプロフィール遷移
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

- **テキストメッセージ機能** 🆕
  - テキスト・音声メッセージの混在送信
  - テキスト用 API エンドポイント（`POST /messages/send-text`）
  - チャット画面でのテキスト入力フォーム
  - テキストメッセージは暗号化対応（E2EE）

- **グループメッセージング機能** 🆕
  - グループ作成・削除（管理者権限）
  - メンバー管理（追加・削除・退出）
  - グループテキスト/ボイスメッセージ送受信
  - グループメッセージ既読管理
  - グループアイコン・説明設定
  - FCM グループ通知

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

- **パスワードリセット** 🆕
  - 「パスワードを忘れた」フロー
  - メールアドレス入力 → リセットメール送信
  - リセットトークン検証
  - 新パスワード設定

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

### 🏗️ コードアーキテクチャ 🆕

- **責務分割リファクタリング**
  - `models/message.dart`: `MessageInfo`/`ThreadInfo` をサービスから独立
  - `providers/message_provider.dart`: メッセージ取得・送信・削除・既読処理を集約
  - `providers/recording_provider.dart`: 録音/再生/送信ロジックを Screen から分離
  - `widgets/message_bubble.dart`: チャットバブル・TailPainter を再利用可能 Widget に
  - `widgets/message_options_sheet.dart`: 長押しオプション・削除確認ダイアログを独立
  - `widgets/voice_messages_panel.dart`: 右スワイプパネルを独立
  - `thread_detail_screen.dart`: **1242行 → 474行（-62%）**

### 🔐 セキュリティ機能 🆕

- **エンドツーエンド暗号化（E2EE）**
  - アルゴリズム: X25519 DH鍵交換 + XSalsa20-Poly1305 認証付き暗号
  - libsodium FFI バックエンド（高速な C実装）
  - 公開鍵登録・取得 API
  - メッセージ送受信時の自動暗号化/復号
  - キーストレージ: `flutter_secure_storage`
  - E2EE 非対応受信者への自動フォールバック

- **レート制限**
  - 全体: 15分間 500 リクエスト/IP（DDoS対策）
  - 認証: 15分間 20 リクエスト/IP（ブルートフォース対策）
  - 送信: 1分間 30 リクエスト/IP（スパム対策）

- **HTTPS/TLS 強制**
  - HSTS ヘッダー（maxAge: 1年）
  - 本番環境で HTTP → HTTPS リダイレクト
  - helmet による セキュリティヘッダー設定

- **トークン管理**
  - JWT アクセストークン + リフレッシュトークン
  - トークンローテーション
  - bcrypt パスワードハッシュ化

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
  - E2EE 自動復号対応

- **プッシュ通知拡張** 🆕
  - フォロー通知
  - メッセージ受信通知
  - グループメッセージ通知
  - 通知タップで自動画面遷移
  - 未読通知集計表示

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
  - reactions（`{emoji, userId, username}` 配列）

#### API エンドポイント

**認証API (`/auth`)**
- `POST /auth/register` - ユーザー登録
- `POST /auth/login` - ログイン（refreshToken発行）
- `POST /auth/logout` - ログアウト（FCMトークン・refreshToken クリア）
- `POST /auth/refresh` - アクセストークンリフレッシュ（ローテーション）
- `GET /auth/me` - 現在のユーザー情報取得
- `POST /auth/forgot-password` - パスワードリセットメール送信
- `POST /auth/reset-password/:token` - パスワードリセット確定
- `PUT /auth/fcm-token` - FCMトークン更新（プッシュ通知用）
- `PUT /auth/public-key` - E2EE 公開鍵登録

**ユーザーAPI (`/users`)**
- `GET /users` - ユーザー一覧（ページング・絞り込み）
- `GET /users/search?q=keyword` - ユーザー検索
- `GET /users/:id` - ユーザー詳細
- `GET /users/:id/public-key` - E2EE 公開鍵取得
- `POST /users/:id/follow` - フォロー
- `DELETE /users/:id/follow` - フォロー解除
- `GET /users/:id/followers` - フォロワー一覧
- `GET /users/:id/following` - フォロー中一覧
- `PUT /users/profile` - プロフィール更新（username / bio）
- `PUT /users/profile/image` - プロフィール画像更新
- `DELETE /users/:id` - アカウント削除（自分のみ・関連データ一括削除）

**メッセージAPI (`/messages`)**
- `POST /messages/send` - 音声メッセージ送信（multipart/form-data）
- `POST /messages/send-text` - テキストメッセージ送信
- `GET /messages` - メッセージ一覧
- `GET /messages/:id` - メッセージ詳細
- `GET /messages/received` - 受信メッセージ一覧
- `GET /messages/sent` - 送信メッセージ一覧
- `GET /messages/search` - メッセージ検索（送信者名、日付範囲、既読フィルター）
- `GET /messages/threads` - スレッド一覧（送信者ごと、未読数付き）
- `GET /messages/thread/:senderId` - 特定相手とのメッセージ一覧
- `PUT /messages/:id/read` - 既読マーク
- `DELETE /messages/:id` - メッセージ削除（論理削除）
- `GET /messages/:id/download` - ファイルダウンロード（認証必須、E2EE 対応）
- `POST /messages/:id/reactions` - リアクション追加（絵文字）
- `DELETE /messages/:id/reactions/:emoji` - リアクション削除

**通知API (`/notifications`)**
- `GET /notifications` - 通知一覧（ページング・未読フィルター・未読数付き）
- `POST /notifications` - 通知送信
- `DELETE /notifications/:id` - 通知削除
- `PATCH /notifications/:id/read` - 個別既読
- `PATCH /notifications/read-all` - 全通知既読

**グループAPI (`/groups`)**
- `GET /groups` - グループ一覧（最新メッセージ・未読数付き）
- `POST /groups` - グループ作成（名前・説明・メンバー・アイコン）
- `GET /groups/:id` - グループ詳細
- `PUT /groups/:id` - グループ情報更新（管理者のみ）
- `DELETE /groups/:id` - グループ削除（管理者のみ）
- `POST /groups/:id/members` - メンバー追加（管理者のみ）
- `DELETE /groups/:id/members/:userId` - メンバー削除 / 退出
- `GET /groups/:id/messages` - グループメッセージ一覧（ページング）
- `POST /groups/:id/messages/text` - グループテキストメッセージ送信
- `POST /groups/:id/messages/voice` - グループ音声メッセージ送信
- `PUT /groups/:id/messages/:messageId/read` - グループメッセージ既読

#### セキュリティ

- JWT トークン認証（protect ミドルウェア）
- bcrypt パスワードハッシュ化
- CORS 設定
- ファイルアップロード制限（10MB、audio MIMEタイプのみ）
- アクセス権限チェック（自分宛のメッセージのみダウンロード可能）

#### バックエンド高度な機能

**プッシュ通知**
- Firebase Admin SDK統合
- メッセージ/グループメッセージ/フォロー 送信時に受信者へ通知
- FCMトークン管理・バックグラウンド/フォアグラウンド通知対応

**キャッシング戦略**
- Redis 統合（Upstash 対応）
- APIレスポンスキャッシング（スレッド・受信一覧・ユーザー検索等）
- キャッシュ自動無効化（メッセージ送信時など）
- ローカル開発時（Redis 未起動）は自動フォールバック

**エラーモニタリング**
- Sentry 統合
- 未処理例外・エラースタックトレース自動キャプチャ
- トランザクショントラッキング
- ローカル開発時（SENTRY_DSN 未設定）は自動無効化

## 🚀 セットアップ手順

### 前提条件

- Node.js 18+ がインストールされていること
- Flutter 3.9.2+ がインストールされていること
- Docker & Docker Compose（推奨）
- MongoDB Atlas アカウント（または ローカルMongoDB）
- Firebase プロジェクト（プッシュ通知機能を使う場合）
- Upstash Redis アカウント（オプション・キャッシング用）
- Sentry アカウント（オプション・エラーモニタリング用）

### 1. バックエンドのセットアップ（Docker推奨）

**Docker Compose で一発起動**（推奨 ✅）

```bash
# 環境変数ファイルを準備
cp backend/.env.docker.example backend/.env.docker

# 環境変数を編集（JWT_SECRET等を設定）
vim backend/.env.docker

# 一発起動（MongoDB + Redis + Backend）
docker compose up -d

# ログ確認
docker compose logs -f backend

# 停止
docker compose down
```

`.env.docker` の重要な環境変数：
```env
MONGO_URI=mongodb://mongo:27017/vio
JWT_SECRET=your-secret-key-here
PORT=3000
NODE_ENV=development
REDIS_URL=redis://redis:6379  # またはUPSTASH_REDIS_URL=rediss://...
SENTRY_DSN=https://...@sentry.io/...  # オプション
```

**ローカル開発（Docker なし）**

```bash
cd backend
npm install
```

`backend/.env` ファイルを作成し、以下を設定：
```env
MONGO_URI=mongodb+srv://your-connection-string
JWT_SECRET=your-secret-key
PORT=3000
NODE_ENV=development
# REDIS_URL=redis://localhost:6379  # オプション
# SENTRY_DSN=...  # オプション
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

### バックエンド

```bash
cd backend
npm test          # 全テスト実行
npm run test:unit # ユニットテストのみ
```

実装済み：
- JWT 認証テスト
- ユーザー管理テスト
- メッセージング テスト
- グループメッセージング テスト
- 通知機能テスト
- Jest + Supertest での統合テスト

### フロントエンド（Flutter）

```bash
cd voice_message_app
flutter test      # ウィジェットテスト実行
```

実装済み：
- ウィジェットテスト（MessageBubble・メッセージオプション等）
- Provider 状態管理テスト

### CI/CD パイプライン

GitHub Actions で自動化：
- **PR・push 時**: バックエンドユニットテスト自動実行（テスト失敗で merge ブロック）
- **main push 時**: テスト → Docker ビルド → GCP Artifact Registry push → Cloud Run デプロイ（自動）

## 📋 技術スタック

### フロントエンド
- **Flutter 3.9.2+** / **Dart**
- **provider** — 状態管理
- **http** — HTTP通信
- **audioplayers** — 音声再生
- **record** — 音声録音
- **shared_preferences** — ローカルキャッシュ
- **hive** — オフラインモード・ローカルストレージ
- **connectivity_plus** — ネットワーク接続監視
- **firebase_messaging** — FCM プッシュ通知
- **flutter_local_notifications** — ローカル通知表示
- **flutter_secure_storage** — キーストレージ（E2EE）
- **sodium** / **sodium_libs** — E2EE 暗号化（libsodium FFI）
- **sentry_flutter** — エラーモニタリング
- **timeago** — 相対時間表示
- **image_picker** / **file_picker** — ファイル選択
- **permission_handler** — 権限管理

### バックエンド
- **Node.js 18+** / **Express.js 4.18+**
- **MongoDB** (Mongoose) — データベース
- **jsonwebtoken** — JWT認証
- **bcrypt** — パスワードハッシュ化
- **multer** — ファイルアップロード
- **ioredis** — Redis キャッシング（Upstash対応）
- **firebase-admin** — FCM プッシュ通知
- **nodemailer** — メール送信（パスワードリセット）
- **express-rate-limit** — レート制限
- **helmet** — セキュリティヘッダー
- **@sentry/node** — エラーモニタリング
- **jest** / **supertest** — テストフレームワーク
- **dumb-init** — Docker イニットプロセス

### 環境・デプロイ
- **Docker** / **Docker Compose** — コンテナ化
- **GitHub Actions** — CI/CD パイプライン
- **GCP Artifact Registry** — Docker イメージリポジトリ
- **GCP Cloud Run** — サーバーレス デプロイ
- **MongoDB Atlas** — マネージド MongoDB
- **Upstash Redis** — マネージド Redis（オプション）
- **Firebase Cloud** — プッシュ通知・認証
- **Sentry** — エラーモニタリング（オプション）

## 📝 残タスク・今後の実装予定

詳細は [ROADMAP.md](ROADMAP.md) を参照してください。

### Phase 7 — 残りのタスク

1. **本番環境デプロイ** ⏳
   - AWS / GCP デプロイメント最適化
   - ドメイン・SSL証明書設定
   - 本番監視・ログ集約

2. **App Store / Google Play リリース** ⏳
   - iOS ビルド署名・プロビジョニング
   - Android キーストア設定
   - ストア申請・レビュー対応

### 拡張機能

- 🎙️ **音声テキスト化（Speech-to-Text）**
  - 音声メッセージ → テキスト変換
  - 複数言語対応
  - Google Cloud Speech-to-Text API 統合

- 🌐 **音声翻訳機能**
  - メッセージ多言語翻訳
  - Google Cloud Translation API 統合

- 💻 **Web バージョン開発**
  - Flutter Web サポート
  - 同一 API で Web/Mobile 統一

- 📊 **分析・統計ダッシュボード**
  - ユーザー活動統計
  - メッセージ統計
  - グループ分析

- 🔔 **高度な通知設定**
  - 通知サウンド・バイブレーション カスタマイズ
  - 通知時間帯設定（Do Not Disturb）
  - 選択的通知フィルタリング

## 🤝 コントリビューション

プルリクエストを歓迎します！大きな変更の場合は、まずissueを開いて変更内容を議論してください。

## 📄 ライセンス

MIT License

## 👥 作成者

開発中の学習プロジェクトです。

---

## 🛠️ 開発コマンド

```bash
# USB接続（WSL）
usbipd attach --wsl --busid 1-1 --auto-attach

# バックエンド + Flutter 同時起動
cd /home/xiaox/voice-message-app && ./dev.sh

# Docker でバックエンド起動
docker compose up -d

# Flutter アプリ実行
cd voice_message_app && flutter run
```

---

**最終更新**: 2026年2月26日
