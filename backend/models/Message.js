// ========================================
// メッセージモデル
// ========================================
// 音声メッセージ情報を管理するスキーマ

const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema(
  {
    // 送信者
    sender: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },

    // 受信者（複数可能）
    receivers: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
      },
    ],

    // 音声ファイルパス
    filePath: {
      type: String,
      required: true,
    },

    // オリジナルファイル名
    originalFilename: {
      type: String,
      required: true,
    },

    // ファイルサイズ（バイト）
    fileSize: {
      type: Number,
      required: true,
    },

    // 音声の長さ（秒）
    duration: {
      type: Number,
      default: 0,
    },

    // MIMEタイプ
    mimeType: {
      type: String,
      default: 'audio/m4a',
    },

    // 添付画像パス（オプション）
    attachedImage: {
      type: String,
      default: null,
    },

    // 音声テキスト化結果（将来実装用）
    transcript: {
      type: String,
      default: null,
    },

    // 既読状態（受信者ごと）
    readStatus: [
      {
        user: {
          type: mongoose.Schema.Types.ObjectId,
          ref: 'User',
        },
        readAt: {
          type: Date,
          default: null,
        },
        isRead: {
          type: Boolean,
          default: false,
        },
      },
    ],

    // 送信日時
    sentAt: {
      type: Date,
      default: Date.now,
    },

    // 削除フラグ
    isDeleted: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

// インデックス（検索性能向上）
messageSchema.index({ sender: 1, sentAt: -1 });
messageSchema.index({ receivers: 1, sentAt: -1 });
messageSchema.index({ sentAt: -1 });

const Message = mongoose.model('Message', messageSchema);

module.exports = Message;
