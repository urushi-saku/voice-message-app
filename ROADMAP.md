# Vio — ロードマップ

最終更新: 2026-02-26  
リポジトリ: `/home/xiaox/voice-message-app`  
**アプリ名**: Vio

---

## 現在の状況

| フェーズ | 内容 | 状態 |
|---|---|---|
| Phase 1 | データベース連携・認証 | ✅ 完了 |
| Phase 2 | フォロワー機能 | ✅ 完了 |
| Phase 3 | メッセージング機能強化 | ✅ 完了 |
| Phase 4 | オフラインモード | ✅ 完了 |
| Phase 4 | プロフィール機能強化 | ✅ 完了 |
| Phase 4 | 録音品質設定 | ✅ 完了 |
| Phase 6 | UI/UX 改善 | ✅ 完了 |
| API拡張 | 認証・ユーザー・メッセージ・通知 | ✅ 完了 |
| Phase 5 | セキュリティ・パフォーマンス | ✅ 完了 |
| 拡張機能 | グループメッセージング | ✅ 完了 |
| UI/UX | リアクション機能（絵文字） | ✅ 完了 |
| 通知 | フォロー通知（FCM push） | ✅ 完了 |
| ダウンロード | ボイスメッセージダウンロード | ✅ 完了 |
| ユーザー | アカウント削除機能 | ✅ 完了 |
| Phase 7 | ウィジェットテスト実装 | ✅ 完了 |
| Phase 7 | Docker コンテナ化 | ✅ 完了 |
| Phase 7 | CI/CD パイプライン | ✅ 完了 |

---

## API 一覧

### 認証

| メソッド | パス | 説明 | 状態 |
|---|---|---|---|
| POST | `/auth/register` | ユーザー登録 | ✅ |
| POST | `/auth/login` | ログイン（refreshToken 発行） | ✅ |
| GET  | `/auth/me` | 現在のユーザー情報 | ✅ |
| POST | `/auth/logout` | ログアウト（FCMトークン・refreshToken クリア） | ✅ |
| POST | `/auth/refresh` | アクセストークンリフレッシュ（ローテーション） | ✅ |
| POST | `/auth/forgot-password` | パスワードリセットメール送信 | ✅ |
| POST | `/auth/reset-password/:token` | パスワードリセット確定 | ✅ |
| PUT  | `/auth/fcm-token` | FCMトークン更新 | ✅ |

### ユーザー

| メソッド | パス | 説明 | 状態 |
|---|---|---|---|
| GET    | `/users` | ユーザー一覧（ページング・絞り込み） | ✅ |
| GET    | `/users/search` | ユーザー検索 | ✅ |
| GET    | `/users/:id` | ユーザー詳細 | ✅ |
| PUT    | `/users/profile` | プロフィール更新（username / handle / bio） | ✅ |
| PUT    | `/users/profile/image` | プロフィール画像更新 | ✅ |
| DELETE | `/users/:id` | アカウント削除（自分のみ・関連データ一括削除） | ✅ |
| POST   | `/users/:id/follow` | フォロー | ✅ |
| DELETE | `/users/:id/follow` | フォロー解除 | ✅ |
| GET    | `/users/:id/followers` | フォロワー一覧 | ✅ |
| GET    | `/users/:id/following` | フォロー中一覧 | ✅ |

### メッセージ

| メソッド | パス | 説明 | 状態 |
|---|---|---|---|
| POST   | `/messages/send` | 音声メッセージ送信（multipart/form-data） | ✅ |
| POST   | `/messages/send-text` | テキストメッセージ送信 | ✅ |
| GET    | `/messages/received` | 受信メッセージ一覧 | ✅ |
| GET    | `/messages/sent` | 送信メッセージ一覧 | ✅ |
| GET    | `/messages/search` | メッセージ検索（送信者名・日付・既読フィルター） | ✅ |
| GET    | `/messages/threads` | スレッド一覧（送信者別グループ化） | ✅ |
| GET    | `/messages/thread/:senderId` | 特定の送信者とのスレッド | ✅ |
| GET    | `/messages/:id` | メッセージ詳細 | ✅ |
| GET    | `/messages/:id/download` | 音声ファイルダウンロード | ✅ |
| PUT    | `/messages/:id/read` | 既読マーク | ✅ |
| DELETE | `/messages/:id` | メッセージ削除（論理削除） | ✅ |
| POST   | `/messages/:id/reactions` | リアクション追加（絵文字） | ✅ |
| DELETE | `/messages/:id/reactions/:emoji` | リアクション削除 | ✅ |

