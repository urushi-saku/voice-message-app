// ========================================
// ユーザーモデル
// ========================================
// ユーザー情報を管理するMongooseスキーマ

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

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

    // リフレッシュトークン（JWT再発行用）
    refreshToken: {
      type: String,
      default: null,
      select: false, // 通常のクエリには含めない
    },

    // リフレッシュトークンの有効期限
    refreshTokenExpiresAt: {
      type: Date,
      default: null,
    },

    // パスワードリセットトークン（ハッシュ化して保存）
    resetPasswordToken: {
      type: String,
      default: null,
      select: false,
    },

    // パスワードリセットトークンの有効期限（1時間）
    resetPasswordExpires: {
      type: Date,
      default: null,
    },

    // ========================================
    // E2EE（エンドツーエンド暗号化）用公開鍵
    // ========================================
    // X25519 公開鍵（Base64エンコード済み）
    // 秘密鍵はサーバーに送信せず、デバイス内のSecureStorageに保管
    publicKey: {
      type: String,
      default: null,
    },

    // ========================================
    // ソーシャル認証（Google OAuth）
    // ========================================
    // Google OAuth 情報
    googleId: {
      type: String,
      default: null,
      sparse: true, // null 値の重複を許可
    },

    // OAuth でログインする場合、パスワード不要
    // authType: 'email' | 'google'
    authType: {
      type: String,
      enum: ['email', 'google'],
      default: 'email',
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

// パスワードの自動ハッシュ化（save時）
userSchema.pre('save', async function () {
  // パスワードが変更されていない場合はスキップ
  if (!this.isModified('password')) {
    return;
  }

  // パスワードがプレーンテキストの場合のみハッシュ化
  // （既にハッシュ化されている可能性がある場合の対応）
  if (!this.password.startsWith('$2a$') && !this.password.startsWith('$2b$')) {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
  }
});

const User = mongoose.model('User', userSchema);

module.exports = User;
