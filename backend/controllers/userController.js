// ========================================
// ユーザー関連コントローラー
// ========================================
// ユーザー検索、フォロー管理、フォロワーリスト取得の
// ビジネスロジックを処理します

const User = require('../models/User');
const Follower = require('../models/Follower');
const Message = require('../models/Message');
const fs = require('fs').promises;
const cache = require('../utils/cache');

// ========================================
// ユーザー一覧取得
// GET /users?page=1&limit=20&q=
// ========================================
// ページング付き全ユーザー一覧。q を渡すと handle/username で絞り込み。
// 自分自身は除外します。
exports.getUsers = async (req, res) => {
  try {
    const currentUserId = req.user.id;
    const page  = Math.max(1, parseInt(req.query.page)  || 1);
    const limit = Math.min(50, parseInt(req.query.limit) || 20);
    const q     = req.query.q?.trim();
    const skip  = (page - 1) * limit;

    // キャッシュチェック（ユーザー・ページ・クエリごとに区別）
    const cacheKey = `users:${currentUserId}:p${page}:l${limit}:q${q || ''}`;
    const cachedUsers = await cache.get(cacheKey);
    if (cachedUsers) return res.json(cachedUsers);

    const filter = { _id: { $ne: currentUserId } };
    if (q) {
      filter.$or = [
        { handle:   { $regex: q, $options: 'i' } },
        { username: { $regex: q, $options: 'i' } },
      ];
    }

    const [users, total] = await Promise.all([
      User.find(filter)
        .select('username handle profileImage headerImage bio followersCount followingCount')
        .sort({ followersCount: -1, createdAt: -1 })
        .skip(skip)
        .limit(limit),
      User.countDocuments(filter),
    ]);

    const result = {
      users: users.map(u => ({
        _id: u._id.toString(),
        username: u.username,
        handle: u.handle,
        profileImage: u.profileImage,
        headerImage: u.headerImage,
        bio: u.bio,
        followersCount: u.followersCount,
        followingCount: u.followingCount,
      })),
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
        hasNext: page * limit < total,
      },
    };
    await cache.set(cacheKey, result, cache.TTL.USERS_LIST);
    res.json(result);
  } catch (error) {
    console.error('ユーザー一覧取得エラー:', error);
    res.status(500).json({ error: 'ユーザー一覧の取得に失敗しました' });
  }
};

// ========================================
// アカウント削除
// DELETE /users/:id
// ========================================
// 自分のアカウントのみ削除可能。
// 関連データ（フォロー関係・メッセージ・プロフィール画像）を一括削除します。
exports.deleteAccount = async (req, res) => {
  try {
    const targetId    = req.params.id;
    const currentUserId = req.user.id;

    // 自分のアカウントのみ削除可能
    if (targetId !== currentUserId) {
      return res.status(403).json({ error: '他のユーザーのアカウントは削除できません' });
    }

    const user = await User.findById(currentUserId);
    if (!user) {
      return res.status(404).json({ error: 'ユーザーが見つかりません' });
    }

    // プロフィール画像の物理削除
    if (user.profileImage) {
      try { await fs.unlink(user.profileImage); } catch (_) {}
    }
    // ヘッダー画像の物理削除
    if (user.headerImage) {
      try { await fs.unlink(user.headerImage); } catch (_) {}
    }

    // 自分が送信した音声ファイルの物理削除
    const sentMessages = await Message.find({ sender: currentUserId, filePath: { $ne: null } });
    for (const msg of sentMessages) {
      try { await fs.unlink(msg.filePath); } catch (_) {}
    }

    // 関連データを並行削除
    await Promise.all([
      Follower.deleteMany({ $or: [{ user: currentUserId }, { follower: currentUserId }] }),
      Message.deleteMany({ $or: [{ sender: currentUserId }, { 'receivers': currentUserId }] }),
    ]);

    // フォロワー/フォロー数のカウント補正
    // 自分をフォローしていた人の followingCount を -1
    // 自分がフォローしていた人の followersCount を -1
    const [myFollowers, myFollowing] = await Promise.all([
      Follower.find({ user: currentUserId }).select('follower'),
      Follower.find({ follower: currentUserId }).select('user'),
    ]);
    const followerIds = myFollowers.map(f => f.follower);
    const followingIds = myFollowing.map(f => f.user);
    await Promise.all([
      User.updateMany({ _id: { $in: followerIds  } }, { $inc: { followingCount: -1 } }),
      User.updateMany({ _id: { $in: followingIds } }, { $inc: { followersCount: -1 } }),
    ]);

    // ユーザー本体を削除
    await User.findByIdAndDelete(currentUserId);

    res.json({ success: true, message: 'アカウントを削除しました' });
  } catch (error) {
    console.error('アカウント削除エラー:', error);
    res.status(500).json({ error: 'アカウントの削除に失敗しました' });
  }
};

