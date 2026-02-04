# ボイスメッセージ送受信アプリ

Flutter製モバイルアプリとNode.js（Express）+ MongoDB バックエンドで構成される、フルスタック音声メッセージングアプリです。

## 🎯 プロジェクト概要

ユーザー認証、フォロー機能、音声メッセージの録音・送信・受信・再生、既読管理など、SNS的な機能を備えた音声コミュニケーションアプリケーションです。

## 📁 ディレクトリ構成

- **voice_message_app/** : Flutterモバイルアプリ（iOS/Android対応）
- **backend/** : Node.js + Express + MongoDB APIサーバー
- **README.md** : このファイル
- **PROJECT_STRUCTURE_AND_ROADMAP.txt** : 詳細な技術仕様とロードマップ

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
  - 既読マーク（再生時自動）
  - プルダウンで更新

- **音声再生**
  - 認証付きファイルダウンロード
  - ローカルキャッシュ再生
  - 再生コントロール（再生/一時停止）
  - スライダーでのシーク機能
  - 再生時間表示
  - ローディング/エラー状態管理

### 🎨 UI/UX

- タブナビゲーション（ホーム/フォロワー/受信/プロフィール）
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

- **Follower モデル**
  - user、follower（参照）
  - 複合インデックス（重複防止）
  - followedAt（タイムスタンプ）

- **Message モデル**
  - sender、receivers（配列、複数受信者対応）
  - filePath、fileSize、duration、mimeType
  - readStatus（ユーザーごとの既読状態）
  - isDeleted（論理削除）

#### API エンドポイント

**認証API (`/auth`)**
- `POST /auth/register` - ユーザー登録
- `POST /auth/login` - ログイン（JWTトークン発行）
- `GET /auth/me` - 現在のユーザー情報取得

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
- `PUT /messages/:id/read` - 既読マーク
- `DELETE /messages/:id` - メッセージ削除（論理削除）
- `GET /messages/:id/download` - ファイルダウンロード（認証必須）

#### セキュリティ

- JWT トークン認証（protect ミドルウェア）
- bcrypt パスワードハッシュ化
- CORS 設定
- ファイルアップロード制限（10MB、audio MIMEタイプのみ）
- アクセス権限チェック（自分宛のメッセージのみダウンロード可能）

## 🚀 セットアップ手順

### 前提条件

- Node.js 18+ がインストールされていること
- Flutter 3.9.2+ がインストールされていること
- MongoDB Atlas アカウント（または ローカルMongoDB）

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

1. **テスト実装**（フェーズ7）
   - ユニットテスト
   - 統合テスト
   - E2Eテスト

2. **残りのメッセージング機能**（フェーズ3）
   - プッシュ通知（FCM）
   - 音声テキスト化（Speech-to-Text）
   - メッセージ検索

3. **高度な機能**（フェーズ4）
   - グループメッセージング
   - リアクション機能
   - 音声エフェクト

## 🤝 コントリビューション

プルリクエストを歓迎します！大きな変更の場合は、まずissueを開いて変更内容を議論してください。

## 📄 ライセンス

MIT License

## 👥 作成者

開発中の学習プロジェクトです。

---

**最終更新**: 2026年2月4日
