// ========================================
// キャッシュユーティリティ
// ========================================
// Redis を使った API レスポンスキャッシング
//
// 【キャッシュキー命名規則】
//   threads:{userId}         - スレッド一覧
//   thread:{userId}:{partnerId} - 特定ユーザーとの会話
//   received:{userId}        - 受信メッセージ一覧
//   user:{id}                - ユーザー詳細
//   users:{userId}:p{page}:l{limit}:q{q} - ユーザー一覧
//   followers:{userId}       - フォロワー一覧
//   following:{userId}       - フォロー中一覧
//
// 【TTL 設計】（秒）
//   スレッド系   : 60s  (頻繁に更新される)
//   ユーザー系   : 300s (比較的安定)
//   フォロー系   : 120s (中程度)

const redis = require('../config/redis');

// ----------------------------------------
// TTL 定数
// ----------------------------------------
const TTL = {
  THREADS:       60,   // スレッド一覧
  THREAD_MSGS:   30,   // 特定スレッドのメッセージ一覧
  RECEIVED:      60,   // 受信メッセージ一覧
  USER:         300,   // ユーザー詳細
  USERS_LIST:   120,   // ユーザー一覧
  FOLLOWERS:    120,   // フォロワー/フォロー中
};

// ----------------------------------------
// get: キャッシュから取得
// ----------------------------------------
const get = async (key) => {
  if (!redis.isAvailable) return null;
  try {
    const raw = await redis.get(key);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null; // キャッシュエラーは握りつぶしてDB参照に fallback
  }
};

// ----------------------------------------
// set: キャッシュに保存
// ----------------------------------------
const set = async (key, value, ttl = TTL.THREADS) => {
  if (!redis.isAvailable) return;
  try {
    await redis.setex(key, ttl, JSON.stringify(value));
  } catch {
    // 保存失敗は無視（次回は DB から取得）
  }
};

// ----------------------------------------
// del: 指定キーを削除（複数可）
// ----------------------------------------
const del = async (...keys) => {
  if (!redis.isAvailable || keys.length === 0) return;
  try {
    // keyPrefix が自動付与されるため、複数一括削除は個別に処理
    await Promise.all(keys.map(k => redis.del(k)));
  } catch {
    // 削除失敗は無視
  }
};

// ----------------------------------------
// delPattern: パターンに一致するキーを全削除
// SCAN を使用してサーバーをブロックしない
// ----------------------------------------
const delPattern = async (pattern) => {
  if (!redis.isAvailable) return;
  try {
    // ioredis の keyPrefix は SCAN でも自動付与されるため
    // pattern に prefix を含める必要はない（内部的に処理される）
    let cursor = '0';
    // ioredis の keyPrefix を考慮したパターン
    const fullPattern = `${redis.options.keyPrefix || 'vmapp:'}${pattern}`;

    // 直接 Redis コマンドを発行（keyPrefix を手動管理）
    const rawClient = redis.getBuiltinCommands
      ? redis
      : redis;

    // SCAN は keyPrefix を自動適用しないため call で実行
    do {
      // eslint-disable-next-line no-await-in-loop
      const [nextCursor, keys] = await redis.call('SCAN', cursor, 'MATCH', fullPattern, 'COUNT', '100');
      cursor = nextCursor;
      if (keys.length > 0) {
        // これらのキーは既に prefix 付きなので unlink で直接削除
        await redis.call('DEL', ...keys);
      }
    } while (cursor !== '0');
  } catch {
    // パターン削除失敗は無視
  }
};

// ----------------------------------------
// invalidateUserMessages: メッセージ操作時の一括無効化
// senderId と receiverIds を指定する
// ----------------------------------------
const invalidateUserMessages = async (senderId, receiverIds = []) => {
  const delKeys = [
    `threads:${senderId}`,
    `received:${senderId}`,
  ];
  for (const rid of receiverIds) {
    delKeys.push(
      `threads:${rid}`,
      `received:${rid}`,
      `thread:${senderId}:${rid}`,
      `thread:${rid}:${senderId}`,
    );
  }
  await del(...delKeys);
};

module.exports = {
  get,
  set,
  del,
  delPattern,
  invalidateUserMessages,
  TTL,
};
