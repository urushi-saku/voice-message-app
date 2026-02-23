// ========================================
// グループ関連コントローラー
// ========================================
// グループのCRUD操作・メンバー管理・グループメッセージの
// ビジネスロジックを処理します

const Group = require('../models/Group');
const Message = require('../models/Message');
const User = require('../models/User');
const { sendPushNotificationToMultiple } = require('../config/firebase');
const path = require('path');
const fs = require('fs');

// ========================================
// グループ一覧取得
// GET /groups
// ========================================
// 自分が参加しているグループ一覧を返します
exports.getMyGroups = async (req, res) => {
  try {
    const userId = req.user.id;

    const groups = await Group.find({ members: userId })
      .populate('admin', 'username handle profileImage')
      .populate('members', 'username handle profileImage')
      .sort({ updatedAt: -1 });

    // 各グループの最新メッセージと未読数を取得
    const groupsWithMeta = await Promise.all(
      groups.map(async (group) => {
        const [lastMessage, unreadCount] = await Promise.all([
          Message.findOne({ group: group._id, isDeleted: false })
            .sort({ sentAt: -1 })
            .populate('sender', 'username'),
          Message.countDocuments({
            group: group._id,
            isDeleted: false,
            'readStatus.user': userId,
            'readStatus.isRead': false,
          }),
        ]);

        return {
          _id: group._id,
          name: group.name,
          description: group.description,
          iconImage: group.iconImage,
          admin: group.admin,
          members: group.members,
          membersCount: group.members.length,
          lastMessage: lastMessage
            ? {
                messageType: lastMessage.messageType,
                textContent: lastMessage.textContent,
                senderUsername: lastMessage.sender?.username || '不明',
                sentAt: lastMessage.sentAt,
              }
            : null,
          unreadCount,
          createdAt: group.createdAt,
          updatedAt: group.updatedAt,
        };
      })
    );

    res.json({ groups: groupsWithMeta });
  } catch (error) {
    console.error('グループ一覧取得エラー:', error);
    res.status(500).json({ error: 'グループ一覧の取得に失敗しました' });
  }
};

// ========================================
// グループ詳細取得
// GET /groups/:id
// ========================================
exports.getGroupById = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const group = await Group.findById(id)
      .populate('admin', 'username handle profileImage')
      .populate('members', 'username handle profileImage');

    if (!group) {
      return res.status(404).json({ error: 'グループが見つかりません' });
    }

    // メンバーかどうか確認
    const isMember = group.members.some(
      (m) => m._id.toString() === userId
    );
    if (!isMember) {
      return res.status(403).json({ error: 'このグループのメンバーではありません' });
    }

    res.json({ group });
  } catch (error) {
    console.error('グループ詳細取得エラー:', error);
    res.status(500).json({ error: 'グループ詳細の取得に失敗しました' });
  }
};

// ========================================
// グループ作成
// POST /groups
// ========================================
// ボディ: { name, description, memberIds: [...] }
exports.createGroup = async (req, res) => {
  try {
    const adminId = req.user.id;
    const { name, description, memberIds } = req.body;

    if (!name || name.trim() === '') {
      return res.status(400).json({ error: 'グループ名は必須です' });
    }

    // memberIds を配列として取得（自分も自動的にメンバーに含める）
    let parsedMemberIds = [];
    if (memberIds) {
      try {
        parsedMemberIds = typeof memberIds === 'string'
          ? JSON.parse(memberIds)
          : memberIds;
      } catch {
        return res.status(400).json({ error: 'メンバーリストの形式が不正です' });
      }
    }

    // 自分が含まれていない場合は追加
    const allMemberIds = [...new Set([adminId, ...parsedMemberIds])];

    // グループアイコン画像
    const iconFile = req.file || null;

    const group = await Group.create({
      name: name.trim(),
      description: description?.trim() || '',
      iconImage: iconFile ? iconFile.path : null,
      admin: adminId,
      members: allMemberIds,
    });

    const populated = await group.populate([
      { path: 'admin', select: 'username handle profileImage' },
      { path: 'members', select: 'username handle profileImage' },
    ]);

    res.status(201).json({
      message: 'グループを作成しました',
      group: populated,
    });
  } catch (error) {
    console.error('グループ作成エラー:', error);
    res.status(500).json({ error: 'グループの作成に失敗しました' });
  }
};