### 通知

| メソッド | パス | 説明 | 状態 |
|---|---|---|---|
| GET    | `/notifications` | 通知一覧（ページング・未読フィルター・未読数付き） | ✅ |
| POST   | `/notifications` | 通知送信 | ✅ |
| DELETE | `/notifications/:id` | 通知削除 | ✅ |
| PATCH  | `/notifications/:id/read` | 個別既読 | ✅ |
| PATCH  | `/notifications/read-all` | 全通知既読 | ✅ |

### グループ

| メソッド | パス | 説明 | 状態 |
|---|---|---|---|
| GET    | `/groups` | 自分が参加しているグループ一覧（最新メッセージ・未読数付き） | ✅ |
| POST   | `/groups` | グループ作成（名前・説明・メンバー・アイコン） | ✅ |
| GET    | `/groups/:id` | グループ詳細 | ✅ |
| PUT    | `/groups/:id` | グループ情報更新（管理者のみ） | ✅ |
| DELETE | `/groups/:id` | グループ削除（管理者のみ・メッセージ・ファイルも削除） | ✅ |
| POST   | `/groups/:id/members` | メンバー追加（管理者のみ） | ✅ |
| DELETE | `/groups/:id/members/:userId` | メンバー削除 / 退出 | ✅ |
| GET    | `/groups/:id/messages` | グループメッセージ一覧（ページング） | ✅ |
| POST   | `/groups/:id/messages/text` | グループテキストメッセージ送信 | ✅ |
| POST   | `/groups/:id/messages/voice` | グループ音声メッセージ送信 | ✅ |
| PUT    | `/groups/:id/messages/:messageId/read` | グループメッセージ既読 | ✅ |

---

## ファイル構成

