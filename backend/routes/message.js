// ========================================
// メッセージ関連ルーティング
// ========================================
// 音声メッセージの送信、受信、既読管理の
// エンドポイントを定義します

const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const { protect } = require('../middleware/auth');
const {
  sendMessage,
  sendTextMessage,
  getReceivedMessages,
  getSentMessages,
  markAsRead,
  deleteMessage,
  downloadMessage,
  searchMessages,
  getMessageThreads,
  getThreadMessages,
  getMessageById,
  addReaction,
  removeReaction,
} = require('../controllers/messageController');

// ========================================
// Multer設定（音声ファイルアップロード用）
// ========================================
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/'); // uploadsディレクトリに保存
  },
  filename: (req, file, cb) => {
    // タイムスタンプ + オリジナルファイル名で保存
    cb(null, Date.now() + '-' + file.originalname);
  }
});

// ファイルフィルター（音声 + 画像を許可）
const fileFilter = (req, file, cb) => {
  const allowedAudio = [
    'audio/mpeg', 'audio/mp4', 'audio/m4a', 'audio/x-m4a',
    'audio/aac', 'audio/wav', 'audio/webm', 'audio/ogg',
    'video/mp4',  // m4a が video/mp4 として検出される場合（Android）
  ];
  const allowedImage = [
    'image/jpeg', 'image/png', 'image/gif', 'image/webp',
  ];

  if (file.fieldname === 'voice' && allowedAudio.includes(file.mimetype)) {
    cb(null, true);
  } else if (file.fieldname === 'thumbnail' && allowedImage.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error(`許可されていないファイル形式です: ${file.mimetype} (${file.fieldname})`), false);
  }
};

const upload = multer({ 
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 10 * 1024 * 1024 // 最大10MB
  }
});

// ========================================
// すべてのルートは認証が必要
// ========================================

// メッセージ送信（音声 + サムネイル任意）
// POST /messages/send
router.post('/send', protect, upload.fields([
  { name: 'voice', maxCount: 1 },
  { name: 'thumbnail', maxCount: 1 }
]), sendMessage);

// テキストメッセージ送信
// POST /messages/send-text
router.post('/send-text', protect, sendTextMessage);

// 受信メッセージリスト取得
// GET /messages/received
router.get('/received', protect, getReceivedMessages);

// メッセージ検索
// GET /messages/search
router.get('/search', protect, searchMessages);

// スレッド一覧取得（送信者ごとにグループ化）
// GET /messages/threads
router.get('/threads', protect, getMessageThreads);

// 特定の送信者からのメッセージ取得
// GET /messages/thread/:senderId
router.get('/thread/:senderId', protect, getThreadMessages);

// 送信メッセージリスト取得
// GET /messages/sent
router.get('/sent', protect, getSentMessages);

// メッセージ詳細取得
// GET /messages/:id
router.get('/:id', protect, getMessageById);

// メッセージ既読
// PUT /messages/:id/read
router.put('/:id/read', protect, markAsRead);

// メッセージ削除
// DELETE /messages/:id
router.delete('/:id', protect, deleteMessage);

// リアクション追加
// POST /messages/:id/reactions
router.post('/:id/reactions', protect, addReaction);

// リアクション削除
// DELETE /messages/:id/reactions/:emoji
router.delete('/:id/reactions/:emoji', protect, removeReaction);

// 音声ファイルダウンロード
// GET /messages/:id/download
router.get('/:id/download', protect, downloadMessage);

module.exports = router;
