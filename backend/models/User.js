// ========================================
// ユーザーモデル
// ========================================
// ユーザー情報を管理するMongooseスキーマ

const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    // 表示名（重複可）
    username: {
      type: String,
      required: [true, 'ユーザー名は必須です'],
      trim: true,
      minlength: [1, 'ユーザー名は1文字以上必要です'],
      maxlength: [30, 'ユーザー名は30文字以内で設定してください'],
    },

    // ユニークID（@handle）
    handle: {
      type: String,
      required: [true, 'IDは必須です'],
      unique: true,
      trim: true,
      lowercase: true,
      index: true,
      minlength: [3, 'IDは3文字以上必要です'],
      maxlength: [20, 'IDは20文字以内で設定してください'],
      match: [/^[a-z0-9_]+$/, 'IDは英小文字・数字・_のみ使用できます'],
    },

    // メールアドレス（ユニーク、必須）
    email: {
      type: String,
      required: [true, 'メールアドレスは必須です'],
      unique: true,
      trim: true,
      lowercase: true,
      index: true,
      match: [
        /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/,
        '有効なメールアドレスを入力してください',
      ],
    },

    // パスワード（ハッシュ化して保存）
    password: {
      type: String,
      required: [true, 'パスワードは必須です'],
      minlength: [6, 'パスワードは6文字以上必要です'],
    },

    // プロフィール画像URL
    profileImage: {
      type: String,
      default: null,
    },

    // 自己紹介
    bio: {
      type: String,
      maxlength: [200, '自己紹介は200文字以内で設定してください'],
      default: '',
    },

    // フォロワー数（参照用）
    followersCount: {
      type: Number,
      default: 0,
    },

    // フォロー中の数（参照用）
    followingCount: {
      type: Number,
      default: 0,
    },

    // アカウント作成日時（自動生成）
    createdAt: {
      type: Date,
      default: Date.now,
    },

    // 最終更新日時（自動更新）
    updatedAt: {
      type: Date,
      default: Date.now,
    },

    // FCMトークン（プッシュ通知用）
    // 初学者向け説明：Firebase Cloud Messagingでプッシュ通知を送るために
    //                 デバイスを識別するトークンを保存します
    fcmToken: {
      type: String,
      default: null,
    },
  },
  {
    // タイムスタンプを自動管理
    timestamps: true,
  }
);

// パスワードをJSON出力時に除外
userSchema.set('toJSON', {
  transform: function (doc, ret, options) {
    delete ret.password;
    return ret;
  },
});

const User = mongoose.model('User', userSchema);

module.exports = User;