```
voice-message-app/
├── backend/
│   ├── app.js                          # サーバーエントリーポイント・ルート登録・CORS設定
│   ├── config/
│   │   ├── database.js                 # MongoDB Atlas 接続設定
│   │   └── firebase.js                 # Firebase Admin SDK 初期化・FCM送信関数
│   ├── models/                         # Mongoose スキーマ定義
│   │   ├── User.js                     # ユーザー（認証情報・プロフィール・FCMトークン・refreshToken）
│   │   ├── Follower.js                 # フォロー関係（user ↔ follower の対）
│   │   ├── Message.js                  # メッセージ（音声/テキスト・既読状態・論理削除・リアクション）
│   │   └── Notification.js             # 通知（follow/message/system・既読管理）
│   ├── controllers/                    # ビジネスロジック
│   │   ├── authController.js           # 登録・ログイン・ログアウト・refresh・パスワードリセット
│   │   ├── userController.js           # ユーザー一覧/詳細・フォロー・プロフィール編集・アカウント削除
│   │   ├── messageController.js        # メッセージ送受信・検索・スレッド・既読・削除・ダウンロード・リアクション
│   │   ├── notificationController.js   # 通知一覧・送信・削除・既読操作
│   │   └── groupController.js          # グループCRUD・メンバー管理・グループメッセージ
│   ├── routes/                         # Express ルーター（URLマッピング）
│   │   ├── auth.js                     # /auth/*
│   │   ├── user.js                     # /users/*
│   │   ├── message.js                  # /messages/*
│   │   ├── notification.js             # /notifications/*
│   │   └── group.js                    # /groups/*
│   ├── models/                         # Mongoose スキーマ定義
│   │   ├── User.js                     # ユーザー（認証情報・プロフィール・FCMトークン・refreshToken）
│   │   ├── Follower.js                 # フォロー関係（user ↔ follower の対）
│   │   ├── Message.js                  # メッセージ（音声/テキスト・既読状態・論理削除・グループ参照）
│   │   ├── Notification.js             # 通知（follow/message/system・既読管理）
│   │   └── Group.js                    # グループ（名前・説明・管理者・メンバー）
│   ├── middleware/
│   │   └── auth.js                     # JWT 検証ミドルウェア（protect）
│   └── uploads/                        # アップロードファイル保存先
│       └── profiles/                   # プロフィール画像
│
└── voice_message_app/
    └── lib/
        ├── main.dart                   # アプリエントリーポイント・Provider/Firebase 初期化
        ├── constants.dart              # アプリ全体の定数（色・サイズ等）
        ├── firebase_options.dart       # FlutterFire 自動生成設定
        ├── screens/                    # 画面 UI
        │   ├── home_page.dart          # ホーム（タブナビゲーション: メッセージ/フォロー/プロフィール）
        │   ├── login_screen.dart       # ログイン画面
        │   ├── register_screen.dart    # ユーザー登録画面
        │   ├── recording_screen.dart   # 音声録音・送信画面
        │   ├── select_follower_screen.dart  # 送信先フォロワー選択画面
        │   ├── followers_tab.dart      # フォロワー/フォロー中一覧・ユーザー検索タブ
        │   ├── received_files_tab.dart # 受信メッセージ一覧タブ（スレッド表示）
        │   ├── voice_playback_screen.dart   # 音声ファイルダウンロード・再生画面
        │   ├── profile_page.dart       # 自分のプロフィール表示画面
        │   ├── edit_profile_screen.dart # プロフィール編集（名前・自己紹介・画像）
        │   ├── thread_detail_screen.dart    # 特定ユーザーとのチャット詳細画面
        │   └── settings_screen.dart    # 設定画面（録音品質・ダークモード）
        ├── services/                   # API通信・ビジネスロジック層
        │   ├── auth_service.dart       # 認証API・トークン管理（login/register/logout/refresh）
        │   ├── user_service.dart       # ユーザーAPI（検索・フォロー・プロフィール更新・削除）
        │   ├── message_service.dart    # メッセージAPI（送受信・検索・スレッド・オフライン対応）
        │   ├── notification_service.dart    # 通知API（一覧・送信・削除・既読）
        │   ├── audio_service.dart      # 音声録音・再生・品質設定
        │   ├── fcm_service.dart        # FCMプッシュ通知受信・ローカル通知表示
        │   ├── navigation_service.dart # グローバルNavigator（通知タップ時の画面遷移）
        │   ├── offline_service.dart    # Hive ローカルストレージ（メッセージ・ユーザーキャッシュ）
        │   ├── sync_service.dart       # オフライン送信キューのネットワーク復帰時自動同期
        │   ├── network_connectivity_service.dart  # ネットワーク接続状態監視
        │   └── api_service.dart        # 旧汎用HTTPクライアント（レガシー）
        ├── models/                     # データクラス定義
        │   ├── message.dart            # MessageInfo / ThreadInfo / MessageReaction（APIレスポンス用）
        │   ├── offline_model.dart      # オフライン保存用モデル群（Hive アダプター）
        │   └── recording_config.dart   # 録音品質設定（低/中/高プリセット）
        ├── providers/                  # Provider 状態管理
        │   ├── auth_provider.dart      # 認証状態（ログイン中ユーザー・トークン）
        │   ├── theme_provider.dart     # ダークモード ON/OFF 状態
        │   ├── message_provider.dart   # スレッドメッセージ読み込み・送信・削除・リアクション操作
        │   └── recording_provider.dart # 録音状態・再生・サムネイル・送信フロー
        ├── widgets/                    # 再利用可能な UI コンポーネント
        │   ├── message_bubble.dart     # チャット吹き出し（アバター・しっぽ・既読表示・リアクションチップ）
        │   ├── message_options_sheet.dart   # メッセージ長押しオプション（クイックリアクション行あり）
        │   ├── voice_messages_panel.dart    # 右スワイプで表示されるボイス一覧パネル
        │   ├── offline_banner.dart     # オフライン状態バナー・接続状態インジケーター
        │   ├── custom_page_route.dart  # カスタムページ遷移（SlideUp / FadeSlide / ScaleFade）
        │   ├── animated_widgets.dart   # アニメーションウィジェット（Pulse / Rotate / SlideIn）
        │   ├── accessible_widgets.dart # アクセシビリティ対応ウィジェット（スクリーンリーダー等）
        │   └── responsive_layout.dart  # レスポンシブ対応（Mobile / Tablet / Desktop）
        └── theme/
            └── app_theme.dart          # Material Design 3 準拠テーマ定義（ライト/ダーク）
```

