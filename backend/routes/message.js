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
  getReceivedMessages,
  getSentMessages,
  markAsRead,
  deleteMessage,
  downloadMessage
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

// ファイルフィルター（音声ファイルのみ許可）
const fileFilter = (req, file, cb) => {
  const allowedMimeTypes = [
    'audio/mpeg',       // mp3
    'audio/mp4',        // m4a
    'audio/x-m4a',      // m4a
    'audio/wav',        // wav
    'audio/webm',       // webm
    'audio/ogg'         // ogg
  ];

  if (allowedMimeTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('音声ファイルのみアップロード可能です'), false);
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

// メッセージ送信（ファイルアップロード付き）
// POST /messages/send
router.post('/send', protect, upload.single('voice'), sendMessage);

// 受信メッセージリスト取得
// GET /messages/received
router.get('/received', protect, getReceivedMessages);

// 送信メッセージリスト取得
// GET /messages/sent
router.get('/sent', protect, getSentMessages);

// メッセージ既読
// PUT /messages/:id/read
router.put('/:id/read', protect, markAsRead);

// メッセージ削除
// DELETE /messages/:id
router.delete('/:id', protect, deleteMessage);

// 音声ファイルダウンロード
// GET /messages/:id/download
router.get('/:id/download', protect, downloadMessage);

module.exports = router;
