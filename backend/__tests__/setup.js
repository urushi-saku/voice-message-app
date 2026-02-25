// ========================================
// テストセットアップ
// ========================================
// 各テストの前後で実行される共通処理

// テスト用環境変数を読み込み
require('dotenv').config({ path: '.env.test' });

const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const User = require('../models/User');
const Follower = require('../models/Follower');
const Message = require('../models/Message');
const Notification = require('../models/Notification');
const Group = require('../models/Group');

let mongoServer;
let isConnected = false;

// テスト前の初期化
beforeAll(async () => {
  // データベース接続のタイムアウトを延長（mongodb-memory-server の起動に時間がかかるため）
  jest.setTimeout(120000);
  
  try {
    // mongodb-memory-server を起動
    mongoServer = await MongoMemoryServer.create();
    const mongoUri = mongoServer.getUri();
    
    // MongoDB に接続
    await mongoose.connect(mongoUri);
    isConnected = true;
    console.log('✅ テスト用 MongoDB (In-Memory) に接続しました');
  } catch (error) {
    console.error('❌ MongoDB 接続に失敗しました:', error.message);
    isConnected = false;
  }
}, 120000);

// 各テストの前にデータベースをクリーンアップ
beforeEach(async () => {
  if (!isConnected) return;
  
  try {
    // すべてのコレクションをクリア
    await User.deleteMany({});
    await Follower.deleteMany({});
    await Message.deleteMany({});
    await Notification.deleteMany({});
    await Group.deleteMany({});
  } catch (error) {
    console.error('テストセットアップエラー:', error);
  }
});

// テスト後のクリーンアップ
afterAll(async () => {
  if (!isConnected) return;
  
  try {
    // データベース接続を閉じる
    await mongoose.disconnect();
    // mongodb-memory-server を停止
    if (mongoServer) {
      await mongoServer.stop();
    }
    console.log('✅ テスト完了、MongoDB を停止しました');
  } catch (error) {
    console.error('接続切断エラー:', error);
  }
});
