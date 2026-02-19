// ========================================
// 認証コントローラー
// ========================================
// ユーザー登録・ログイン・認証処理を管理

const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

/**
 * ユーザー登録
 * POST /auth/register
 */
exports.register = async (req, res) => {
  try {
    const { username, handle, email, password } = req.body;

    // 入力チェック
    if (!username || !handle || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'ユーザー名、ID、メールアドレス、パスワードは必須です',
      });
    }

    // handleのフォーマットチェック
    const handleLower = handle.toLowerCase().trim();
    if (!/^[a-z0-9_]{3,20}$/.test(handleLower)) {
      return res.status(400).json({
        success: false,
        message: 'IDは英小文字・数字・_の3〜20文字で入力してください',
      });
    }

    // handleの重複チェック
    const existingHandle = await User.findOne({ handle: handleLower });
    if (existingHandle) {
      return res.status(400).json({
        success: false,
        message: 'このIDは既に使用されています',
      });
    }

    // パスワードをハッシュ化
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // 新しいユーザーを作成
    const user = await User.create({
      username,
      handle: handleLower,
      email,
      password: hashedPassword,
    });

    // JWTトークンを生成
    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, {
      expiresIn: '30d', // 30日間有効
    });

    res.status(201).json({
      success: true,
      message: 'ユーザー登録が完了しました',
      data: {
        user: {
          id: user._id,
          username: user.username,
          handle: user.handle,
          email: user.email,
          profileImage: user.profileImage,
          bio: user.bio,
        },
        token,
      },
    });
  } catch (error) {
    console.error('登録エラー:', error);
    res.status(500).json({
      success: false,
      message: 'サーバーエラーが発生しました',
      error: error.message,
    });
  }
};

/**
 * ログイン
 * POST /auth/login
 */
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // 入力チェック
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'メールアドレスとパスワードを入力してください',
      });
    }

    // ユーザーを検索（パスワード含む）
    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'メールアドレスまたはパスワードが正しくありません',
      });
    }

    // パスワードを検証
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'メールアドレスまたはパスワードが正しくありません',
      });
    }

    // JWTトークンを生成
    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, {
      expiresIn: '30d',
    });

    res.status(200).json({
      success: true,
      message: 'ログインに成功しました',
      data: {
        user: {
          id: user._id,
          username: user.username,          handle: user.handle,          email: user.email,
          profileImage: user.profileImage,
          bio: user.bio,
          followersCount: user.followersCount,
          followingCount: user.followingCount,
        },
        token,
      },
    });
  } catch (error) {
    console.error('ログインエラー:', error);
    res.status(500).json({
      success: false,
      message: 'サーバーエラーが発生しました',
      error: error.message,
    });
  }
};

/**
 * 現在のユーザー情報を取得
 * GET /auth/me
 */
exports.getMe = async (req, res) => {
  try {
    // req.userはミドルウェアで設定される
    const user = await User.findById(req.user.id);

    res.status(200).json({
      success: true,
      data: {
        user: {
          id: user._id,
          username: user.username,
          handle: user.handle,
          email: user.email,
          profileImage: user.profileImage,
          bio: user.bio,
          followersCount: user.followersCount,
          followingCount: user.followingCount,
        },
      },
    });
  } catch (error) {
    console.error('ユーザー情報取得エラー:', error);
    res.status(500).json({
      success: false,
      message: 'サーバーエラーが発生しました',
      error: error.message,
    });
  }
};

/**
 * FCMトークンを更新
 * PUT /auth/fcm-token
 * 
 * 【処理フロー】
 * ①リクエストボディからFCMトークンを取得
 * ②現在のユーザーのfcmTokenフィールドを更新
 * ③レスポンスを返す
 * 
 * 【使用例】
 * アプリ起動時やトークン更新時にこのエンドポイントを呼び出して、
 * サーバーに最新のFCMトークンを保存します
 */
exports.updateFcmToken = async (req, res) => {
  try {
    const { fcmToken } = req.body;

    // 入力チェック
    if (!fcmToken) {
      return res.status(400).json({
        success: false,
        message: 'FCMトークンは必須です',
      });
    }

    // ユーザーのFCMトークンを更新
    const user = await User.findByIdAndUpdate(
      req.user.id,
      { fcmToken },
      { new: true }
    );

    res.status(200).json({
      success: true,
      message: 'FCMトークンを更新しました',
      data: {
        userId: user._id,
        fcmToken: user.fcmToken,
      },
    });
  } catch (error) {
    console.error('FCMトークン更新エラー:', error);
    res.status(500).json({
      success: false,
      message: 'サーバーエラーが発生しました',
      error: error.message,
    });
  }
};
