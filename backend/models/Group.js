// ========================================
// グループモデル
// ========================================
// グループメッセージング機能のグループ情報を管理するスキーマ

const mongoose = require('mongoose');

const groupSchema = new mongoose.Schema(
  {
    // グループ名
    name: {
      type: String,
      required: [true, 'グループ名は必須です'],
      trim: true,
      minlength: [1, 'グループ名は1文字以上必要です'],
      maxlength: [50, 'グループ名は50文字以内で設定してください'],
    },

    // グループの説明
    description: {
      type: String,
      maxlength: [200, 'グループの説明は200文字以内で設定してください'],
      default: '',
    },

    // グループアイコン画像パス
    iconImage: {
      type: String,
      default: null,
    },

    // グループ管理者（作成者）
    admin: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },

    // グループメンバー
    members: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
    ],
  },
  {
    timestamps: true,
  }
);

// インデックス（メンバーIDによる検索性能向上）
groupSchema.index({ members: 1 });
groupSchema.index({ admin: 1 });

const Group = mongoose.model('Group', groupSchema);

module.exports = Group;
