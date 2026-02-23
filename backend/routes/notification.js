// ========================================
// 通知関連ルーティング
// ========================================
// 通知の取得・送信・削除・既読操作のエンドポイントを定義します

const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
  getNotifications,
  sendNotification,
  deleteNotification,
  markNotificationAsRead,
  markAllNotificationsAsRead,
} = require('../controllers/notificationController');

// ========================================
// すべてのルートは認証が必要
// ========================================

// 通知一覧取得（ページング / 未読フィルター対応）
// GET /notifications?page=1&limit=20&unreadOnly=false
router.get('/', protect, getNotifications);

// 全通知を既読にする
// PATCH /notifications/read-all
// ※ /:id/read より先に定義しないとマッチしない
router.patch('/read-all', protect, markAllNotificationsAsRead);

// 通知を既読にする
// PATCH /notifications/:id/read
router.patch('/:id/read', protect, markNotificationAsRead);

// 通知送信
// POST /notifications
router.post('/', protect, sendNotification);

// 通知削除
// DELETE /notifications/:id
router.delete('/:id', protect, deleteNotification);

module.exports = router;
