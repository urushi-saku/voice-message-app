# Firebase Cloud Messaging (FCM) セットアップガイド

このガイドでは、プッシュ通知機能を有効にするためのFirebase設定手順を説明します。

## � 推奨方法：FlutterFire CLI（自動セットアップ）

**最も簡単な方法**です。対話的に設定できます。

### ステップ1：Firebaseプロジェクトの作成

1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. 「プロジェクトを追加」をクリック
3. プロジェクト名を入力（例：voice-message-app）
4. Google アナリティクスの有効化（任意）
5. プロジェクトを作成

### ステップ2：FlutterFire CLIで自動設定

```bash
# 1. FlutterFire CLIをインストール（初回のみ）
dart pub global activate flutterfire_cli

# 2. PATHを追加（初回のみ）
export PATH="$PATH":"$HOME/.pub-cache/bin"

# 3. プロジェクトディレクトリで実行
cd voice_message_app
flutterfire configure
```

**対話的に選択**：
- Firebaseプロジェクトを選択
- プラットフォーム選択（Android, iOS, Web など）
- 自動的に設定ファイルが配置される
- `lib/firebase_options.dart` が自動生成される

### ステップ3：main.dartを更新

```dart
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // FlutterFire CLI生成の設定を使用
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await FcmService.initialize();
  runApp(const MyApp());
}
```

### ステップ4：バックエンドの秘密鍵設定

1. Firebase Console → プロジェクト設定 → サービスアカウント
2. 「新しい秘密鍵の生成」をクリック
3. ダウンロードしたJSONを配置：
   ```bash
   mv ~/Downloads/voice-message-app-xxxxx.json backend/config/serviceAccountKey.json
   ```

**これで完了！**🎉

---

## 📝 手動セットアップ方法（代替手段）

FlutterFire CLIが使えない場合の手動設定方法です。

### 1. Androidアプリの設定

#### 2.1 Firebaseにアプリを登録

1. Firebase Console → プロジェクト設定
2. 「Android アプリを追加」
3. **Androidパッケージ名**を入力
   ```
   com.example.voice_message_app
   ```
   ※ `voice_message_app/android/app/build.gradle.kts` の `applicationId` を確認

4. アプリのニックネーム（任意）
5. SHA-1証明書（デバッグ用は任意、リリース時必須）
   ```bash
   # デバッグ証明書のSHA-1取得
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

#### 2.2 google-services.jsonをダウンロード

1. `google-services.json` ファイルをダウンロード
2. **配置場所**: `voice_message_app/android/app/`

#### 2.3 Android設定ファイルの更新

**`android/build.gradle.kts`** （プロジェクトレベル）
```kotlin
plugins {
    // 既存の設定...
    id("com.google.gms.google-services") version "4.4.0" apply false
}
```

**`android/app/build.gradle.kts`** （アプリレベル）
```kotlin
plugins {
    // 既存の設定...
    id("com.google.gms.google-services")
}
```

---

### 3. iOSアプリの設定

#### 3.1 FirebaseにiOSアプリを登録

1. Firebase Console → プロジェクト設定
2. 「iOS アプリを追加」
3. **iOSバンドルID**を入力
   ```
   com.example.voiceMessageApp
   ```
   ※ `voice_message_app/ios/Runner.xcodeproj/project.pbxproj` の `PRODUCT_BUNDLE_IDENTIFIER` を確認

4. アプリのニックネーム（任意）

#### 3.2 GoogleService-Info.plistをダウンロード

1. `GoogleService-Info.plist` ファイルをダウンロード
2. **配置場所**: `voice_message_app/ios/Runner/`

#### 3.3 Xcodeでの設定

1. Xcodeでプロジェクトを開く
   ```bash
   open voice_message_app/ios/Runner.xcworkspace
   ```

2. `Runner` プロジェクト → `Runner` ターゲット → 「Signing & Capabilities」
3. 「+ Capability」をクリック
4. 「Push Notifications」を追加
5. 「Background Modes」を追加
   - ☑ Background fetch
   - ☑ Remote notifications

---

### 4. バックエンド（Node.js）の設定

#### 4.1 Firebase秘密鍵の取得

1. Firebase Console → プロジェクト設定
2. 「サービスアカウント」タブ
3. 「新しい秘密鍵の生成」をクリック
4. JSONファイルがダウンロードされる

#### 4.2 秘密鍵の配置

1. ダウンロードしたJSONファイルをリネーム
   ```bash
   mv ~/Downloads/voice-message-app-xxxxx.json backend/config/serviceAccountKey.json
   ```

2. **重要**: `.gitignore` に追加（機密情報なので公開しない）
   ```
   backend/config/serviceAccountKey.json
   ```

#### 4.3 環境変数の設定（オプション）

`.env` ファイルに追加（カスタムパスを使う場合）:
```env
FIREBASE_SERVICE_ACCOUNT_KEY=./config/serviceAccountKey.json
```

---

### 5. 動作確認

#### 5.1 パッケージのインストール

```bash
# Flutter側
cd voice_message_app
flutter pub get

