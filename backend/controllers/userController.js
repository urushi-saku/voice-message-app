// ========================================
// ユーザー関連コントローラー
// ========================================
// ユーザー検索、フォロー管理、フォロワーリスト取得の
// ビジネスロジックを処理します

const User = require('../models/User');
const Follower = require('../models/Follower');

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
      .select('username handle email profileImage bio followersCount followingCount')
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

    res.status(201).json({ message: 'フォローしました' });
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

    res.json({ message: 'フォローを解除しました' });
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
    const followerList = followers.map(f => f.follower);

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
    const followingList = following.map(f => f.user);

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

    const user = await User.findById(userId)
      .select('username handle email profileImage bio followersCount followingCount createdAt');

    if (!user) {
      return res.status(404).json({ error: 'ユーザーが見つかりません' });
    }

    res.json(user);
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
    ).select('username handle email profileImage bio followersCount followingCount');

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
    ).select('username email profileImage bio followersCount followingCount');

    res.json({
      message: 'プロフィール画像を更新しました',
      user: updatedUser
    });
  } catch (error) {
    console.error('プロフィール画像更新エラー:', error);
    res.status(500).json({ error: 'プロフィール画像の更新に失敗しました' });
  }
};