---

## 実装済み機能

### Flutter

- 音声録音・再生（品質設定: 低/中/高）
- ユーザー認証（ログイン・登録・ログアウト）
- JWT / refreshToken 管理
- ユーザー検索・フォロー/アンフォロー
- 音声メッセージ送信（複数受信者）
- テキストメッセージ送信
- 受信メッセージ一覧・既読/未読管理・スワイプ削除
- スレッド表示・チャット画面
- プロフィール表示・編集・画像アップロード
- 設定画面（録音品質・ダークモード）
- オフラインモード（Hive キャッシュ・自動同期）
- グループメッセージング（作成・メンバー管理・テキスト/ボイス送受信・未読管理）
- FCM プッシュ通知・通知タップ画面遷移
- ダークモード / ライトモード
- アニメーション・アクセシビリティ・レスポンシブ対応

- **メッセージリアクション（絵文字）** 🆕
  - 長押しシートのクイックリアクション行（👍 ❤️ 😂 😮 😢 🔥）
  - バブル面のリアクションチップ表示（絵文字・件数・自分のを紫で強調表示）
  - チップタップでトグル（再タップで取り消し）

### バックエンド (Node.js + MongoDB)

- JWT 認証・bcrypt ハッシュ化
- refreshToken ローテーション
- パスワードリセット（メール送信 / コンソールフォールバック）
- FCM トークン管理・プッシュ通知送信
- ファイルアップロード（音声 10MB・画像 5MB、multer）
- 論理削除・アカウント削除時のファイル物理削除
- 通知モデル（follow / message / system）
- グループメッセージング（グループCRUD・メンバー管理・テキスト/ボイス送信・FCM通知）
- **リアクション追加/削除 API**（`Message.reactions` 配列フィールド）

---

## 残タスク

### Phase 5 — セキュリティ・パフォーマンス

- [x] エンドツーエンド暗号化（X25519 DH + XSalsa20-Poly1305、libsodium FFI）
- [x] レート制限（express-rate-limit）
- [x] HTTPS/TLS 強制
- [x] Sentry によるエラーモニタリング
- [x] APIレスポンスキャッシング（Redis）

### Phase 7 — テスト・デプロイメント

- [x] バックエンドユニットテスト（Jest / Supertest）
- [x] Flutter ウィジェットテスト
- [x] Docker コンテナ化
- [x] CI/CD パイプライン（GitHub Actions）
- [ ] 本番環境デプロイ（AWS / GCP）
- [ ] App Store / Google Play リリース

### 拡張機能

- [x] グループメッセージング
- [x] メッセージへのリアクション（絵文字）

---

## 技術スタック

| 区分 | 技術 |
|---|---|
| モバイル | Flutter 3.9.2+, Dart |
| 状態管理 | Provider |
| ローカル保存 | Hive, SharedPreferences |
| バックエンド | Node.js 18+, Express 4 |
| データベース | MongoDB Atlas (Mongoose) |
| 認証 | JWT, bcrypt, nodemailer |
| ファイル | multer |
| 通知 | Firebase Cloud Messaging |
| E2EE | libsodium (sodium + sodium_libs FFI), flutter_secure_storage |
| バージョン管理 | Git / GitHub |
| コンテナ化 | Docker / Docker Compose |
| CI/CD | GitHub Actions / GCP Cloud Run |

---

## 更新履歴