// ========================================
// ユーザー検索
// GET /users/search?q=username
// ========================================
// クエリパラメータ「q」でユーザー名を部分一致検索します
// 自分自身は検索結果から除外します
exports.searchUsers = async (req, res) => {
  try {
    const { q } = req.query;
    const currentUserId = req.user.id;

    if (!q || q.trim() === '') {
      return res.status(400).json({ error: '検索キーワードを入力してください' });
    }

    // handleまたはusernameで部分一致検索（自分以外）
    const users = await User.find({
      _id: { $ne: currentUserId },
      $or: [
        { handle:   { $regex: q, $options: 'i' } },
        { username: { $regex: q, $options: 'i' } },
      ]
    })
      .select('username handle email profileImage headerImage bio followersCount followingCount')
      .limit(20);

    res.json(users);
  } catch (error) {
    console.error('ユーザー検索エラー:', error);
    res.status(500).json({ error: 'ユーザー検索に失敗しました' });
  }
};

// ========================================
// フォローする
// POST /users/:id/follow
// ========================================
// パラメータで指定されたユーザーをフォローします
// 既にフォロー済みの場合はエラーを返します
exports.followUser = async (req, res) => {
  try {
    const targetUserId = req.params.id; // フォローしたいユーザーのID
    const currentUserId = req.user.id;   // 自分のID

    // 自分自身をフォローしようとした場合
    if (targetUserId === currentUserId) {
      return res.status(400).json({ error: '自分自身をフォローできません' });
    }

    // フォロー対象のユーザーが存在するか確認
    const targetUser = await User.findById(targetUserId);
    if (!targetUser) {
      return res.status(404).json({ error: 'ユーザーが見つかりません' });
    }

    // 既にフォロー済みか確認
    const existingFollow = await Follower.findOne({
      user: targetUserId,
      follower: currentUserId
    });

    if (existingFollow) {
      return res.status(400).json({ error: '既にフォローしています' });
    }

    // フォロー関係を作成
    const newFollow = new Follower({
      user: targetUserId,     // フォローされる人
      follower: currentUserId // フォローする人
    });
    await newFollow.save();

    // フォロー数・フォロワー数を更新
    await User.findByIdAndUpdate(targetUserId, {
      $inc: { followersCount: 1 } // フォローされた人のフォロワー数+1
    });
    await User.findByIdAndUpdate(currentUserId, {
      $inc: { followingCount: 1 } // フォローした人のフォロー中数+1
    });

    // フォロー後にキャッシュを無効化
    await cache.del(
      `followers:${targetUserId}`,
      `following:${currentUserId}`,
      `user:${targetUserId}`,
      `user:${currentUserId}`,
    );

    res.status(200).json({ success: true, message: 'フォローしました' });
  } catch (error) {
    console.error('フォローエラー:', error);
    res.status(500).json({ error: 'フォローに失敗しました' });
  }
};

