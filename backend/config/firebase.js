// ========================================
// Firebase Admin SDK 設定
// ========================================
// プッシュ通知を送信するためのFirebase設定

const admin = require('firebase-admin');

// Firebase Admin SDKの初期化
// 初学者向け説明：
// Firebase Consoleでプロジェクトを作成し、秘密鍵JSONファイルを
// ダウンロードする必要があります。
// 
// 【初期設定手順】
// 1. Firebase Console (https://console.firebase.google.com/) にアクセス
// 2. プロジェクトを作成
// 3. プロジェクト設定 → サービスアカウント → 「新しい秘密鍵の生成」
// 4. ダウンロードしたJSONファイルを backend/config/serviceAccountKey.json として保存
// 5. .gitignore に serviceAccountKey.json を追加（機密情報なので公開しない）

let firebaseApp;

try {
  // 環境変数からFirebase秘密鍵のパスを取得
  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_KEY || './config/serviceAccountKey.json';
  
  // サービスアカウント秘密鍵の読み込み
  const serviceAccount = require(serviceAccountPath);

  // Firebase Admin SDKを初期化
  firebaseApp = admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  console.log('✅ Firebase Admin SDK initialized successfully');
} catch (error) {
  console.warn('⚠️  Firebase Admin SDK initialization failed:', error.message);
  console.warn('⚠️  Push notifications will not work until Firebase is properly configured.');
  console.warn('⚠️  Please follow the setup instructions in backend/config/firebase.js');
}

/**
 * FCM通知を送信する関数
 * 
 * @param {string} fcmToken - 送信先デバイスのFCMトークン
 * @param {object} notification - 通知内容
 * @param {string} notification.title - 通知タイトル
 * @param {string} notification.body - 通知本文
 * @param {object} data - カスタムデータ（オプション）
 * @returns {Promise<string>} - メッセージID
 */
async function sendPushNotification(fcmToken, notification, data = {}) {
  if (!firebaseApp) {
    console.warn('Firebase is not initialized. Skipping push notification.');
    return null;
  }

  if (!fcmToken) {
    console.warn('FCM token is missing. Cannot send push notification.');
    return null;
  }

  const message = {
    token: fcmToken,
    notification: {
      title: notification.title,
      body: notification.body,
    },
    data: data,
    // Android固有の設定
    android: {
      priority: 'high',
      notification: {
        sound: 'default',
        channelId: 'voice_messages',
      },
    },
    // iOS固有の設定
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
        },
      },
    },
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('✅ Push notification sent successfully:', response);
    return response;
  } catch (error) {
    console.error('❌ Error sending push notification:', error);
    throw error;
  }
}

/**
 * 複数のデバイスに通知を送信する関数
 * 
 * @param {string[]} fcmTokens - 送信先デバイスのFCMトークン配列
 * @param {object} notification - 通知内容
 * @param {object} data - カスタムデータ（オプション）
 * @returns {Promise<object>} - 送信結果
 */
async function sendPushNotificationToMultiple(fcmTokens, notification, data = {}) {
  if (!firebaseApp) {
    console.warn('Firebase is not initialized. Skipping push notifications.');
    return null;
  }

  // 空のトークンを除外
  const validTokens = fcmTokens.filter(token => token && token.length > 0);

  if (validTokens.length === 0) {
    console.warn('No valid FCM tokens. Cannot send push notifications.');
    return null;
  }

  const message = {
    tokens: validTokens,
    notification: {
      title: notification.title,
      body: notification.body,
    },
    data: data,
    android: {
      priority: 'high',
      notification: {
        sound: 'default',
        channelId: 'voice_messages',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
        },
      },
    },
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`✅ Push notifications sent: ${response.successCount} successful, ${response.failureCount} failed`);
    return response;
  } catch (error) {
    console.error('❌ Error sending push notifications:', error);
    throw error;
  }
}

module.exports = {
  sendPushNotification,
  sendPushNotificationToMultiple,
};