### 2026-02-26
- CI/CD パイプライン実装（GitHub Actions + GCP Cloud Run）
  - `.github/workflows/ci.yml`: PR・push 時にバックエンドユニットテストを自動実行
    - Node.js 20.x、`npm ci` キャッシュ、カバレッジレポートをアーティファクト保存
  - `.github/workflows/deploy.yml`: main push 時に Cloud Run へ自動デプロイ
    - 認証方式: **Workload Identity Federation (OIDC)** — Service Account Key 不要
    - ステップ: テスト通過 → Docker マルチステージビルド → Artifact Registry push → Cloud Run デプロイ
    - `concurrency` 設定で同ブランチの重複デプロイを自動キャンセル
    - デプロイ結果（URL・イメージ・コミット SHA）を Job Summary に出力
    - `workflow_dispatch` で手動トリガー・タグ指定デプロイも対応
    - GCP セットアップ手順を deploy.yml 末尾にコメントで完全記載
- Graceful Shutdown 実装（`app.js`）
  - SIGTERM / SIGINT で `server.close()` → `mongoose.close()` → `redis.quit()` → `Sentry.close()` の順に安全終了
  - 10秒タイムアウトでハングアップ防止

### 2026-02-26
- Docker コンテナ化実装（「自分のPCでは動いたのに…」を撲滅）
  - `backend/Dockerfile`: 3ステージ マルチステージビルド（deps / prod-deps / runner）
    - ベースイメージ: `node:20-alpine`（軽量・セキュリティパッチ済み）
    - `dumb-init` で PID 1 問題・シグナル伝播を適切に処理
    - 非 root ユーザー `viouser` で実行（セキュリティ強化）
    - 開発依存（devDependencies）を本番イメージから除外
  - `docker-compose.yml`: `docker compose up -d` 一発で全環境が立ち上がる
    - `backend` — Node.js/Express API サーバー (Port 3000)
    - `mongo` — MongoDB 7 (Port 27017、ヘルスチェック付き)
    - `redis` — Redis 7-alpine (Port 6379、ヘルスチェック付き)
    - `depends_on` で起動順序を保証（mongo・redis が healthy になってから backend 起動）
    - `uploads/` ・ `serviceAccountKey.json` はボリュームマウントでコンテナ外管理
  - `backend/.dockerignore`: ビルドコンテキスト最小化（node_modules・.env・テストファイル除外）
  - `backend/.env.docker.example`: Docker 専用環境変数テンプレート
  - `.gitignore` に `.env.docker` を追加（秘密情報の誤コミット防止）
- Flutter ウィジェットテスト完了（6/6 PASS）記録をROADMAPに反映

### 2026-02-23
- Redis APIレスポンスキャッシング実装
  - Backend: `ioredis` パッケージ導入
  - `config/redis.js`: Redis クライアント（graceful degradation — 未起動時はアプリを継続）
  - `utils/cache.js`: `get` / `set` / `del` / `delPattern` / `invalidateUserMessages` ユーティリティ
  - キャッシュ対象 API
    - `GET /messages/threads` → `threads:{userId}` (TTL: 60s)
    - `GET /messages/thread/:id` → `thread:{userId}:{partnerId}` (TTL: 30s)
    - `GET /messages/received` → `received:{userId}` (TTL: 60s)
    - `GET /users` → `users:{userId}:p{page}:l{limit}:q{q}` (TTL: 120s)
    - `GET /users/:id` → `user:{id}` (TTL: 300s)
    - `GET /users/:id/followers` → `followers:{id}` (TTL: 120s)
    - `GET /users/:id/following` → `following:{id}` (TTL: 120s)
  - キャッシュ無効化: メッセージ送信/既読/削除、フォロー/解除、プロフィール更新時に関連キャッシュを自動削除
  - `REDIS_HOST` 未設定時はキャッシュ無効化でローカル開発に影響なし
  - Phase 5 (Security / Performance) 全完了 ✅