// ========================================
// フォロー解除
// DELETE /users/:id/follow
// ========================================
// パラメータで指定されたユーザーのフォローを解除します
exports.unfollowUser = async (req, res) => {
  try {
    const targetUserId = req.params.id; // フォロー解除したいユーザーのID
    const currentUserId = req.user.id;   // 自分のID

    // フォロー関係を検索
    const followRelation = await Follower.findOne({
      user: targetUserId,
      follower: currentUserId
    });

    if (!followRelation) {
      return res.status(400).json({ error: 'フォローしていません' });
    }

    // フォロー関係を削除
    await Follower.deleteOne({ _id: followRelation._id });

    // フォロー数・フォロワー数を更新
    await User.findByIdAndUpdate(targetUserId, {
      $inc: { followersCount: -1 } // フォロワー数-1
    });
    await User.findByIdAndUpdate(currentUserId, {
      $inc: { followingCount: -1 } // フォロー中数-1
    });

    // フォロー解除後にキャッシュを無効化
    await cache.del(
      `followers:${targetUserId}`,
      `following:${currentUserId}`,
      `user:${targetUserId}`,
      `user:${currentUserId}`,
    );

    res.json({ success: true, message: 'フォローを解除しました' });
  } catch (error) {
    console.error('フォロー解除エラー:', error);
    res.status(500).json({ error: 'フォロー解除に失敗しました' });
  }
};

// ========================================
// フォロワーリスト取得
// GET /users/:id/followers
// ========================================
// パラメータで指定されたユーザーのフォロワー一覧を取得します
exports.getFollowers = async (req, res) => {
  try {
    const userId = req.params.id;

    // キャッシュチェック
    const cacheKey = `followers:${userId}`;
    const cached = await cache.get(cacheKey);
    if (cached) return res.json(cached);

    // ユーザーが存在するか確認
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ error: 'ユーザーが見つかりません' });
    }

    // フォロワーリストを取得
    // Followerテーブルから、userがuserIdのレコードを検索し、
    // followerフィールドをpopulateして詳細情報を取得
    const followers = await Follower.find({ user: userId })
      .populate('follower', 'username handle email profileImage bio followersCount followingCount')
      .sort({ followedAt: -1 }); // 新しい順

    // followerフィールドの情報のみを抽出
    const followerList = followers.map(f => ({
      _id: f.follower._id.toString(),
      username: f.follower.username,
      handle: f.follower.handle,
      email: f.follower.email,
      profileImage: f.follower.profileImage,
      bio: f.follower.bio,
      followersCount: f.follower.followersCount,
      followingCount: f.follower.followingCount,
    }));

    await cache.set(cacheKey, followerList, cache.TTL.FOLLOWERS);
    res.json(followerList);
  } catch (error) {
    console.error('フォロワーリスト取得エラー:', error);
    res.status(500).json({ error: 'フォロワーリストの取得に失敗しました' });
  }
};

// ========================================
// フォロー中リスト取得
// GET /users/:id/following
// ========================================
// パラメータで指定されたユーザーがフォロー中のユーザー一覧を取得します
exports.getFollowing = async (req, res) => {
  try {
    const userId = req.params.id;

    // キャッシュチェック
    const cacheKey = `following:${userId}`;
    const cached = await cache.get(cacheKey);
    if (cached) return res.json(cached);

    // ユーザーが存在するか確認
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ error: 'ユーザーが見つかりません' });
    }

    // フォロー中リストを取得
    // Followerテーブルから、followerがuserIdのレコードを検索し、
    // userフィールドをpopulateして詳細情報を取得
    const following = await Follower.find({ follower: userId })
      .populate('user', 'username handle email profileImage bio followersCount followingCount')
      .sort({ followedAt: -1 }); // 新しい順

    // userフィールドの情報のみを抽出
    const followingList = following.map(f => ({
      _id: f.user._id.toString(),
      username: f.user.username,
      handle: f.user.handle,
      email: f.user.email,
      profileImage: f.user.profileImage,
      bio: f.user.bio,
      followersCount: f.user.followersCount,
      followingCount: f.user.followingCount,
    }));

    await cache.set(cacheKey, followingList, cache.TTL.FOLLOWERS);
    res.json(followingList);
  } catch (error) {
    console.error('フォロー中リスト取得エラー:', error);
    res.status(500).json({ error: 'フォロー中リストの取得に失敗しました' });
  }
};

