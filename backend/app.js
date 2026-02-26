// ========================================
// ボイスメッセージアプリ - バックエンドサーバー
// ========================================
// このファイルはNode.js + Expressで書かれたサーバーです
// Flutterアプリから送られてきた音声ファイルを受け取ったり、
// 保存されている音声ファイルを取得・再生するための機能を提供します

// 環境変数の読み込み（最初に実行）
require('dotenv').config();

// ========================================
// Sentry 初期化（最初に実行 — 全モジュールロード前）
// ========================================
// テスト環境では Sentry を初期化しない（Jest 無限ループ回避）
const Sentry = require('@sentry/node');
if (process.env.NODE_ENV !== 'test') {
  Sentry.init({
    dsn: process.env.SENTRY_DSN || '',
    environment: process.env.NODE_ENV || 'development',
    // トランザクションのサンプリング率（本番: 10%, 開発: 100%）
    tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1.0,
    // DSN が未設定（ローカル開発）の場合は Sentry を無効化
    enabled: !!process.env.SENTRY_DSN,
  });
}

// 必要なモジュール（Node.jsの機能）をインポート
const express = require('express');          // Webサーバーを作るためのフレームワーク
const cors = require('cors');                // CORS対応
const path = require('path');                // ファイルパスを操作するためのモジュール
const fs = require('fs');                    // ファイル操作を行うためのモジュール
const rateLimit = require('express-rate-limit'); // レート制限
const helmet = require('helmet');                // セキュリティヘッダー (HSTS 等)
const mongoose   = require('mongoose');           // MongoDB 接続クローズ用
const connectDB  = require('./config/database'); // データベース接続
const redisClient = require('./config/redis');   // Redis クライアント起動（キャッシュ層）

const app = express();                       // Expressアプリケーションを作成
const PORT = process.env.PORT || 3000;       // サーバーが待機するポート番号

// リバースプロキシ（nginx / AWS ELB / GCP LB 等）の X-Forwarded-Proto を信頼
app.set('trust proxy', 1);

// ========================================
// データベース接続
// ========================================
connectDB();

// ========================================
// ミドルウェア設定
// ========================================

// ========================================
// HTTPS/TLS 強制リダイレクト（本番環境のみ）
// ========================================
// HTTP でアクセスされた場合 301 で HTTPS へリダイレクト
// X-Forwarded-Proto ヘッダーを使用（リバースプロキシ対応）
if (process.env.NODE_ENV === 'production') {
  app.use((req, res, next) => {
    const proto = req.headers['x-forwarded-proto'];
    if (req.secure || proto === 'https') {
      return next();
    }
    return res.redirect(301, `https://${req.headers.host}${req.url}`);
  });
}

// ========================================
// セキュリティヘッダー（helmet）
// ========================================
// - Strict-Transport-Security (HSTS): ブラウザに1年間 HTTPS を強制
// - X-Content-Type-Options, X-Frame-Options 等の標準セキュリティヘッダー
app.use(helmet({
  hsts: {
    maxAge: 31536000,        // 1年（秒）
    includeSubDomains: true, // サブドメインにも適用
    preload: true,           // HSTS Preload リストへの登録を許可
  },
  contentSecurityPolicy: false, // REST API サーバーのため CSP は不要
}));

// JSON形式のリクエストボディをパース
app.use(express.json());
// URLエンコードされたデータをパース
app.use(express.urlencoded({ extended: true }));
// CORS設定（すべてのオリジンを許可）
app.use(cors());

// ========================================
// レート制限
// ========================================
// 【全体】全APIに対する基本制限（DDoS・スクレイピング対策）
// 1 IP につき 15 分間で 500 リクエストまで
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15分
  max: 500,
  standardHeaders: true,    // RateLimit-* ヘッダーを返す
  legacyHeaders: false,
  message: { error: 'リクエストが多すぎます。しばらく待ってから再試行してください。' },
  skip: () => process.env.NODE_ENV === 'test', // テスト時は無効
});
app.use(globalLimiter);

// 【認証】ブルートフォース対策
// 1 IP につき 15 分間で 20 リクエストまで（login / register / パスワードリセット）
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: '認証リクエストが多すぎます。15分後に再試行してください。' },
  skip: () => process.env.NODE_ENV === 'test',
});

// 【メッセージ送信】スパム対策
// 1 IP につき 1 分間で 30 リクエストまで
const messageSendLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1分
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'メッセージ送信が多すぎます。しばらく待ってから再試行してください。' },
  skip: () => process.env.NODE_ENV === 'test',
});

// ========================================
// ルーティング
// ========================================
// 認証関連のルート（ブルートフォース対策: 15分で20回まで）
app.use('/auth', authLimiter, require('./routes/auth'));
// ユーザー関連のルート
app.use('/users', require('./routes/user'));
// メッセージ送信エンドポイント専用のスパム対策（1分で30回まで）
app.use(['/messages/send', '/messages/send-text'], messageSendLimiter);
// メッセージ関連のルート
app.use('/messages', require('./routes/message'));
// 通知関連のルート
app.use('/notifications', require('./routes/notification'));
// グループ関連のルート
app.use('/groups', require('./routes/group'));