### 2026-02-23
- Sentry エラーモニタリング実装
  - Backend: `@sentry/node` v10 パッケージ導入
  - `Sentry.init()` を `dotenv.config()` 直後に配置（全モジュールロード前に初期化）
  - `Sentry.setupExpressErrorHandler(app)` でルートの例外を自動キャプチャ
  - `uncaughtException` / `unhandledRejection` のハンドラーで `Sentry.captureException()` を呼び出し
  - `SENTRY_DSN` 未設定時は `enabled: false` でローカル開発に影響なし
  - トランザクションサンプリング率: 本番 10% / 開発 100%
  - Flutter: `sentry_flutter: ^8.0.0` 導入
  - Flutter: `SentryFlutter.init()` で `runApp` をラップ（未処理例外を自動キャプチャ）
  - Flutter: `SentryNavigatorObserver` で画面遷移をトラッキング
  - DSN はビルド時に `--dart-define=SENTRY_DSN=...` / 環境変数 `SENTRY_DSN` で注入

### 2026-02-23
- HTTPS/TLS 強制実装
  - Backend: `helmet` パッケージ導入
  - HSTS（HTTP Strict Transport Security）: `maxAge=31536000`（1年）`includeSubDomains` `preload` 指定
  - 本番環境（`NODE_ENV=production`）で HTTP → HTTPS へ 301 リダイレクト（`X-Forwarded-Proto` 対応）
  - `app.set('trust proxy', 1)` で nginx / AWS ELB 等のリバースプロキシ対応
  - helmet 標準ヘッダー: `X-Content-Type-Options` `X-Frame-Options` `X-DNS-Prefetch-Control` 等

### 2026-02-23
- レート制限実装（express-rate-limit）
  - Backend: `express-rate-limit` パッケージ導入
  - 全体制限: 1IP あたり 15 分間 500 リクエスト（DDoS・スクレイピング対策）
  - 認証制限: 1IP あたり 15 分間 20 リクエスト（ブルートフォース対策、全 `/auth` ルートに適用）
  - 送信制限: 1IP あたり 1 分間 30 リクエスト（スパム対策、`/messages/send` `/messages/send-text` に適用）
  - テスト環境ではすべてのレート制限を自動スキップ（`NODE_ENV=test`）

### 2026-02-23
- E2EE 暗号ライブラリを純 Dart → libsodium FFI に移行（高速化）
  - 背景: `cryptography: ^2.7.0` は純 Dart 実装のため、音声ファイル等の大容量データ暗号化が低速
  - 変更: `cryptography` → `sodium: ^3.4.6` + `sodium_libs: ^3.4.6+4` (Skycoder42、publisher:skycoder42.de)
  - 暗号アルゴリズム変更: X25519 + ChaCha20-Poly1305 (12B nonce) → X25519 + XSalsa20-Poly1305 (24B nonce)
  - DH 鍵導出: 生の DH 出力をそのまま鍵利用 → `crypto_box_easy` / `crypto_box_openEasy` で内部的に HSalsa20 を用いた安全な鍵導出
  - MAC 格納形式: 末尾付加 (CT+MAC) → 先頭付加 (MAC+CT、libsodium easy 標準)
  - キーストレージキーを `e2ee_secret_key_v2` / `e2ee_public_key_v2` に更新（旧実装と競合回避）
  - `SecureKey` のメモリ消去 (`.dispose()`) でセキュアなキー管理を実現
  - `SodiumInit` は `sodium_libs` からのみ import（`sodium.dart` から `hide SodiumInit`）