# Backend側
cd ../backend
npm install
```

#### 5.2 バックエンドの起動

```bash
cd backend
node app.js
```

コンソールに次のメッセージが表示されればOK:
```
✅ Firebase Admin SDK initialized successfully
```

#### 5.3 アプリの起動

```bash
cd voice_message_app
flutter run
```

コンソールに次のメッセージが表示されればOK:
```
✅ Firebase initialized
✅ 通知権限が許可されました
📱 FCMトークン取得: ey...
✅ FCMトークンをサーバーに送信しました
✅ FCMサービスの初期化が完了しました
```

#### 5.4 プッシュ通知のテスト

1. 2つのアカウントでログイン（デバイスA、デバイスB）
2. デバイスAからデバイスBにボイスメッセージを送信
3. デバイスBにプッシュ通知が届くことを確認

---

## 🔍 トラブルシューティング

### エラー: "Firebase is not initialized"

**原因**: Firebase設定ファイルが見つからない

**解決策**:
- `google-services.json` が `android/app/` にあるか確認
- `GoogleService-Info.plist` が `ios/Runner/` にあるか確認

### エラー: "Firebase Admin SDK initialization failed"

**原因**: バックエンドの秘密鍵が見つからない

**解決策**:
- `backend/config/serviceAccountKey.json` が存在するか確認
- ファイル名が正確か確認

### 通知が届かない

**チェックリスト**:
1. ✅ 通知権限が許可されているか
2. ✅ FCMトークンがサーバーに送信されているか（コンソールログ確認）
3. ✅ バックエンドでFirebase Admin SDKが正しく初期化されているか
4. ✅ インターネット接続が安定しているか

### iOS シミュレータで通知が届かない

**原因**: iOSシミュレータはプッシュ通知をサポートしていない

**解決策**: 実機デバイスでテストする

---

## 📚 参考資料

- [Firebase Console](https://console.firebase.google.com/)
- [FlutterFire公式ドキュメント](https://firebase.flutter.dev/)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [firebase_messaging パッケージ](https://pub.dev/packages/firebase_messaging)

---

## ✅ セットアップ完了チェックリスト

- [ ] Firebaseプロジェクト作成
- [ ] Androidアプリ登録 + `google-services.json` 配置
- [ ] iOSアプリ登録 + `GoogleService-Info.plist` 配置
- [ ] バックエンド秘密鍵 (`serviceAccountKey.json`) 配置
- [ ] パッケージインストール完了
- [ ] バックエンド起動確認（Firebase初期化成功）
- [ ] アプリ起動確認（FCMトークン取得成功）
- [ ] プッシュ通知テスト成功

すべてチェックできたら通知機能の準備完了です！🎉
