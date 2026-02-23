// ========================================
// グループ関連ルーティング
// ========================================
// グループのCRUD・メンバー管理・グループメッセージの
// エンドポイントを定義します

const express = require('express');
const router = express.Router();
const multer = require('multer');
const { protect } = require('../middleware/auth');
const {
  getMyGroups,
  getGroupById,
  createGroup,
  updateGroup,
  deleteGroup,
  addMember,
  removeMember,
  getGroupMessages,
  sendGroupTextMessage,
  sendGroupVoiceMessage,
  markGroupMessageRead,
} = require('../controllers/groupController');

// ========================================
// Multer設定（グループアイコン・音声ファイル用）
// ========================================
const iconStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/groups/');
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + '-' + file.originalname);
  },
});

const voiceStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + '-' + file.originalname);
  },
});

const iconUpload = multer({
  storage: iconStorage,
  fileFilter: (req, file, cb) => {
    const allowedImage = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    if (allowedImage.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error(`許可されていないファイル形式です: ${file.mimetype}`), false);
    }
  },
  limits: { fileSize: 5 * 1024 * 1024 },
});

const voiceUpload = multer({
  storage: voiceStorage,
  fileFilter: (req, file, cb) => {
    const allowedAudio = [
      'audio/mpeg', 'audio/mp4', 'audio/m4a', 'audio/x-m4a',
      'audio/aac', 'audio/wav', 'audio/webm', 'audio/ogg',
      'video/mp4',
    ];
    if (allowedAudio.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error(`許可されていないファイル形式です: ${file.mimetype}`), false);
    }
  },
  limits: { fileSize: 10 * 1024 * 1024 },
});

// ========================================
// すべてのルートは認証が必要
// ========================================

// 自分が参加しているグループ一覧
// GET /groups
router.get('/', protect, getMyGroups);

// グループ作成
// POST /groups
router.post('/', protect, iconUpload.single('icon'), createGroup);

// グループ詳細
// GET /groups/:id
router.get('/:id', protect, getGroupById);

// グループ情報更新（管理者のみ）
// PUT /groups/:id
router.put('/:id', protect, iconUpload.single('icon'), updateGroup);

// グループ削除（管理者のみ）
// DELETE /groups/:id
router.delete('/:id', protect, deleteGroup);

// メンバー追加（管理者のみ）
// POST /groups/:id/members
router.post('/:id/members', protect, addMember);

// メンバー削除（管理者または本人）
// DELETE /groups/:id/members/:userId
router.delete('/:id/members/:userId', protect, removeMember);

// グループメッセージ一覧
// GET /groups/:id/messages
router.get('/:id/messages', protect, getGroupMessages);

// グループテキストメッセージ送信
// POST /groups/:id/messages/text
router.post('/:id/messages/text', protect, sendGroupTextMessage);

// グループ音声メッセージ送信
// POST /groups/:id/messages/voice
router.post('/:id/messages/voice', protect, voiceUpload.single('voice'), sendGroupVoiceMessage);

// グループメッセージ既読
// PUT /groups/:id/messages/:messageId/read
router.put('/:id/messages/:messageId/read', protect, markGroupMessageRead);

module.exports = router;
