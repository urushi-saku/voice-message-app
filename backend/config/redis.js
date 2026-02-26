// ========================================
// Redis クライアント設定
// ========================================
// ioredis を使用した Redis クライアント
//
// 【設計方針】
// - Redis が未起動 / 未設定でもアプリはクラッシュしない（graceful degradation）
// - 接続失敗時はキャッシュを無効化して DB に直接アクセスする
// - ローカル (redis://) と Upstash (rediss://) の両方に対応
//
// 【接続方式】
// ローカル/Docker: REDIS_URL="redis://localhost:6379"
// 本番/Upstash:    REDIS_URL="rediss://default:PASSWORD@hostname:6379" ← s付き！

const Redis = require('ioredis');

// ========================================
// Redis クライアント生成
// ========================================

// REDIS_URL が設定されていれば優先（Upstash用）
// そうでなければ個別の REDIS_HOST / REDIS_PORT / REDIS_PASSWORD を使用（ローカル用）
const redisUrl = process.env.REDIS_URL;

let redisConfig;

if (redisUrl) {
  // 【Upstash / Redis Cloud 用】接続文字列ベース
  // rediss:// は SSL/TLS を使用（自動検出されるが、明示的に tls を設定）
  redisConfig = {
    url: redisUrl,
    keyPrefix: 'vmapp:',
    lazyConnect: true,
    enableOfflineQueue: false,
    
    // TLS 設定（Upstash は rediss:// のため必須）
    tls: redisUrl.includes('rediss://') ? {
      rejectUnauthorized: false, // 自己署名証明書への対応
    } : undefined,
    
    // Cloud Run のコールドスタート対策
    retryStrategy(times) {
      const delayMs = Math.min(times * 50, 2000);
      if (times > 6) return null; // 6回以上失敗したら諦める
      console.warn(`⏳ Redis 再接続試行 ${times}/6... (${delayMs}ms待機)`);
      return delayMs;
    },
  };
} else {
  // 【ローカル/Docker Compose 用】個別のホスト・ポート・パスワード
  redisConfig = {
    host:     process.env.REDIS_HOST || 'localhost',
    port:     parseInt(process.env.REDIS_PORT)     || 6379,
    db:       parseInt(process.env.REDIS_DB)       || 0,
    keyPrefix: 'vmapp:',
    lazyConnect: true,
    enableOfflineQueue: false,
    
    // 再試行戦略: 3 回超えたら諦めて無効化モードに切り替える
    retryStrategy(times) {
      if (times > 3) return null; // null を返すと再試行を停止
      return Math.min(times * 300, 3000);
    },
    
    // パスワードが設定されている場合のみ使用
    ...(process.env.REDIS_PASSWORD && { password: process.env.REDIS_PASSWORD }),
  };
}

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
  console.warn('    Redis を起動するか以下のいずれかを .env に設定してください:');
  console.warn('    【ローカル】 REDIS_URL="redis://localhost:6379"');
  console.warn('    【Upstash】  REDIS_URL="rediss://default:PASSWORD@hostname:6379"');
});

module.exports = client;