// ========================================
// Sentry エラーハンドラー（ルート登録後・カスタムエラーハンドラーの前）
// ========================================
// ルーターで発生した例外を自動キャプチャして Sentry に送信する
// テスト環境では Sentry エラーハンドラーをスキップ
if (process.env.NODE_ENV !== 'test') {
  Sentry.setupExpressErrorHandler(app);
}

// ========================================
// uploadsディレクトリの確保（messages APIが使用）
// ========================================
const uploadDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir);
}

const groupUploadDir = path.join(__dirname, 'uploads', 'groups');
if (!fs.existsSync(groupUploadDir)) {
  fs.mkdirSync(groupUploadDir, { recursive: true });
}

// ========================================
// 静的ファイル配信（アップロード画像）
// ========================================
// プロフィール画像・ヘッダー画像を HTTP 経由で取得できるよう公開
app.use('/uploads', require('express').static(path.join(__dirname, 'uploads')));

// ========================================
// ヘルスチェックエンドポイント
// ========================================
app.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'サーバーは正常に動作しています',
    timestamp: new Date().toISOString(),
  });
});

// ========================================
// サーバー起動
// ========================================
// 指定したPORTでサーバーを起動
// テスト時はサーバーを起動しない
let server;
if (process.env.NODE_ENV !== 'test') {
  server = app.listen(PORT, () => {
    console.log('========================================');
    console.log(`🚀 サーバー起動: http://localhost:${PORT}`);
    console.log(`📝 環境: ${process.env.NODE_ENV || 'development'}`);
    console.log('========================================');
  });
}

// ========================================
// Graceful Shutdown
// ========================================
// dumb-init が SIGTERM をそのまま転送してくれるので、
// ここで受け取り「新規リクエストの受付停止 → 接続クローズ」を行う。
// これにより進行中のリクエストを中途切断せずに安全に終了できる。
//
// シャットダウン手順:
//   1. server.close()   — 新規接続の受付を停止（既存リクエストは完走させる）
//   2. mongoose.close() — MongoDB コネクションを閉じる
//   3. redis.quit()     — Redis へ QUIT コマンドを送り接続を閉じる
//   4. process.exit(0)  — 正常終了
// ※ 10 秒以内に完了しない場合は強制終了（ハングアップ防止）
const shutdown = async (signal, exitCode = 0) => {
  console.log(`\n🛑 ${signal} を受信 — Graceful Shutdown を開始します...`);

  // 強制終了タイマー（10 秒後に強制 exit）
  const forceExit = setTimeout(() => {
    console.error('⏰ シャットダウンがタイムアウト — 強制終了します');
    process.exit(1);
  }, 10_000);
  forceExit.unref(); // タイマーだけが残ってもプロセスを維持しない

  try {
    // 1. HTTP サーバー: 新規リクエストの受付を停止
    if (server) {
      await new Promise((resolve, reject) =>
        server.close((err) => (err ? reject(err) : resolve()))
      );
      console.log('  ✅ HTTP サーバー停止完了');
    }

    // 2. MongoDB 接続クローズ
    if (mongoose.connection.readyState !== 0) {
      await mongoose.connection.close();
      console.log('  ✅ MongoDB 切断完了');
    }

    // 3. Redis 接続クローズ（QUIT コマンドで通知してから切断）
    if (redisClient.isAvailable) {
      await redisClient.quit();
      console.log('  ✅ Redis 切断完了');
    }

    // 4. Sentry へのペンディング送信を待つ（エラーレポートの喪失防止）
    if (process.env.SENTRY_DSN) {
      console.log('  📤 Sentry への送信を待機中...');
      await Sentry.close(5000); // 5秒以内に pending イベントを送信
      console.log('  ✅ Sentry 送信完了');
    }

    console.log('👋 シャットダウン完了');
    clearTimeout(forceExit);
    process.exit(exitCode);
  } catch (err) {
    console.error('❌ シャットダウン中にエラーが発生しました:', err);
    Sentry.captureException(err);
    // Sentry 送信を待つ（エラーレポートの喪失防止）
    if (process.env.SENTRY_DSN) {
      await Sentry.close(3000).catch(() => {
        // Sentry.close 自体がタイムアウトしても無視（既にログに出ているため）
      });
    }
    process.exit(1);
  }
};

// docker stop / Kubernetes の terminationGracePeriodSeconds → SIGTERM
process.on('SIGTERM', () => shutdown('SIGTERM', 0));
// Ctrl+C（ローカル開発時）→ SIGINT
process.on('SIGINT',  () => shutdown('SIGINT',  0));

// ========================================
// グローバルエラーハンドラー（予期しないクラッシュ）
// ========================================
process.on('uncaughtException', (err) => {
  console.error('【致命的エラー】uncaughtException:', err);
  Sentry.captureException(err);
  // 致命的例外は Graceful Shutdown を試みてから終了
  shutdown('uncaughtException', 1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('【警告】unhandledRejection:', reason, 'at:', promise);
  Sentry.captureException(reason instanceof Error ? reason : new Error(String(reason)));
  // unhandledRejection は警告に留め、プロセスは継続（クリティカルでない場合のみ）
});

// テスト用にエクスポート
module.exports = app;