// ========================================
// ユーザー詳細取得
// GET /users/:id
// ========================================
// パラメータで指定されたユーザーの詳細情報を取得します
exports.getUserById = async (req, res) => {
  try {
    const userId = req.params.id;

    // キャッシュチェック
    const cacheKey = `user:${userId}`;
    const cached = await cache.get(cacheKey);
    if (cached) return res.json(cached);

    const user = await User.findById(userId)
      .select('username handle email profileImage headerImage bio followersCount followingCount createdAt');

    if (!user) {
      return res.status(404).json({ error: 'ユーザーが見つかりません' });
    }

    const userWithStringId = {
      _id: user._id.toString(),
      username: user.username,
      handle: user.handle,
      email: user.email,
      profileImage: user.profileImage,
      headerImage: user.headerImage,
      bio: user.bio,
      followersCount: user.followersCount,
      followingCount: user.followingCount,
      createdAt: user.createdAt,
    };
    await cache.set(cacheKey, userWithStringId, cache.TTL.USER);
    res.json(userWithStringId);
  } catch (error) {
    console.error('ユーザー詳細取得エラー:', error);
    res.status(500).json({ error: 'ユーザー情報の取得に失敗しました' });
  }
};

// ========================================
// プロフィール更新
// PUT /users/profile
// ========================================
// 自分のプロフィール情報（username, bio）を更新します
exports.updateProfile = async (req, res) => {
  try {
    const currentUserId = req.user.id;
    const { username, handle, bio } = req.body;

    // 更新するフィールドを構築
    const updateFields = {};
    
    if (username !== undefined) {
      // ユーザー名のバリデーション
      if (username.trim().length < 1) {
        return res.status(400).json({ error: 'ユーザー名を入力してください' });
      }
      if (username.trim().length > 30) {
        return res.status(400).json({ error: 'ユーザー名は30文字以内で設定してください' });
      }
      updateFields.username = username.trim();
    }

    if (handle !== undefined) {
      const handleLower = handle.toLowerCase().trim();
      if (!/^[a-z0-9_]{3,20}$/.test(handleLower)) {
        return res.status(400).json({ error: 'IDは英小文字・数字・_の3〜20文字で入力してください' });
      }
      // handleの重複チェック（自分以外）
      const existingHandle = await User.findOne({
        handle: handleLower,
        _id: { $ne: currentUserId }
      });
      if (existingHandle) {
        return res.status(400).json({ error: 'このIDは既に使用されています' });
      }
      updateFields.handle = handleLower;
    }

    if (bio !== undefined) {
      // 自己紹介のバリデーション
      if (bio.length > 200) {
        return res.status(400).json({ error: '自己紹介は200文字以内で設定してください' });
      }
      updateFields.bio = bio;
    }

    // 更新するフィールドがない場合
    if (Object.keys(updateFields).length === 0) {
      return res.status(400).json({ error: '更新する情報がありません' });
    }

    // プロフィール更新
    const updatedUser = await User.findByIdAndUpdate(
      currentUserId,
      { $set: updateFields },
      { new: true, runValidators: true }
    ).select('username handle email profileImage headerImage bio followersCount followingCount');

    // プロフィール更新後にキャッシュを無効化
    await cache.del(`user:${currentUserId}`);

    res.json({
      message: 'プロフィールを更新しました',
      user: updatedUser
    });
  } catch (error) {
    console.error('プロフィール更新エラー:', error);
    if (error.code === 11000) {
      return res.status(400).json({ error: 'このユーザー名は既に使用されています' });
    }
    res.status(500).json({ error: 'プロフィールの更新に失敗しました' });
  }
};

