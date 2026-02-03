// ========================================
// データベース接続設定
// ========================================
// MongoDBへの接続を管理するファイル

const mongoose = require('mongoose');

/**
 * MongoDBに接続する関数
 */
const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI, {
      // Mongoose 6以降、以下のオプションはデフォルトで有効
      // useNewUrlParser: true,
      // useUnifiedTopology: true,
    });

    console.log(`✅ MongoDB接続成功: ${conn.connection.host}`);
    console.log(`📊 データベース名: ${conn.connection.name}`);
  } catch (error) {
    console.error('❌ MongoDB接続エラー:', error.message);
    // 接続失敗時はプロセスを終了
    process.exit(1);
  }
};

module.exports = connectDB;
