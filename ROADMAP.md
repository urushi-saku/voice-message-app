# ボイスメッセージアプリ — ロードマップ

最終更新: 2026-02-23  
リポジトリ: `/home/xiaox/voice-message-app`

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
| Phase 5 | セキュリティ・パフォーマンス | ⏳ 未着手 |
| Phase 7 | テスト・デプロイメント | ⏳ 未着手 |

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

### 通知

| メソッド | パス | 説明 | 状態 |
|---|---|---|---|
| GET    | `/notifications` | 通知一覧（ページング・未読フィルター・未読数付き） | ✅ |
| POST   | `/notifications` | 通知送信 | ✅ |
| DELETE | `/notifications/:id` | 通知削除 | ✅ |
| PATCH  | `/notifications/:id/read` | 個別既読 | ✅ |
| PATCH  | `/notifications/read-all` | 全通知既読 | ✅ |

---

## ファイル構成

```
voice-message-app/
├── backend/
│   ├── app.js
│   ├── config/
│   │   ├── database.js
│   │   └── firebase.js
│   ├── models/
│   │   ├── User.js
│   │   ├── Follower.js
│   │   ├── Message.js
│   │   └── Notification.js
│   ├── controllers/
│   │   ├── authController.js
│   │   ├── userController.js
│   │   ├── messageController.js
│   │   └── notificationController.js
│   ├── routes/
│   │   ├── auth.js
│   │   ├── user.js
│   │   ├── message.js
│   │   └── notification.js
│   ├── middleware/
│   │   └── auth.js
│   └── uploads/
│       └── profiles/
│
└── voice_message_app/
    └── lib/
        ├── main.dart
        ├── constants.dart
        ├── firebase_options.dart
        ├── screens/
        │   ├── home_page.dart
        │   ├── login_screen.dart
        │   ├── register_screen.dart
        │   ├── recording_screen.dart
        │   ├── select_follower_screen.dart
        │   ├── followers_tab.dart
        │   ├── received_files_tab.dart
        │   ├── voice_playback_screen.dart
        │   ├── profile_page.dart
        │   ├── edit_profile_screen.dart
        │   ├── thread_detail_screen.dart
        │   └── settings_screen.dart
        ├── services/
        │   ├── auth_service.dart
        │   ├── user_service.dart
        │   ├── message_service.dart
        │   ├── notification_service.dart
        │   ├── audio_service.dart
        │   ├── fcm_service.dart
        │   ├── navigation_service.dart
        │   ├── offline_service.dart
        │   ├── sync_service.dart
        │   ├── network_connectivity_service.dart
        │   └── api_service.dart
        ├── models/
        │   ├── message.dart
        │   ├── offline_model.dart
        │   └── recording_config.dart
        ├── providers/
        │   ├── auth_provider.dart
        │   ├── theme_provider.dart
        │   ├── message_provider.dart
        │   └── recording_provider.dart
        ├── widgets/
        │   ├── message_bubble.dart
        │   ├── message_options_sheet.dart
        │   ├── voice_messages_panel.dart
        │   ├── offline_banner.dart
        │   ├── custom_page_route.dart
        │   ├── animated_widgets.dart
        │   ├── accessible_widgets.dart
        │   └── responsive_layout.dart
        └── theme/
            └── app_theme.dart
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
- FCM プッシュ通知・通知タップ画面遷移
- ダークモード / ライトモード
- アニメーション・アクセシビリティ・レスポンシブ対応

### バックエンド (Node.js + MongoDB)

- JWT 認証・bcrypt ハッシュ化
- refreshToken ローテーション
- パスワードリセット（メール送信 / コンソールフォールバック）
- FCM トークン管理・プッシュ通知送信
- ファイルアップロード（音声 10MB・画像 5MB、multer）
- 論理削除・アカウント削除時のファイル物理削除
- 通知モデル（follow / message / system）

---

## 残タスク

### Phase 5 — セキュリティ・パフォーマンス

- [ ] エンドツーエンド暗号化（TweetNaCl.js）
- [ ] レート制限（express-rate-limit）
- [ ] HTTPS/TLS 強制
- [ ] Sentry によるエラーモニタリング
- [ ] APIレスポンスキャッシング（Redis）

### Phase 7 — テスト・デプロイメント

- [ ] バックエンドユニットテスト（Jest / Supertest）
- [ ] Flutter ウィジェットテスト
- [ ] Docker コンテナ化
- [ ] CI/CD パイプライン（GitHub Actions）
- [ ] 本番環境デプロイ（AWS / GCP）
- [ ] App Store / Google Play リリース

### 拡張機能（優先度低）

- [ ] グループメッセージング
- [ ] メッセージへのリアクション（絵文字）
- [ ] Web バージョン

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
| バージョン管理 | Git / GitHub |

---

## 更新履歴

### 2026-02-23
- 旧ファイルAPI削除（`POST /upload`, `GET /voices`, `GET /voice/:filename`）
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
