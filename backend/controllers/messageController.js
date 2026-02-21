// ========================================
// メッセージ関連コントローラー
// ========================================
// 音声メッセージの送信、受信リスト取得、既読管理の
// ビジネスロジックを処理します

const Message = require('../models/Message');
const User = require('../models/User');
const Follower = require('../models/Follower');
const { sendPushNotificationToMultiple } = require('../config/firebase');
const path = require('path');
const fs = require('fs');

// ========================================
// メッセージ送信
// POST /messages/send
// ========================================
// 音声ファイルをアップロードして、選択したフォロワーに送信します
// 
// 【処理フロー】
// ①フォームから音声ファイルとreceivers（受信者IDリスト）を取得
// ②ファイルがアップロードされているか確認
// ③受信者が全員自分のフォロワーか確認
// ④Messageドキュメントを作成して保存
// ⑤レスポンスを返す
exports.sendMessage = async (req, res) => {
  try {
    const senderId = req.user.id;
    const { receivers, duration } = req.body; // receivers: JSON文字列 "[\"id1\", \"id2\"]"
    const file = req.file;

    // ファイルの確認
    if (!file) {
      return res.status(400).json({ error: '音声ファイルをアップロードしてください' });
    }

    // 受信者リストの確認
    if (!receivers) {
      return res.status(400).json({ error: '受信者を指定してください' });
    }

    // JSON文字列をパース
    let receiverIds;
    try {
      receiverIds = JSON.parse(receivers);
    } catch (e) {
      return res.status(400).json({ error: '受信者リストの形式が不正です' });
    }

    if (!Array.isArray(receiverIds) || receiverIds.length === 0) {
      return res.status(400).json({ error: '受信者を少なくとも1人選択してください' });
    }

    // 受信者が全員自分のフォロワーか確認
    for (const receiverId of receiverIds) {
      const isFollower = await Follower.findOne({
        user: senderId,
        follower: receiverId
      });

      if (!isFollower) {
        return res.status(403).json({ 
          error: 'フォロワーにしか送信できません' 
        });
      }
    }

    // 既読ステータスの初期化
    // 各受信者に対して、未読（false）で初期化
    const readStatus = receiverIds.map(id => ({
      user: id,
      isRead: false,
      readAt: null
    }));

    // メッセージドキュメントを作成
    const newMessage = new Message({
      sender: senderId,
      receivers: receiverIds,
      filePath: file.path,
      fileSize: file.size,
      duration: duration ? parseInt(duration) : null,
      mimeType: file.mimetype,
      readStatus: readStatus
    });

    await newMessage.save();

    // 【プッシュ通知送信】
    // 送信者情報を取得
    const sender = await User.findById(senderId).select('username');
    
    // 受信者のFCMトークンを取得（変数名を receiversData に変更）
    const receiversData = await User.find({ _id: { $in: receiverIds } }).select('fcmToken');
    const fcmTokens = receiversData
      .map(receiver => receiver.fcmToken)
      .filter(token => token); // nullを除外

    // プッシュ通知を送信
    if (fcmTokens.length > 0) {
      try {
        const durationText = duration ? `${Math.floor(duration / 60)}:${String(duration % 60).padStart(2, '0')}` : '';
        await sendPushNotificationToMultiple(
          fcmTokens,
          {
            title: `${sender.username}から新しいメッセージ`,
            body: durationText ? `ボイスメッセージ (${durationText})` : 'ボイスメッセージが届きました',
          },
          {
            messageId: newMessage._id.toString(),
            senderId: senderId,
            senderUsername: sender.username,
            type: 'new_message',
          }
        );
      } catch (notificationError) {
        // 通知送信エラーでもメッセージ送信は成功とする
        console.error('プッシュ通知送信エラー:', notificationError);
      }
    }

    res.status(201).json({
      message: 'メッセージを送信しました',
      messageId: newMessage._id
    });
  } catch (error) {
    console.error('メッセージ送信エラー:', error);
    res.status(500).json({ error: 'メッセージの送信に失敗しました' });
  }
};