// ========================================
// プロフィール画像更新
// PUT /users/profile/image
// ========================================
// 自分のプロフィール画像を更新します（multerミドルウェアで処理）
exports.updateProfileImage = async (req, res) => {
  try {
    const currentUserId = req.user.id;

    // ファイルがアップロードされたか確認
    if (!req.file) {
      return res.status(400).json({ error: 'プロフィール画像ファイルが必要です' });
    }

    // ファイルパスを取得（uploadsディレクトリからの相対パス）
    const profileImagePath = req.file.path.replace(/\\/g, '/'); // Windowsパス対策

    // 古いプロフィール画像がある場合は削除
    const user = await User.findById(currentUserId);
    if (user.profileImage) {
      const fs = require('fs').promises;
      const oldImagePath = user.profileImage;
      try {
        await fs.unlink(oldImagePath);
      } catch (err) {
        console.log('古いプロフィール画像の削除に失敗:', err.message);
      }
    }

    // プロフィール画像のパスを更新
    const updatedUser = await User.findByIdAndUpdate(
      currentUserId,
      { $set: { profileImage: profileImagePath } },
      { new: true }
    ).select('username email profileImage headerImage bio followersCount followingCount');

    // プロフィール画像更新後にキャッシュを無効化
    await cache.del(`user:${currentUserId}`);

    res.json({
      message: 'プロフィール画像を更新しました',
      user: updatedUser
    });
  } catch (error) {
    console.error('プロフィール画像更新エラー:', error);
    res.status(500).json({ error: 'プロフィール画像の更新に失敗しました' });
  }
};

// ========================================
// ヘッダー画像更新
// PUT /users/profile/header-image
// ========================================
exports.updateHeaderImage = async (req, res) => {
  try {
    const currentUserId = req.user.id;

    if (!req.file) {
      return res.status(400).json({ error: 'ヘッダー画像ファイルが必要です' });
    }

    const headerImagePath = req.file.path.replace(/\\/g, '/');

    // 古いヘッダー画像があれば削除
    const user = await User.findById(currentUserId);
    if (user.headerImage) {
      try { await require('fs').promises.unlink(user.headerImage); } catch (_) {}
    }

    const updatedUser = await User.findByIdAndUpdate(
      currentUserId,
      { $set: { headerImage: headerImagePath } },
      { new: true }
    ).select('username email profileImage headerImage bio followersCount followingCount');

    await cache.del(`user:${currentUserId}`);

    res.json({
      message: 'ヘッダー画像を更新しました',
      user: updatedUser
    });
  } catch (error) {
    console.error('ヘッダー画像更新エラー:', error);
    res.status(500).json({ error: 'ヘッダー画像の更新に失敗しました' });
  }
};

// ========================================
// E2EE 公開鍵を登録 / 更新
// PUT /users/public-key
// ========================================
// クライアントで生成した X25519 公開鍵（Base64）をサーバーに保存する
// 秘密鍵はデバイスのSecureStorageにのみ保管し、サーバーには送らない
exports.updatePublicKey = async (req, res) => {
  try {
    const { publicKey } = req.body;
    if (!publicKey) {
      return res.status(400).json({ error: '公開鍵が指定されていません' });
    }

    await User.findByIdAndUpdate(req.user.id, { publicKey });

    res.json({ message: '公開鍵を更新しました' });
  } catch (error) {
    console.error('公開鍵更新エラー:', error);
    res.status(500).json({ error: '公開鍵の更新に失敗しました' });
  }
};

// ========================================
// ユーザーの公開鍵を取得
// GET /users/:id/public-key
// ========================================
// メッセージ送信前に受信者の公開鍵を取得するために使用
exports.getPublicKey = async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('publicKey');
    if (!user) {
      return res.status(404).json({ error: 'ユーザーが見つかりません' });
    }
    res.json({ publicKey: user.publicKey });
  } catch (error) {
    console.error('公開鍵取得エラー:', error);
    res.status(500).json({ error: '公開鍵の取得に失敗しました' });
  }
};
