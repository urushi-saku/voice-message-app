# Firebase秘密鍵セットアップ チェックリスト

## ステップ1: Firebase Consoleでのセットアップ

### 1.1 Firebaseプロジェクト作成
- [ ] [Firebase Console](https://console.firebase.google.com/) にアクセス
- [ ] Googleアカウントでログイン
- [ ] 「プロジェクトを追加」をクリック
- [ ] プロジェクト名を入力: `voice-message-app`
- [ ] Googleアナリティクスの設定（任意）
- [ ] 「プロジェクトを作成」をクリック

### 1.2 サービスアカウント秘密鍵をダウンロード
- [ ] Firebase Console → プロジェクト設定（⚙️）
- [ ] 「サービスアカウント」タブをクリック
- [ ] 下部の「Admin SDK の構成スニペット」でNode.jsを選択
- [ ] 「新しい秘密鍵の生成」をクリック
- [ ] JSONファイルをダウンロード（ファイル名: `voice-message-app-xxxxx.json`）

### 1.3 firebase_options.dartの設定（フロントエンド）
- [ ] Firebase Console → プロジェクト設定 → アプリスニペット
  - [ ] API Key (Web)
  - [ ] App ID (Web)
  - [ ] Messaging Sender ID
  - [ ] Project ID

これらの値を使用して、以下を実行：
```bash
cd voice_message_app
export PATH="$PATH":"$HOME/.pub-cache/bin"
flutterfire configure
# または手動で lib/firebase_options.dart を編集
```

---

## ステップ2: バックエンド設定

### 2.1 秘密鍵ファイルの配置
```bash
# ダウンロードしたJSONファイルを以下に移動
mv ~/Downloads/voice-message-app-xxxxx.json backend/config/serviceAccountKey.json

# ファイルのパーミッション設定
chmod 600 backend/config/serviceAccountKey.json

# ファイルが正しく配置されているか確認
ls -la backend/config/serviceAccountKey.json
```

### 2.2 環境変数の設定
```bash
cd backend

# .env ファイルが存在するか確認
ls -la .env

# 存在しない場合は .env.example からコピー
cp .env.example .env

# .env を編集
nano .env
# または
vim .env
```

`.env` ファイルに以下を確認/追加:
```bash
FIREBASE_SERVICE_ACCOUNT_KEY=./config/serviceAccountKey.json
```

### 2.3 必要なパッケージのインストール
```bash
cd backend
npm install
```

---

## ステップ3: セキュリティ確認

### 3.1 .gitignore確認
```bash
# サービスアカウント秘密鍵が .gitignore に登録されているか確認
grep -n "serviceAccountKey" .gitignore

# 出力: backend/config/serviceAccountKey.json が含まれていることを確認
```

### 3.2 機密情報の漏洩確認
```bash
# 秘密鍵ファイルが誤ってgitにステージングされていないか確認
git status
git ls-files backend/config/serviceAccountKey.json

# もし含まれていたら以下で削除
git rm --cached backend/config/serviceAccountKey.json
git commit -m "Remove sensitive serviceAccountKey.json"
```

---

## ステップ4: サーバー起動とテスト

### 4.1 バックエンド起動
```bash
cd backend
npm start

# 正常起動の確認メッセージ:
# ✅ Firebase Admin SDK initialized successfully
# または
# ⚠️  Firebase Admin SDK initialization failed: ... （秘密鍵ファイル未設定時）
```

### 4.2 FCM通知送信テスト
バックエンドAPI経由でテスト通知を送信（実装予定）

### 4.3 Flutterアプリのビルド・実行
```bash
cd voice_message_app
flutter pub get
flutter run

# ログで以下を確認
# ✅ Firebase initialized
# ✅ FCMサービスの初期化が完了しました
```

---

## トラブルシューティング

### 問題1: `Firebase Admin SDK initialization failed`

**症状**: サーバー起動時にこのエラーが表示される

**原因**: 秘密鍵ファイルが見つからないか無効

**解決方法**:
```bash
# 1. ファイルが存在するか確認
ls -la backend/config/serviceAccountKey.json

# 2. .env で正しいパスが指定されているか確認
cat backend/.env | grep FIREBASE

# 3. JSONファイルのフォーマットが正しいか確認
file backend/config/serviceAccountKey.json
# 出力: JSON data が含まれていること

# 4. JSONの妥当性チェック
jq . backend/config/serviceAccountKey.json > /dev/null && echo "Valid JSON" || echo "Invalid JSON"
```

### 問題2: `Cannot find module 'firebase-admin'`

**症状**: サーバー起動時にこのエラーが表示される

**原因**: firebase-admin パッケージがインストールされていない

**解決方法**:
```bash
cd backend
npm install firebase-admin
```

### 問題3: firebase_options.dart が見つからない

**症状**: Flutterアプリをビルド時にエラー

**原因**: firebase_options.dart が生成されていない

**解決方法**:
```bash
cd voice_message_app

# 方法1: FlutterFire CLIで自動生成
export PATH="$PATH":"$HOME/.pub-cache/bin"
flutterfire configure

# 方法2: テンプレートから手動作成
cat > lib/firebase_options.dart << 'EOF'
# (テンプレート内容を貼り付け)
EOF
```

---

## 本番環境への対応

### 本番環境のセキュリティ設定

1. **秘密鍵の管理**:
   - 本番環境では別の秘密鍵を使用
   - 秘密管理サービス（AWS Secrets Manager等）の利用
   - 環境変数として注入

2. **CORSとセキュリティ**:
   - バックエンド: `CORS_ORIGIN` で許可するドメインを指定
   - フロントエンド: HTTPSの使用

3. **秘密鍵のローテーション**:
   - Firebase Console で定期的に秘密鍵をローテーション
   - 使用中の秘密鍵情報を記録

---

## 参考リンク

- [Firebase Console](https://console.firebase.google.com/)
- [Firebase Admin SDK ドキュメント](https://firebase.google.com/docs/admin/setup)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire ドキュメント](https://firebase.flutter.dev/)

---

## セットアップ完了チェックリスト

セットアップが全て完了したことを確認:

- [ ] Firebase Consoleでプロジェクト作成
- [ ] サービスアカウント秘密鍵をダウンロード
- [ ] `backend/config/serviceAccountKey.json` に配置
- [ ] `backend/.env` にFIREBASE_SERVICE_ACCOUNT_KEYを記入
- [ ] `firebase_options.dart` が生成/配置されている
- [ ] `.gitignore` に秘密鍵が追加されている
- [ ] バックエンド起動時に `✅ Firebase Admin SDK initialized successfully`
- [ ] フロントエンド起動時に `✅ Firebase initialized`
- [ ] プッシュ通知が正常に送受信される

**すべてチェックできたら、Firebase秘密鍵セットアップが完了です！** 🎉