// ========================================
// テキストメッセージ送信
// POST /messages/send-text
// ========================================
exports.sendTextMessage = async (req, res) => {
  try {
    const senderId = req.user.id;
    const { receivers, textContent } = req.body;

    if (!textContent || !textContent.trim()) {
      return res.status(400).json({ error: 'テキストを入力してください' });
    }
    if (!receivers) {
      return res.status(400).json({ error: '受信者を指定してください' });
    }

    let receiverIds;
    try {
      receiverIds = typeof receivers === 'string' ? JSON.parse(receivers) : receivers;
    } catch (e) {
      return res.status(400).json({ error: '受信者リストの形式が不正です' });
    }

    if (!Array.isArray(receiverIds) || receiverIds.length === 0) {
      return res.status(400).json({ error: '受信者を少なくとも1人選択してください' });
    }

    const readStatus = receiverIds.map(id => ({
      user: id,
      isRead: false,
      readAt: null
    }));

    const newMessage = new Message({
      sender: senderId,
      receivers: receiverIds,
      messageType: 'text',
      textContent: textContent.trim(),
      readStatus
    });

    await newMessage.save();

    // プッシュ通知
    const sender = await User.findById(senderId).select('username');
    const receiversData = await User.find({ _id: { $in: receiverIds } }).select('fcmToken');
    const fcmTokens = receiversData.map(r => r.fcmToken).filter(Boolean);
    if (fcmTokens.length > 0) {
      try {
        await sendPushNotificationToMultiple(
          fcmTokens,
          {
            title: `${sender.username}から新しいメッセージ`,
            body: textContent.trim().length > 50
                ? textContent.trim().slice(0, 50) + '...'
                : textContent.trim(),
          },
          { messageId: newMessage._id.toString(), senderId, type: 'new_message' }
        );
      } catch (e) {
        console.error('プッシュ通知送信エラー:', e);
      }
    }

    res.status(201).json({ message: 'テキストメッセージを送信しました', messageId: newMessage._id });
  } catch (error) {
    console.error('テキストメッセージ送信エラー:', error);
    res.status(500).json({ error: 'テキストメッセージの送信に失敗しました' });
  }
};

// ========================================
// 受信メッセージリスト取得
// GET /messages/received
// ========================================
// 自分が受信したメッセージの一覧を取得します
// 
// 【処理フロー】
// ①自分がreceiversに含まれているメッセージを検索
// ②削除されていないメッセージのみ取得
// ③送信者の情報をpopulateで取得
// ④新しい順にソート
exports.getReceivedMessages = async (req, res) => {
  try {
    const userId = req.user.id;

    // 自分宛てのメッセージを検索
    const messages = await Message.find({
      receivers: userId,
      isDeleted: false
    })
      .populate('sender', 'username email profileImage')
      .sort({ sentAt: -1 }); // 新しい順

    // 各メッセージに対して、自分の既読状態を追加
    const messagesWithReadStatus = messages.map(msg => {
      const myReadStatus = msg.readStatus.find(
        status => status.user.toString() === userId
      );

      return {
        _id: msg._id,
        sender: msg.sender,
        filePath: msg.filePath,
        fileSize: msg.fileSize,
        duration: msg.duration,
        mimeType: msg.mimeType,
        sentAt: msg.sentAt,
        isRead: myReadStatus ? myReadStatus.isRead : false,
        readAt: myReadStatus ? myReadStatus.readAt : null
      };
    });

    res.json(messagesWithReadStatus);
  } catch (error) {
    console.error('受信メッセージ取得エラー:', error);
    res.status(500).json({ error: '受信メッセージの取得に失敗しました' });
  }
};

// ========================================
// 送信メッセージリスト取得
// GET /messages/sent
// ========================================
// 自分が送信したメッセージの一覧を取得します
exports.getSentMessages = async (req, res) => {
  try {
    const userId = req.user.id;

    // 自分が送信したメッセージを検索
    const messages = await Message.find({
      sender: userId,
      isDeleted: false
    })
      .populate('receivers', 'username email profileImage')
      .sort({ sentAt: -1 }); // 新しい順

    res.json(messages);
  } catch (error) {
    console.error('送信メッセージ取得エラー:', error);
    res.status(500).json({ error: '送信メッセージの取得に失敗しました' });
  }
};

