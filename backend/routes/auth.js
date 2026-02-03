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

module.exports = router;