// ========================================
// グループ情報更新
// PUT /groups/:id
// ========================================
// ボディ: { name, description }
exports.updateGroup = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;
    const { name, description } = req.body;

    const group = await Group.findById(id);
    if (!group) {
      return res.status(404).json({ error: 'グループが見つかりません' });
    }

    // 管理者のみ更新可能
    if (group.admin.toString() !== userId) {
      return res.status(403).json({ error: 'グループ管理者のみ編集できます' });
    }

    if (name !== undefined) group.name = name.trim();
    if (description !== undefined) group.description = description.trim();

    // アイコン画像更新
    if (req.file) {
      // 古いアイコンを削除
      if (group.iconImage && fs.existsSync(group.iconImage)) {
        fs.unlinkSync(group.iconImage);
      }
      group.iconImage = req.file.path;
    }

    await group.save();

    const populated = await group.populate([
      { path: 'admin', select: 'username handle profileImage' },
      { path: 'members', select: 'username handle profileImage' },
    ]);

    res.json({ message: 'グループを更新しました', group: populated });
  } catch (error) {
    console.error('グループ更新エラー:', error);
    res.status(500).json({ error: 'グループの更新に失敗しました' });
  }
};

// ========================================
// グループ削除
// DELETE /groups/:id
// ========================================
exports.deleteGroup = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const group = await Group.findById(id);
    if (!group) {
      return res.status(404).json({ error: 'グループが見つかりません' });
    }

    // 管理者のみ削除可能
    if (group.admin.toString() !== userId) {
      return res.status(403).json({ error: 'グループ管理者のみ削除できます' });
    }

    // グループアイコン削除
    if (group.iconImage && fs.existsSync(group.iconImage)) {
      fs.unlinkSync(group.iconImage);
    }

    // グループメッセージの音声ファイルを物理削除
    const groupMessages = await Message.find({ group: id, filePath: { $ne: null } });
    for (const msg of groupMessages) {
      if (msg.filePath && fs.existsSync(msg.filePath)) {
        fs.unlinkSync(msg.filePath);
      }
    }

    // グループメッセージを削除
    await Message.deleteMany({ group: id });

    // グループを削除
    await Group.findByIdAndDelete(id);

    res.json({ message: 'グループを削除しました' });
  } catch (error) {
    console.error('グループ削除エラー:', error);
    res.status(500).json({ error: 'グループの削除に失敗しました' });
  }
};

// ========================================
// メンバー追加
// POST /groups/:id/members
// ========================================
// ボディ: { userId }
exports.addMember = async (req, res) => {
  try {
    const adminId = req.user.id;
    const { id } = req.params;
    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({ error: 'ユーザーIDは必須です' });
    }

    const group = await Group.findById(id);
    if (!group) {
      return res.status(404).json({ error: 'グループが見つかりません' });
    }

    // 管理者のみ追加可能
    if (group.admin.toString() !== adminId) {
      return res.status(403).json({ error: 'グループ管理者のみメンバーを追加できます' });
    }

    // すでにメンバーか確認
    if (group.members.map((m) => m.toString()).includes(userId)) {
      return res.status(400).json({ error: 'すでにグループのメンバーです' });
    }

    // ユーザー存在確認
    const user = await User.findById(userId).select('username');
    if (!user) {
      return res.status(404).json({ error: 'ユーザーが見つかりません' });
    }

    group.members.push(userId);
    await group.save();

    res.json({ message: `${user.username} をグループに追加しました` });
  } catch (error) {
    console.error('メンバー追加エラー:', error);
    res.status(500).json({ error: 'メンバーの追加に失敗しました' });
  }
};

