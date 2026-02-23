// ========================================
// 通知関連コントローラー
// ========================================
// 通知の取得・送信・削除のビジネスロジックを処理します

const Notification = require('../models/Notification');
const User = require('../models/User');

// ========================================
// 通知一覧取得
// GET /notifications?page=1&limit=20&unreadOnly=false
// ========================================
// 自分宛ての通知をページング付きで取得します
//
// 【クエリパラメータ】
// - page       : ページ番号（1始まり、デフォルト: 1）
// - limit      : 1ページあたりの件数（最大50、デフォルト: 20）
// - unreadOnly : 未読のみ取得する場合は 'true'
//
// 【レスポンス】
// - notifications : 通知リスト
// - unreadCount   : 未読通知の総数
// - pagination    : ページング情報
exports.getNotifications = async (req, res) => {
  try {
    const userId = req.user.id;
    const page  = Math.max(1, parseInt(req.query.page)  || 1);
    const limit = Math.min(50, parseInt(req.query.limit) || 20);
    const unreadOnly = req.query.unreadOnly === 'true';
    const skip = (page - 1) * limit;

    // 検索条件
    const query = { recipient: userId };
    if (unreadOnly) {
      query.isRead = false;
    }

    // 通知一覧と未読数を並行取得
    const [notifications, total, unreadCount] = await Promise.all([
      Notification.find(query)
        .populate('sender', 'username handle profileImage')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      Notification.countDocuments(query),
      Notification.countDocuments({ recipient: userId, isRead: false }),
    ]);

    // 返却する通知リストを整形
    const result = notifications.map(n => ({
      _id:       n._id,
      type:      n.type,
      content:   n.content,
      relatedId: n.relatedId,
      isRead:    n.isRead,
      readAt:    n.readAt,
      createdAt: n.createdAt,
      sender: n.sender
        ? {
            _id:          n.sender._id,
            username:     n.sender.username,
            handle:       n.sender.handle,
            profileImage: n.sender.profileImage,
          }
        : null,
    }));

    res.json({
      notifications: result,
      unreadCount,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
        hasNext: page * limit < total,
      },
    });
  } catch (error) {
    console.error('通知一覧取得エラー:', error);
    res.status(500).json({ error: '通知の取得に失敗しました' });
  }
};

// ========================================
// 通知送信
// POST /notifications
// ========================================
// 指定したユーザーに通知を送信します
//
// 【リクエストボディ】
// - recipientId : 通知を受け取るユーザーのID（必須）
// - type        : 通知種別 'follow' | 'message' | 'system'（必須）
// - content     : 通知本文（必須）
// - relatedId   : 関連リソースのID（省略可）
//
// 【制限】
// - 自分自身への通知は不可
// - 相手が存在しない場合は404
exports.sendNotification = async (req, res) => {
  try {
    const senderId = req.user.id;
    const { recipientId, type, content, relatedId } = req.body;

    // バリデーション
    if (!recipientId || !type || !content) {
      return res.status(400).json({ error: 'recipientId・type・content は必須です' });
    }

    if (!['follow', 'message', 'system'].includes(type)) {
      return res.status(400).json({ error: 'type は follow / message / system のいずれかです' });
    }

    if (content.length > 500) {
      return res.status(400).json({ error: '通知本文は500文字以内で入力してください' });
    }

    // 自分自身への通知は不可
    if (recipientId === senderId) {
      return res.status(400).json({ error: '自分自身に通知を送ることはできません' });
    }

    // 受信者が存在するか確認
    const recipient = await User.findById(recipientId);
    if (!recipient) {
      return res.status(404).json({ error: '通知先のユーザーが見つかりません' });
    }

    const notification = await Notification.create({
      recipient: recipientId,
      sender:    senderId,
      type,
      content:   content.trim(),
      relatedId: relatedId || null,
    });

    // sender 情報を付与して返す
    await notification.populate('sender', 'username handle profileImage');

    res.status(201).json({
      message: '通知を送信しました',
      notification: {
        _id:       notification._id,
        type:      notification.type,
        content:   notification.content,
        relatedId: notification.relatedId,
        isRead:    notification.isRead,
        createdAt: notification.createdAt,
        sender: {
          _id:          notification.sender._id,
          username:     notification.sender.username,
          handle:       notification.sender.handle,
          profileImage: notification.sender.profileImage,
        },
      },
    });
  } catch (error) {
    console.error('通知送信エラー:', error);
    res.status(500).json({ error: '通知の送信に失敗しました' });
  }
};

// ========================================
// 通知削除
// DELETE /notifications/:id
// ========================================
// 自分宛ての通知を削除します
// 自分が recipient でない通知は削除できません
exports.deleteNotification = async (req, res) => {
  try {
    const notificationId = req.params.id;
    const userId = req.user.id;

    const notification = await Notification.findById(notificationId);

    if (!notification) {
      return res.status(404).json({ error: '通知が見つかりません' });
    }

    // 自分宛て以外は削除不可
    if (notification.recipient.toString() !== userId) {
      return res.status(403).json({ error: 'この通知を削除する権限がありません' });
    }

    await Notification.deleteOne({ _id: notificationId });

    res.json({ message: '通知を削除しました' });
  } catch (error) {
    console.error('通知削除エラー:', error);
    res.status(500).json({ error: '通知の削除に失敗しました' });
  }
};

// ========================================
// 通知を既読にする
// PATCH /notifications/:id/read
// ========================================
// 指定した通知を既読にします
exports.markNotificationAsRead = async (req, res) => {
  try {
    const notificationId = req.params.id;
    const userId = req.user.id;

    const notification = await Notification.findById(notificationId);

    if (!notification) {
      return res.status(404).json({ error: '通知が見つかりません' });
    }

    if (notification.recipient.toString() !== userId) {
      return res.status(403).json({ error: 'この通知にアクセスする権限がありません' });
    }

    if (notification.isRead) {
      return res.json({ message: '既に既読です' });
    }

    notification.isRead = true;
    notification.readAt = new Date();
    await notification.save();

    res.json({ message: '通知を既読にしました' });
  } catch (error) {
    console.error('通知既読エラー:', error);
    res.status(500).json({ error: '既読の更新に失敗しました' });
  }
};

// ========================================
// 全通知を既読にする
// PATCH /notifications/read-all
// ========================================
// 自分宛ての未読通知をすべて既読にします
exports.markAllNotificationsAsRead = async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await Notification.updateMany(
      { recipient: userId, isRead: false },
      { $set: { isRead: true, readAt: new Date() } }
    );

    res.json({ message: `${result.modifiedCount} 件の通知を既読にしました` });
  } catch (error) {
    console.error('全通知既読エラー:', error);
    res.status(500).json({ error: '既読の更新に失敗しました' });
  }
};