// ========================================
// メッセージ既読
// PUT /messages/:id/read
// ========================================
// 指定したメッセージを既読にします
// 
// 【処理フロー】
// ①メッセージIDでメッセージを検索
// ②自分が受信者に含まれているか確認
// ③readStatusを更新（isRead: true, readAt: 現在時刻）
exports.markAsRead = async (req, res) => {
  try {
    const messageId = req.params.id;
    const userId = req.user.id;

    // メッセージを検索
    const message = await Message.findById(messageId);

    if (!message) {
      return res.status(404).json({ error: 'メッセージが見つかりません' });
    }

    // 自分が受信者に含まれているか確認
    if (!message.receivers.includes(userId)) {
      return res.status(403).json({ error: 'このメッセージにアクセスする権限がありません' });
    }

    // 既読状態を更新
    const readStatusIndex = message.readStatus.findIndex(
      status => status.user.toString() === userId
    );

    if (readStatusIndex !== -1) {
      message.readStatus[readStatusIndex].isRead = true;
      message.readStatus[readStatusIndex].readAt = new Date();
      await message.save();
    }

    res.json({ message: '既読にしました' });
  } catch (error) {
    console.error('既読更新エラー:', error);
    res.status(500).json({ error: '既読更新に失敗しました' });
  }
};

// ========================================
// メッセージ削除
// DELETE /messages/:id
// ========================================
// 指定したメッセージを削除します
// 
// 【処理フロー】
// ①ユーザーが削除対象か確認（送信者/受信者）
// ②削除者リストに追加
// ③全ユーザー（送信者＋全受信者）が削除したか判定
// ④全員削除の場合：ファイル物理削除 → レコード削除
// ⑤そうでない場合：論理削除フラグのみセット
exports.deleteMessage = async (req, res) => {
  try {
    const messageId = req.params.id;
    const userId = req.user.id;

    // メッセージを検索
    const message = await Message.findById(messageId);

    if (!message) {
      return res.status(404).json({ error: 'メッセージが見つかりません' });
    }

    // 送信者または受信者のみ削除可能
    const isSender = message.sender.toString() === userId;
    const isReceiver = message.receivers.includes(userId);

    if (!isSender && !isReceiver) {
      return res.status(403).json({ error: 'このメッセージを削除する権限がありません' });
    }

    // 削除者リストに追加（重複排除）
    if (!message.deletedBy.includes(userId)) {
      message.deletedBy.push(userId);
    }

    // 論理削除フラグを設定
    message.isDeleted = true;
    
    // 全ユーザー（送信者＋全受信者）が削除したかチェック
    const allUsersInvolved = [
      message.sender.toString(),
      ...message.receivers.map(r => r.toString())
    ];
    
    const uniqueAllUsers = [...new Set(allUsersInvolved)];
    const deletedUserIds = message.deletedBy.map(id => id.toString());
    
    const allUsersDeleted = uniqueAllUsers.every(userId => 
      deletedUserIds.includes(userId)
    );

    // 全員が削除した場合：ファイル物理削除 → レコード削除
    if (allUsersDeleted) {
      // ファイル物理削除
      if (fs.existsSync(message.filePath)) {
        try {
          fs.unlinkSync(message.filePath);
          console.log(`ファイル削除完了: ${message.filePath}`);
        } catch (fileError) {
          console.error(`ファイル削除失敗: ${message.filePath}`, fileError);
          // ファイル削除失敗してもメッセージレコードは削除する
        }
      }

      // 画像がある場合も削除
      if (message.attachedImage && fs.existsSync(message.attachedImage)) {
        try {
          fs.unlinkSync(message.attachedImage);
          console.log(`画像削除完了: ${message.attachedImage}`);
        } catch (fileError) {
          console.error(`画像削除失敗: ${message.attachedImage}`, fileError);
        }
      }

      // メッセージレコード削除
      await Message.deleteOne({ _id: messageId });

      return res.json({ 
        message: 'メッセージを削除しました',
        physicallyDeleted: true
      });
    }

    // 全員削除でない場合：論理削除フラグのみセット
    await message.save();

    res.json({ 
      message: 'メッセージを削除しました',
      physicallyDeleted: false
    });
  } catch (error) {
    console.error('メッセージ削除エラー:', error);
    res.status(500).json({ error: 'メッセージの削除に失敗しました' });
  }
};