// ========================================
// メンバー削除
// DELETE /groups/:id/members/:userId
// ========================================
exports.removeMember = async (req, res) => {
  try {
    const requesterId = req.user.id;
    const { id, userId } = req.params;

    const group = await Group.findById(id);
    if (!group) {
      return res.status(404).json({ error: 'グループが見つかりません' });
    }

    // 管理者が削除する か 自分が退出する場合のみ許可
    const isAdmin = group.admin.toString() === requesterId;
    const isSelf = userId === requesterId;

    if (!isAdmin && !isSelf) {
      return res.status(403).json({ error: '管理者のみ他のメンバーを削除できます' });
    }

    // 管理者自身は退出不可
    if (isSelf && group.admin.toString() === userId) {
      return res.status(400).json({ error: '管理者はグループから退出できません。先に管理者を変更してください' });
    }

    group.members = group.members.filter((m) => m.toString() !== userId);
    await group.save();

    res.json({ message: 'メンバーをグループから削除しました' });
  } catch (error) {
    console.error('メンバー削除エラー:', error);
    res.status(500).json({ error: 'メンバーの削除に失敗しました' });
  }
};

// ========================================
// グループメッセージ一覧取得
// GET /groups/:id/messages?page=1&limit=30
// ========================================
exports.getGroupMessages = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;
    const page  = Math.max(1, parseInt(req.query.page)  || 1);
    const limit = Math.min(100, parseInt(req.query.limit) || 30);
    const skip  = (page - 1) * limit;

    // グループ存在確認・メンバー確認
    const group = await Group.findById(id);
    if (!group) {
      return res.status(404).json({ error: 'グループが見つかりません' });
    }
    const isMember = group.members.map((m) => m.toString()).includes(userId);
    if (!isMember) {
      return res.status(403).json({ error: 'このグループのメンバーではありません' });
    }

    const [messages, total] = await Promise.all([
      Message.find({ group: id, isDeleted: false })
        .populate('sender', 'username handle profileImage')
        .sort({ sentAt: -1 })
        .skip(skip)
        .limit(limit),
      Message.countDocuments({ group: id, isDeleted: false }),
    ]);

    const result = messages.reverse().map((msg) => ({
      _id: msg._id,
      sender: {
        _id: msg.sender._id,
        username: msg.sender.username,
        handle: msg.sender.handle,
        profileImage: msg.sender.profileImage,
      },
      messageType: msg.messageType,
      textContent: msg.textContent,
      filePath: msg.filePath,
      fileSize: msg.fileSize,
      duration: msg.duration,
      mimeType: msg.mimeType,
      sentAt: msg.sentAt,
      isMine: msg.sender._id.toString() === userId,
      isRead: msg.readStatus.some(
        (rs) => rs.user.toString() === userId && rs.isRead
      ),
    }));

    res.json({
      messages: result,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
        hasNext: page * limit < total,
      },
    });
  } catch (error) {
    console.error('グループメッセージ取得エラー:', error);
    res.status(500).json({ error: 'グループメッセージの取得に失敗しました' });
  }
};

