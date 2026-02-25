// ========================================
// 認証ミドルウェア
// ========================================
// JWTトークンを検証して、認証済みユーザーのみアクセス可能にする

const jwt = require('jsonwebtoken');
const User = require('../models/User');

/**
 * JWT認証ミドルウェア
 * リクエストヘッダーのトークンを検証し、ユーザー情報をreq.userに追加
 */
const protect = async (req, res, next) => {
  let token;

  // Authorizationヘッダーからトークンを取得
  if (
    req.headers.authorization &&
    req.headers.authorization.startsWith('Bearer')
  ) {
    token = req.headers.authorization.split(' ')[1];
  }

  // トークンが存在しない場合
  if (!token) {
    return res.status(401).json({
      success: false,
      error: '認証トークンがありません',
      message: '認証トークンがありません',
    });
  }

  try {
    // トークンを検証
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // デコードしたIDからユーザー情報を取得
    req.user = await User.findById(decoded.id).select('-password');

    if (!req.user) {
      return res.status(401).json({
        success: false,
        error: 'ユーザーが見つかりません',
        message: 'ユーザーが見つかりません',
      });
    }

    next(); // 次のミドルウェアへ
  } catch (error) {
    console.error('認証エラー:', error);
    return res.status(401).json({
      success: false,
      error: 'トークンが無効です',
      message: 'トークンが無効です',
    });
  }
};

module.exports = { protect };
