// ========================================
// ユーザー関連ルーティング
// ========================================
// ユーザー検索、フォロー管理、フォロワーリストの
// エンドポイントを定義します

const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
  searchUsers,
  followUser,
  unfollowUser,
  getFollowers,
  getFollowing,
  getUserById
} = require('../controllers/userController');

// ========================================
// すべてのルートは認証が必要
// ========================================
// protect ミドルウェアを適用して、
// JWTトークンによる認証を必須にします

// ユーザー検索
// GET /users/search?q=username
router.get('/search', protect, searchUsers);

// ユーザー詳細取得
// GET /users/:id
router.get('/:id', protect, getUserById);

// フォローする
// POST /users/:id/follow
router.post('/:id/follow', protect, followUser);

// フォロー解除
// DELETE /users/:id/follow
router.delete('/:id/follow', protect, unfollowUser);

// フォロワーリスト取得
// GET /users/:id/followers
router.get('/:id/followers', protect, getFollowers);

// フォロー中リスト取得
// GET /users/:id/following
router.get('/:id/following', protect, getFollowing);

module.exports = router;
