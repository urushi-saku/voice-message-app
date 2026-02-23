// ========================================
// Redis クライアント設定
// ========================================
// ioredis を使用した Redis クライアント
//
// 【設計方針】
// - Redis が未起動 / 未設定でもアプリはクラッシュしない（graceful degradation）
// - 接続失敗時はキャッシュを無効化して DB に直接アクセスする
// - REDIS_HOST 未設定時は自動的にキャッシュ無効モードで起動

const Redis = require('ioredis');

// ========================================
// Redis クライアント生成
// ========================================
const redisConfig = {
  host:     process.env.REDIS_HOST || 'localhost',
  port:     parseInt(process.env.REDIS_PORT)     || 6379,
  db:       parseInt(process.env.REDIS_DB)       || 0,
  keyPrefix: 'vmapp:',         // 他アプリとのキー衝突を防ぐ名前空間
  lazyConnect: true,           // connect() を明示的に呼ぶまで接続しない
  enableOfflineQueue: false,   // Redis 未接続時にコマンドをキューに入れない
  // 再試行戦略: 3 回超えたら諦めて無効化モードに切り替える
  retryStrategy(times) {
    if (times > 3) return null; // null を返すと再試行を停止
    return Math.min(times * 300, 3000);
  },
  // パスワードが設定されている場合のみ使用
  ...(process.env.REDIS_PASSWORD && { password: process.env.REDIS_PASSWORD }),
};

const client = new Redis(redisConfig);

// 利用可能フラグ（他モジュールからチェックする）
client.isAvailable = false;

// 接続成功
client.on('connect', () => {
  client.isAvailable = true;
  console.log('✅ Redis 接続成功');
});

// 接続確立（ready）
client.on('ready', () => {
  client.isAvailable = true;
});

// エラー発生（接続拒否・認証失敗等）
client.on('error', (err) => {
  if (client.isAvailable) {
    // 初回エラー時のみログ出力（ループ防止）
    console.warn(`⚠️  Redis エラー: ${err.message}`);
  }
  client.isAvailable = false;
});

// 切断
client.on('close', () => {
  client.isAvailable = false;
});

// 再接続終了（max retries 超過）
client.on('end', () => {
  client.isAvailable = false;
});

// Redis 接続を試みる（失敗してもアプリを止めない）
client.connect().catch(() => {
  console.warn('⚠️  Redis 未接続 — キャッシュは無効化されました（アプリは正常動作します）');
  console.warn('    Redis を起動するか .env に REDIS_HOST を設定してください');
});

module.exports = client;
