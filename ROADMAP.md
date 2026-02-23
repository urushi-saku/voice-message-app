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
| 拡張機能 | グループメッセージング | ✅ 完了 |

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
- **リアクション追加/削除 API**（`Message.reactions` 配列フィールド）

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

- [x] グループメッセージング
- [x] メッセージへのリアクション（絵文字）
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
