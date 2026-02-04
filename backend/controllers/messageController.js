// ========================================
// メッセージ関連コントローラー
// ========================================
// 音声メッセージの送信、受信リスト取得、既読管理の
// ビジネスロジックを処理します

const Message = require('../models/Message');
const User = require('../models/User');
const Follower = require('../models/Follower');
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
// 指定したメッセージを削除します（論理削除）
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

    // 論理削除
    message.isDeleted = true;
    await message.save();

    res.json({ message: 'メッセージを削除しました' });
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
