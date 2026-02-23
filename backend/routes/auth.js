// ========================================
// 認証ルート
// ========================================
// ユーザー登録・ログイン・認証関連のルーティング

const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { protect } = require('../middleware/auth');

// ========================================
// 公開ルート（認証不要）
// ========================================

/**
 * @route   POST /auth/register
 * @desc    新規ユーザー登録
 * @access  Public
 */
router.post('/register', authController.register);

/**
 * @route   POST /auth/login
 * @desc    ユーザーログイン
 * @access  Public
 */
router.post('/login', authController.login);

// ========================================
// 保護されたルート（認証必要）
// ========================================

/**
 * @route   GET /auth/me
 * @desc    現在のユーザー情報を取得
 * @access  Private
 */
router.get('/me', protect, authController.getMe);

/**
 * @route   PUT /auth/fcm-token
 * @desc    FCMトークンを更新
 * @access  Private
 */
router.put('/fcm-token', protect, authController.updateFcmToken);

/**
 * @route   POST /auth/logout
 * @desc    ログアウト（FCMトークン・リフレッシュトークンをクリア）
 * @access  Private
 */
router.post('/logout', protect, authController.logout);

/**
 * @route   POST /auth/refresh
 * @desc    リフレッシュトークンで新しいアクセストークンを発行
 * @access  Public（リフレッシュトークン必須）
 */
router.post('/refresh', authController.refresh);

/**
 * @route   POST /auth/forgot-password
 * @desc    パスワードリセット用メールを送信
 * @access  Public
 */
router.post('/forgot-password', authController.forgotPassword);

/**
 * @route   POST /auth/reset-password/:token
 * @desc    パスワードリセット確定
 * @access  Public（リセットトークン必須）
 */
router.post('/reset-password/:token', authController.resetPassword);

module.exports = router;
