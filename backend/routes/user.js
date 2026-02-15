// ========================================
// ユーザー関連ルーティング
// ========================================
// ユーザー検索、フォロー管理、フォロワーリストの
// エンドポイントを定義します

const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const { protect } = require('../middleware/auth');
const {
  searchUsers,
  followUser,
  unfollowUser,
  getFollowers,
  getFollowing,
  getUserById,
  updateProfile,
  updateProfileImage
} = require('../controllers/userController');

// ========================================
// Multer設定（プロフィール画像アップロード用）
// ========================================
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/profiles/'); // uploadsディレクトリに保存
  },
  filename: (req, file, cb) => {
    // タイムスタンプ + ユーザーID + 拡張子で保存
    const ext = path.extname(file.originalname);
    cb(null, `profile-${req.user.id}-${Date.now()}${ext}`);
  }
});

// ファイルフィルター（画像ファイルのみ許可）
const fileFilter = (req, file, cb) => {
  const allowedMimeTypes = [
    'image/jpeg',       // jpg, jpeg
    'image/png',        // png
    'image/gif',        // gif
    'image/webp'        // webp
  ];

  if (allowedMimeTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('画像ファイルのみアップロード可能です'), false);
  }
};

const upload = multer({ 
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024 // 最大5MB
  }
});

// ========================================
// すべてのルートは認証が必要
// ========================================
// protect ミドルウェアを適用して、
// JWTトークンによる認証を必須にします

// ユーザー検索
// GET /users/search?q=username
router.get('/search', protect, searchUsers);

// プロフィール更新
// PUT /users/profile
router.put('/profile', protect, updateProfile);

// プロフィール画像更新
// PUT /users/profile/image
router.put('/profile/image', protect, upload.single('image'), updateProfileImage);

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
