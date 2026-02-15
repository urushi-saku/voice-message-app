# Firebase秘密鍵設定ガイド

## セットアップ手順

### 1. Firebase Console からサービスアカウント秘密鍵を取得

1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. プロジェクトを選択
3. ⚙️ **プロジェクト設定** → **サービスアカウント** タブ
4. **新しい秘密鍵の生成** をクリック
5. ダウンロードしたJSONファイルを保存

### 2. バックエンドに秘密鍵ファイルを配置

```bash
# ダウンロードしたJSONファイルを配置
mv ~/Downloads/voice-message-app-xxxxx.json backend/config/serviceAccountKey.json
```

### 3. 環境変数を設定（本番環境）

`.env` ファイルに以下を追加：

```bash
# Firebase秘密鍵ファイルのパス
FIREBASE_SERVICE_ACCOUNT_KEY=/path/to/serviceAccountKey.json

# または、BASE_URL
BASE_URL=http://localhost:3000
```

### 4. サーバーを起動

```bash
cd backend
npm start
```

## Firebase Console での確認

- **プロジェクト設定**: Firebase Consoleのプロジェクト設定から確認
- **秘密鍵**: サービスアカウント → 秘密鍵を確認
- **APIキー**: Firebase Console → プロジェクト設定 → API キーを確認

## トラブルシューティング

### エラー1: Firebase Admin SDK initialization failed

**原因**: `serviceAccountKey.json` が見つからない

**解決方法**:
```bash
# ファイルの存在確認
ls -la backend/config/serviceAccountKey.json

# みつからない場合は、Firebase Consoleから再度ダウンロード
```

### エラー2: Push notifications will not work

**原因**: Firebase Admin SDKの認証に失敗

**解決方法**:
1. `/backend/config/serviceAccountKey.json` が正しい場所にあるか確認
2. JSONファイルの秘密鍵フォーマットが正しいか確認
3. ファイルのパーミッション確認:
   ```bash
   chmod 600 backend/config/serviceAccountKey.json
   ```

## Firebase設定ファイルの記載例

### serviceAccountKey.json の構造

```json
{
  "type": "service_account",
  "project_id": "voice-message-app-xxxx",
  "private_key_id": "xxxx",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@voice-message-app-xxxx.iam.gserviceaccount.com",
  "client_id": "xxxx",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/..."
}
```

**⚠️ 注意**: `private_key` には改行が含まれます。JSONフォーマットを壊さないようにコピーしてください。

## 本番環境での設定

本番環境ではGCP（Google Cloud Platform）の推奨メソッドを使用してください：

1. **環境変数の使用**:
   ```bash
   export FIREBASE_SERVICE_ACCOUNT_KEY=/secure/path/to/serviceAccountKey.json
   ```

2. **GCP秘密管理サービス（Secret Manager）**:
   - サービスアカウント秘密鍵をSecret Managerに保存
   - 本番環境でランタイムに取得

3. **Docker/Kubernetes**:
   - Secretsとしてマウント
   - 環境変数として注入

## セキュリティのベストプラクティス

- ✅ `.gitignore` に `serviceAccountKey.json` を追加（してあります）
- ✅ 秘密鍵ファイルを公開リポジトリにコミットしない
- ✅ 本番環境は別の秘密鍵を使用
- ✅ 定期的に秘密鍵をローテーション
- ✅ 不使用になった秘密鍵を削除

## 次のステップ

Firebase設定が完了したら：

1. バックエンドサーバーを起動:
   ```bash
   cd backend
   npm start
   ```

2. Flutterアプリケーションのビルド:
   ```bash
   cd voice_message_app
   flutter pub get
   flutter run
   ```

3. プッシュ通知をテスト
