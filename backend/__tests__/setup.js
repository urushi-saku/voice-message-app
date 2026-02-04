// ========================================
// テストセットアップ
// ========================================
// 各テストの前後で実行される共通処理

// テスト用環境変数を読み込み
require('dotenv').config({ path: '.env.test' });

const mongoose = require('mongoose');
const User = require('../models/User');
const Follower = require('../models/Follower');
const Message = require('../models/Message');

// テスト前の初期化
beforeAll(async () => {
  // データベース接続のタイムアウトを延長
  jest.setTimeout(30000);
});

// 各テストの前にデータベースをクリーンアップ
beforeEach(async () => {
  // すべてのコレクションをクリア
  await User.deleteMany({});
  await Follower.deleteMany({});
  await Message.deleteMany({});
});

// テスト後のクリーンアップ
afterAll(async () => {
  // データベース接続を閉じる
  await mongoose.connection.close();
});
