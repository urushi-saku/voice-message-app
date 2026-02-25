#!/usr/bin/env node

/**
 * マイグレーション: refreshToken互換性修正
 * 
 * セキュリティ強化でrefreshTokenをハッシュ化に変更した際、
 * 既存ユーザーの古い形式のトークンをクリアして新規ログインを要求します。
 */

const mongoose = require('mongoose');
const path = require('path');

// 環境変数の読み込み
require('dotenv').config({ path: path.join(__dirname, '../.env') });

const User = require('../models/User');

async function migrate() {
  try {
    // MongoDB接続
    console.log('📌 MongoDB に接続中...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ MongoDB 接続完了');

    // すべてのユーザーのrefreshTokenをクリア
    console.log('\n🔄 既存ユーザーの古いrefreshTokenをクリア中...');
    const result = await User.updateMany(
      {},
      {
        refreshToken: null,
        refreshTokenExpiresAt: null,
      }
    );

    console.log(`✅ ${result.modifiedCount} 件のユーザーを更新しました`);
    console.log('\n📝 ユーザーは再度ログインして新しいrefreshTokenを取得してください。');

    // 接続を閉じる
    await mongoose.connection.close();
    console.log('\n✅ マイグレーション完了');
    process.exit(0);
  } catch (error) {
    console.error('❌ エラーが発生しました:', error.message);
    process.exit(1);
  }
}

// 実行
migrate();