### 2026-02-23
- E2EE（エンドツーエンド暗号化）実装
  - 暗号方式: X25519 DH鍵交換 + ChaCha20-Poly1305認証付き暗号（ハイブリッド）
  - Backend: `User` モデルに `publicKey` フィールド追加
  - Backend: `Message` モデルに `isEncrypted / contentNonce / encryptedKeys` フィールド追加
  - Backend: `PUT /users/public-key` 公開鍵登録 API、`GET /users/:id/public-key` 公開鍵取得 API追加
  - Backend: `sendMessage` / `sendTextMessage` で E2EE フィールドを保存、`getThreadMessages` で E2EE フィールドをレスポンスに含める
  - Flutter: `e2ee_service.dart` 追加（`E2eeService` / `ReceiverKey` / `EncryptedKeyEntry` / `E2eePayload`）
  - Flutter: `pubspec.yaml` に `cryptography: ^2.7.0` / `flutter_secure_storage: ^9.2.4` 追加
  - Flutter: `auth_service.dart` の登録・ログイン後に `uploadPublicKey()` ・ `storeCurrentUserId()` 呼び出しを追加
  - Flutter: `message_service.dart` で送信時に自動暗号化、受信時に自動復号
  - Flutter: `MessageInfo` に `isEncrypted / contentNonce / encryptedKeys` フィールド追加
  - Flutter: `downloadMessage()` で音声ファイルを自動復号、テキストメッセージは `getThreadMessages` で一括復号
  - Flutter: E2EEに対応していない受信者がいる場合は暗号化なしで送信（自動フォールバック）

### 2026-02-23
- リアクション機能実装
  - Backend: `Message` モデルに `reactions` 配列フィールド追加（`{emoji, userId, username}`）
  - Backend: `addReaction` / `removeReaction` エンドポイント — `POST /messages/:id/reactions` / `DELETE /messages/:id/reactions/:emoji`
  - Backend: `getThreadMessages` レスポンスに `reactions` を含めるよう更新
  - Flutter: `MessageReaction` データクラス追加、`MessageInfo` に `reactions` フィールド追加
  - Flutter: `MessageService.addReaction` / `removeReaction` 実装
  - Flutter: `MessageProvider.toggleReaction` 実装（楽観的UI更新）
  - Flutter: `MessageBubble` に `_ReactionChip` 追加（絵文字・件数・自分御紫強調）
  - Flutter: `showMessageOptionsSheet` にクイックリアクション行（👍❤️😂😮😢🔥）追加
  - Flutter: `ThreadDetailScreen` に `AuthProvider` 連携

### 2026-02-23
- グループメッセージング実装
  - Backend: `Group` モデル・`groupController.js`・`routes/group.js` 追加
  - Backend: `Message` モデルに `group` フィールド追加
  - Flutter: `Group` / `GroupMember` / `GroupMessageInfo` モデル追加
  - Flutter: `GroupService` 追加（グループCRUD・メンバー管理・テキスト/ボイス送信）
  - Flutter: `GroupListScreen` / `GroupChatScreen` / `GroupMembersScreen` / `CreateGroupScreen` 追加
  - Flutter: `home_page.dart` にグループタブ追加（4タブ構成）

### 2026-02-23（`POST /upload`, `GET /voices`, `GET /voice/:filename`）
- 通知API実装（`Notification` モデル・コントローラー・ルート・Flutter サービス）
- `GET /messages/:id` メッセージ詳細API実装
- おすすめユーザー機能削除
- ロードマップを Markdown に移行（`PROJECT_STRUCTURE_AND_ROADMAP.txt` 廃止）

### 2026-02-23
- ユーザーAPI拡張: `GET /users`（一覧）, `DELETE /users/:id`（アカウント削除）
- 認証API拡張: logout / refresh / forgot-password / reset-password
- SMTP 設定追加（`.env`）

### 2026-02-21
- `NavigationService` 実装（通知タップ時の画面遷移）
- FCM 通知タップ → `ThreadDetailScreen` 遷移対応

### 2026-02-20
- Phase 6 (UI/UX改善) 完了
- ダークモード・アニメーション・アクセシビリティ・レスポンシブ実装

### 2026-02-04
- Phase 1–3 完了（認証・フォロー・メッセージング基本機能）

---

## 開発起動コマンド

```bash
# USB接続（WSL）
usbipd attach --wsl --busid 1-1 --auto-attach

# バックエンド + Flutter 同時起動
cd /home/xiaox/voice-message-app && ./dev.sh
```
実際に起動する手順
# 1. 環境変数ファイルを準備
cp backend/.env.docker.example backend/.env.docker
# 必要に応じて JWT_SECRET などを編集

# 2. 一発起動
docker compose up -d

# ログ確認
docker compose logs -f backend

# 停止
docker compose down