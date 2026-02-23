// ========================================
// 通知モデル
// ========================================
// アプリ内通知（フォロー・メッセージ受信・システム）を管理するスキーマ

const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    // 通知を受け取るユーザー
    recipient: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },

    // 通知を送ったユーザー（システム通知の場合は null）
    sender: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },

    // 通知種別
    // - follow  : フォロー通知
    // - message : メッセージ受信通知
    // - system  : システム通知
    type: {
      type: String,
      enum: ['follow', 'message', 'system'],
      required: true,
    },

    // 通知本文
    content: {
      type: String,
      required: true,
      maxlength: 500,
    },

    // 関連リソースのID（メッセージID、ユーザーIDなど）
    relatedId: {
      type: mongoose.Schema.Types.ObjectId,
      default: null,
    },

    // 既読フラグ
    isRead: {
      type: Boolean,
      default: false,
    },

    // 既読日時
    readAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true, // createdAt / updatedAt を自動付与
  }
);

// =========================================
// インデックス
// =========================================
// 通知一覧を高速に取得するためのインデックス
notificationSchema.index({ recipient: 1, createdAt: -1 });
notificationSchema.index({ recipient: 1, isRead: 1 });

module.exports = mongoose.model('Notification', notificationSchema);