// ========================================
// 音声ファイルダウンロード
// GET /messages/:id/download
// ========================================
// メッセージの音声ファイルをダウンロードします
exports.downloadMessage = async (req, res) => {
  try {
    const messageId = req.params.id;
    const userId = req.user.id;

    // メッセージを検索
    const message = await Message.findById(messageId);

    if (!message) {
      return res.status(404).json({ error: 'メッセージが見つかりません' });
    }

    // 送信者または受信者のみダウンロード可能
    const isSender = message.sender.toString() === userId;
    const isReceiver = message.receivers.includes(userId);

    if (!isSender && !isReceiver) {
      return res.status(403).json({ error: 'このメッセージにアクセスする権限がありません' });
    }

    // ファイルの存在確認
    if (!fs.existsSync(message.filePath)) {
      return res.status(404).json({ error: 'ファイルが見つかりません' });
    }

    // ファイルを送信
    res.download(message.filePath);
  } catch (error) {
    console.error('ファイルダウンロードエラー:', error);
    res.status(500).json({ error: 'ファイルのダウンロードに失敗しました' });
  }
};

// ========================================
// メッセージ検索
// GET /messages/search
// ========================================
// 受信メッセージを検索およびフィルタリングします
// 
// 【クエリパラメータ】
// - q: 検索文字列（送信者のユーザー名で検索）
// - dateFrom: 開始日時（ISO 8601形式）
// - dateTo: 終了日時（ISO 8601形式）
// - isRead: 既読フィルター（'true', 'false', または未指定）
// 
// 【処理フロー】
// ①クエリパラメータを取得
// ②検索条件を構築
// ③メッセージを検索して返す
exports.searchMessages = async (req, res) => {
  try {
    const userId = req.user.id;
    const { q, dateFrom, dateTo, isRead } = req.query;

    // 基本条件：自分宛てのメッセージで、削除されていないもの
    const query = {
      receivers: userId,
      isDeleted: false
    };

    // 日付範囲フィルター
    if (dateFrom || dateTo) {
      query.sentAt = {};
      if (dateFrom) {
        query.sentAt.$gte = new Date(dateFrom);
      }
      if (dateTo) {
        query.sentAt.$lte = new Date(dateTo);
      }
    }

    // メッセージを取得（送信者情報をpopulate）
    let messages = await Message.find(query)
      .populate('sender', 'username profileImage')
      .sort({ sentAt: -1 });

    // 送信者名で検索（クライアントサイドフィルタリング）
    if (q && q.trim()) {
      const searchTerm = q.trim().toLowerCase();
      messages = messages.filter(message => 
        message.sender.username.toLowerCase().includes(searchTerm)
      );
    }

    // 既読/未読フィルター
    if (isRead === 'true' || isRead === 'false') {
      const readFilter = isRead === 'true';
      messages = messages.filter(message => {
        const readStatus = message.readStatus.find(rs => rs.user.toString() === userId);
        return readStatus ? readStatus.isRead === readFilter : !readFilter;
      });
    }

    // レスポンスを整形
    const result = messages.map(message => {
      const readStatus = message.readStatus.find(rs => rs.user.toString() === userId);
      return {
        _id: message._id,
        sender: {
          _id: message.sender._id,
          username: message.sender.username,
          profileImage: message.sender.profileImage
        },
        filePath: message.filePath,
        fileSize: message.fileSize,
        duration: message.duration,
        mimeType: message.mimeType,
        sentAt: message.sentAt,
        isRead: readStatus ? readStatus.isRead : false,
        readAt: readStatus ? readStatus.readAt : null
      };
    });

    res.json(result);
  } catch (error) {
    console.error('メッセージ検索エラー:', error);
    res.status(500).json({ error: 'メッセージの検索に失敗しました' });
  }
};

