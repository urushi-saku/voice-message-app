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

    // 宛先グループ（グループメッセージの場合）
    group: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Group',
      default: null,
    },

    // 受信者（複数可能）
    receivers: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
    ],

    // メッセージ種別: 'voice' | 'text'
    messageType: {
      type: String,
      enum: ['voice', 'text'],
      default: 'voice',
    },

    // テキストメッセージ内容（messageType === 'text' の場合）
    textContent: {
      type: String,
      default: null,
    },

    // 音声ファイルパス（messageType === 'voice' の場合）
    filePath: {
      type: String,
      default: null,
    },

    // オリジナルファイル名
    originalFilename: {
      type: String,
      default: null,
    },

    // ファイルサイズ（バイト）
    fileSize: {
      type: Number,
      default: 0,
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

    // 削除フラグ（互換性用）
    isDeleted: {
      type: Boolean,
      default: false,
    },

    // 削除者リスト（全ユーザーが削除したかをチェックするため）
    deletedBy: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
    ],

    // ========================================
    // E2EE（エンドツーエンド暗号化）フィールド
    // ========================================
    // E2EE が有効かどうか
    isEncrypted: {
      type: Boolean,
      default: false,
    },

    // 暗号化済みコンテンツ（Base64）
    // isEncrypted=true の場合、filePath/textContent の代わりにこちらを使用
    encryptedContent: {
      type: String,
      default: null,
    },

    // secretbox用ノンス（Base64）
    contentNonce: {
      type: String,
      default: null,
    },

    // 受信者ごとのメッセージ鍵（box で暗号化済み）
    encryptedKeys: [
      {
        // 受信者 ID
        userId: {
          type: mongoose.Schema.Types.ObjectId,
          ref: 'User',
        },
        // nacl.box で暗号化された 32バイトのメッセージ鍵（Base64）
        encryptedKey: {
          type: String,
        },
        // このエントリで使用された一時公開鍵（Base64）
        ephemeralPublicKey: {
          type: String,
        },
        // box用ノンス（Base64）
        keyNonce: {
          type: String,
        },
      },
    ],

    // リアクション
    reactions: [
      {
        emoji: {
          type: String,
          required: true,
        },
        userId: {
          type: mongoose.Schema.Types.ObjectId,
          ref: 'User',
          required: true,
        },
        username: {
          type: String,
          required: true,
        },
      },
    ],
  },
  {
    timestamps: true,
  }
);

// インデックス（検索性能向上）
messageSchema.index({ sender: 1, sentAt: -1 });
messageSchema.index({ receivers: 1, sentAt: -1 });
messageSchema.index({ group: 1, sentAt: -1 });
messageSchema.index({ sentAt: -1 });

const Message = mongoose.model('Message', messageSchema);

module.exports = Message;
