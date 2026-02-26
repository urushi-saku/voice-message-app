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
  updateProfileImage,
  updateHeaderImage,
  getUsers,
  deleteAccount,
  updatePublicKey,
  getPublicKey,
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
  // image/* すべて許可（image/jpg, image/jpeg, image/png, image/webp 等）
  // または mimetype が不明な場合も拡張子で判断
  const isImage = file.mimetype.startsWith('image/') ||
    file.mimetype === 'application/octet-stream';

  if (isImage) {
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

// ユーザー一覧取得（ページング対応）
// GET /users?page=1&limit=20&q=
router.get('/', protect, getUsers);

// ユーザー検索
// GET /users/search?q=username
router.get('/search', protect, searchUsers);

// プロフィール更新
// PUT /users/profile
router.put('/profile', protect, updateProfile);

// プロフィール画像更新
// PUT /users/profile/image
router.put('/profile/image', protect, (req, res, next) => {
  upload.single('image')(req, res, (err) => {
    if (err) {
      console.error('プロフィール画像 multer エラー:', err);
      return res.status(400).json({ error: err.message || '画像のアップロードに失敗しました' });
    }
    next();
  });
}, updateProfileImage);

// ======================================
// Multer設定（ヘッダー画像アップロード用）
// ======================================
const headerStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/headers/');
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `header-${req.user.id}-${Date.now()}${ext}`);
  }
});
const uploadHeader = multer({
  storage: headerStorage,
  fileFilter: fileFilter,
  limits: { fileSize: 10 * 1024 * 1024 } // 最大10MB
});

// ヘッダー画像更新
// PUT /users/profile/header-image
router.put('/profile/header-image', protect, (req, res, next) => {
  uploadHeader.single('image')(req, res, (err) => {
    if (err) {
      console.error('ヘッダー画像 multer エラー:', err);
      return res.status(400).json({ error: err.message || 'ヘッダー画像のアップロードに失敗しました' });
    }
    next();
  });
}, updateHeaderImage);

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

// アカウント削除（自分のみ）
// DELETE /users/:id
router.delete('/:id', protect, deleteAccount);

// ========================================
// E2EE 公開鍵
// ========================================
// 自分の公開鍵を登録/更新
// PUT /users/public-key
router.put('/public-key', protect, updatePublicKey);

// 特定ユーザーの公開鍵を取得
// GET /users/:id/public-key
router.get('/:id/public-key', protect, getPublicKey);

module.exports = router;