// ========================================
// スレッド一覧取得（送信者ごとにグループ化）
// GET /messages/threads
// ========================================
// 受信メッセージを送信者ごとにグループ化して返します
// 
// 【レスポンス】
// - sender: 送信者情報
// - lastMessage: 最新メッセージ
// - unreadCount: 未読メッセージ数
// - totalCount: 総メッセージ数
// - lastMessageAt: 最終メッセージ日時
exports.getMessageThreads = async (req, res) => {
  try {
    const userId = req.user.id;

    // 自分が送信または受信したメッセージを全取得
    const messages = await Message.find({
      isDeleted: false,
      $or: [
        { receivers: userId },
        { sender: userId }
      ]
    })
      .populate('sender', 'username profileImage')
      .populate('receivers', 'username profileImage')
      .sort({ sentAt: -1 });

    // 相手ユーザーごとにグループ化
    const threadsMap = new Map();

    messages.forEach(message => {
      const senderId = message.sender._id.toString();
      const isMine = senderId === userId;

      // 相手のIDを特定
      let partnerId, partnerUsername, partnerProfileImage;
      if (isMine) {
        // 自分が送った → 受信者が相手（複数の場合は最初の1人）
        const partner = message.receivers.find(r => r && r._id && r._id.toString() !== userId);
        if (!partner) return;
        partnerId = partner._id.toString();
        partnerUsername = partner.username;
        partnerProfileImage = partner.profileImage;
      } else {
        // 相手が送ってきた → 送信者が相手
        partnerId = senderId;
        partnerUsername = message.sender.username;
        partnerProfileImage = message.sender.profileImage;
      }

      if (!threadsMap.has(partnerId)) {
        // 未読数（受信したメッセージのみカウント）
        const unreadCount = messages.filter(m => {
          if (m.sender._id.toString() !== partnerId) return false;
          if (!m.receivers.some(r => r && r._id && r._id.toString() === userId)) return false;
          const rs = m.readStatus.find(rs => rs.user.toString() === userId);
          return rs ? !rs.isRead : true;
        }).length;

        const totalCount = messages.filter(m => {
          const mid = m.sender._id.toString();
          const hasPartner = m.receivers.some(r => r && r._id && r._id.toString() === partnerId);
          const hasMe    = m.receivers.some(r => r && r._id && r._id.toString() === userId);
          return (mid === partnerId && hasMe) || (mid === userId && hasPartner);
        }).length;

        const readStatus = isMine ? null : message.readStatus.find(rs => rs.user.toString() === userId);
        threadsMap.set(partnerId, {
          sender: {
            _id: partnerId,
            username: partnerUsername,
            profileImage: partnerProfileImage
          },
          lastMessage: {
            _id: message._id,
            sentAt: message.sentAt,
            duration: message.duration,
            messageType: message.messageType || 'voice',
            textContent: message.textContent || null,
            isMine,
            isRead: isMine ? true : (readStatus ? readStatus.isRead : false)
          },
          unreadCount,
          totalCount,
          lastMessageAt: message.sentAt
        });
      }
    });

    const threads = Array.from(threadsMap.values()).sort((a, b) =>
      new Date(b.lastMessageAt) - new Date(a.lastMessageAt)
    );

    res.json(threads);
  } catch (error) {
    console.error('スレッド一覧取得エラー:', error);
    res.status(500).json({ error: 'スレッド一覧の取得に失敗しました' });
  }
};

// ========================================
// 特定の送信者からのメッセージ取得（双方向）
// GET /messages/thread/:partnerId
// ========================================
// 指定ユーザーとの会話（送受信両方）を取得します
exports.getThreadMessages = async (req, res) => {
  try {
    const userId = req.user.id;
    const partnerId = req.params.senderId;

    // 自分 → 相手、または 相手 → 自分のメッセージを取得
    const messages = await Message.find({
      isDeleted: false,
      $or: [
        { sender: userId,   receivers: partnerId },
        { sender: partnerId, receivers: userId   }
      ]
    })
      .populate('sender', 'username profileImage')
      .sort({ sentAt: 1 }); // 古い順（チャット表示用）

    const result = messages.map(message => {
      const isMine = message.sender._id.toString() === userId;
      let isRead, readAt;
      if (isMine) {
        // 自分が送ったメッセージ → 相手（partnerId）が既読したかを返す
        const receiverStatus = message.readStatus.find(
          rs => rs.user.toString() === partnerId
        );
        isRead = receiverStatus ? receiverStatus.isRead : false;
        readAt = receiverStatus ? receiverStatus.readAt : null;
      } else {
        // 相手から受信したメッセージ → 自分が既読したかを返す
        const myStatus = message.readStatus.find(
          rs => rs.user.toString() === userId
        );
        isRead = myStatus ? myStatus.isRead : false;
        readAt = myStatus ? myStatus.readAt : null;
      }
      return {
        _id: message._id,
        sender: {
          _id: message.sender._id,
          username: message.sender.username,
          profileImage: message.sender.profileImage
        },
        isMine,
        messageType: message.messageType || 'voice',
        textContent: message.textContent || null,
        filePath: message.filePath,
        fileSize: message.fileSize,
        duration: message.duration,
        mimeType: message.mimeType,
        sentAt: message.sentAt,
        isRead,
        readAt
      };
    });

    res.json(result);
  } catch (error) {
    console.error('スレッドメッセージ取得エラー:', error);
    res.status(500).json({ error: 'メッセージの取得に失敗しました' });
  }
};