// ========================================
// グループテキストメッセージ送信
// POST /groups/:id/messages/text
// ========================================
// ボディ: { textContent }
exports.sendGroupTextMessage = async (req, res) => {
  try {
    const senderId = req.user.id;
    const { id } = req.params;
    const { textContent } = req.body;

    if (!textContent || textContent.trim() === '') {
      return res.status(400).json({ error: 'メッセージ本文は必須です' });
    }

    const group = await Group.findById(id).populate('members', '_id fcmTokens');
    if (!group) {
      return res.status(404).json({ error: 'グループが見つかりません' });
    }

    const isMember = group.members.map((m) => m._id.toString()).includes(senderId);
    if (!isMember) {
      return res.status(403).json({ error: 'このグループのメンバーではありません' });
    }

    // 自分以外のメンバーが受信者
    const receiverIds = group.members
      .filter((m) => m._id.toString() !== senderId)
      .map((m) => m._id);

    const readStatus = receiverIds.map((uid) => ({
      user: uid,
      isRead: false,
      readAt: null,
    }));

    const newMessage = await Message.create({
      sender: senderId,
      receivers: receiverIds,
      group: id,
      messageType: 'text',
      textContent: textContent.trim(),
      readStatus,
    });

    res.status(201).json({
      message: 'メッセージを送信しました',
      messageId: newMessage._id,
    });

    // プッシュ通知（バックグラウンド）
    const sender = await User.findById(senderId).select('username');
    const fcmTokens = group.members
      .filter((m) => m._id.toString() !== senderId && m.fcmTokens?.length)
      .flatMap((m) => m.fcmTokens);

    if (fcmTokens.length > 0) {
      sendPushNotificationToMultiple(fcmTokens, {
        title: `${group.name}`,
        body: `${sender?.username || '誰か'}: ${textContent.trim().substring(0, 50)}`,
        data: { type: 'group_message', groupId: id },
      }).catch((err) => console.error('グループ通知送信エラー:', err));
    }
  } catch (error) {
    console.error('グループテキスト送信エラー:', error);
    res.status(500).json({ error: 'グループメッセージの送信に失敗しました' });
  }
};

// ========================================
// グループ音声メッセージ送信
// POST /groups/:id/messages/voice (multipart/form-data)
// ========================================
exports.sendGroupVoiceMessage = async (req, res) => {
  try {
    const senderId = req.user.id;
    const { id } = req.params;
    const { duration } = req.body;
    const file = req.file;

    if (!file) {
      return res.status(400).json({ error: '音声ファイルをアップロードしてください' });
    }

    const group = await Group.findById(id).populate('members', '_id fcmTokens');
    if (!group) {
      return res.status(404).json({ error: 'グループが見つかりません' });
    }

    const isMember = group.members.map((m) => m._id.toString()).includes(senderId);
    if (!isMember) {
      return res.status(403).json({ error: 'このグループのメンバーではありません' });
    }

    const receiverIds = group.members
      .filter((m) => m._id.toString() !== senderId)
      .map((m) => m._id);

    const readStatus = receiverIds.map((uid) => ({
      user: uid,
      isRead: false,
      readAt: null,
    }));

    const newMessage = await Message.create({
      sender: senderId,
      receivers: receiverIds,
      group: id,
      messageType: 'voice',
      filePath: file.path,
      fileSize: file.size,
      duration: duration ? parseInt(duration) : null,
      mimeType: file.mimetype,
      readStatus,
    });

    res.status(201).json({
      message: 'ボイスメッセージを送信しました',
      messageId: newMessage._id,
    });

    // プッシュ通知（バックグラウンド）
    const sender = await User.findById(senderId).select('username');
    const fcmTokens = group.members
      .filter((m) => m._id.toString() !== senderId && m.fcmTokens?.length)
      .flatMap((m) => m.fcmTokens);

    if (fcmTokens.length > 0) {
      sendPushNotificationToMultiple(fcmTokens, {
        title: `${group.name}`,
        body: `${sender?.username || '誰か'} がボイスメッセージを送信しました 🎤`,
        data: { type: 'group_message', groupId: id },
      }).catch((err) => console.error('グループ通知送信エラー:', err));
    }
  } catch (error) {
    console.error('グループ音声送信エラー:', error);
    res.status(500).json({ error: 'グループボイスメッセージの送信に失敗しました' });
  }
};

// ========================================
// グループメッセージ既読
// PUT /groups/:id/messages/:messageId/read
// ========================================
exports.markGroupMessageRead = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id, messageId } = req.params;

    const message = await Message.findOne({ _id: messageId, group: id });
    if (!message) {
      return res.status(404).json({ error: 'メッセージが見つかりません' });
    }

    const entry = message.readStatus.find(
      (rs) => rs.user.toString() === userId
    );
    if (entry && !entry.isRead) {
      entry.isRead = true;
      entry.readAt = new Date();
      await message.save();
    }

    res.json({ message: '既読にしました' });
  } catch (error) {
    console.error('グループ既読エラー:', error);
    res.status(500).json({ error: '既読処理に失敗しました' });
  }
};
