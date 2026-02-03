// ========================================
// フォロワー関係モデル
// ========================================
// ユーザー間のフォロー関係を管理するスキーマ

const mongoose = require('mongoose');

const followerSchema = new mongoose.Schema(
  {
    // フォローされているユーザー（被フォロー者）
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },

    // フォローしているユーザー（フォロワー）
    follower: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },

    // フォロー開始日時
    followedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
);

// 複合インデックス（同じユーザー間で重複フォローを防ぐ）
followerSchema.index({ user: 1, follower: 1 }, { unique: true });

// クエリ性能向上のためのインデックス
followerSchema.index({ user: 1 });
followerSchema.index({ follower: 1 });

const Follower = mongoose.model('Follower', followerSchema);

module.exports = Follower;
