// ========================================
// 認証コントローラー
// ========================================
// ユーザー登録・ログイン・認証処理を管理

const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const nodemailer = require('nodemailer');
const User = require('../models/User');

// ========================================
// ユーティリティ: メール送信
// ========================================
const sendEmail = async ({ to, subject, html }) => {
  // SMTP設定が未設定の場合はコンソールに出力（開発時用）
  if (!process.env.SMTP_HOST || !process.env.SMTP_USER) {
    console.log('==== [DEV] Email not sent (SMTP unconfigured) ====');
    console.log(`To: ${to}`);
    console.log(`Subject: ${subject}`);
    console.log(html.replace(/<[^>]+>/g, ''));
    console.log('=================================================');
    return;
  }

  const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: parseInt(process.env.SMTP_PORT || '587'),
    secure: process.env.SMTP_SECURE === 'true',
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
  });

  await transporter.sendMail({
    from: `"Voice Message App" <${process.env.SMTP_USER}>`,
    to,
    subject,
    html,
  });
};

// ========================================
// ユーティリティ: リフレッシュトークン生成
// ========================================
const generateRefreshToken = () => crypto.randomBytes(40).toString('hex');

// ========================================
// ユーティリティ: アクセストークン生成
// ========================================
const generateAccessToken = (userId) =>
  jwt.sign({ id: userId }, process.env.JWT_SECRET, { expiresIn: '30d' });


/**
 * ユーザー登録
 * POST /auth/register
 */
exports.register = async (req, res) => {
  try {
    const { username, handle, email, password } = req.body;

    // 入力チェック
    if (!username || !email || !password) {
      return res.status(400).json({
        success: false,
        error: 'ユーザー名、メールアドレス、パスワードは必須です',
        message: 'ユーザー名、メールアドレス、パスワードは必須です',
      });
    }

    // 重複するusernameをチェック
    const existingUsername = await User.findOne({ username });
    if (existingUsername) {
      return res.status(400).json({
        success: false,
        error: 'usernameは既に存在します',
        message: 'usernameは既に存在します',
      });
    }

    // 重複するemailをチェック
    const existingEmail = await User.findOne({ email });
    if (existingEmail) {
      return res.status(400).json({
        success: false,
        error: 'emailは既に存在します',
        message: 'emailは既に存在します',
      });
    }

    // handle の生成（送信されていない場合はランダム生成）
    const generateRandomHandle = async () => {
      const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
      for (let attempt = 0; attempt < 10; attempt++) {
        const suffix = Array.from({ length: 8 }, () =>
          chars[Math.floor(Math.random() * chars.length)]
        ).join('');
        const candidate = `user_${suffix}`;
        const exists = await User.findOne({ handle: candidate });
        if (!exists) return candidate;
      }
      throw new Error('handleの生成に失敗しました');
    };

    let handleLower;
    if (handle) {
      handleLower = handle.toLowerCase().trim();
      if (!/^[a-z0-9_]{3,20}$/.test(handleLower)) {
        return res.status(400).json({
          success: false,
          error: 'IDは英小文字・数字・_の3〜20文字で入力してください',
          message: 'IDは英小文字・数字・_の3〜20文字で入力してください',
        });
      }
      const existingHandle = await User.findOne({ handle: handleLower });
      if (existingHandle) {
        return res.status(400).json({
          success: false,
          error: 'このIDは既に使用されています',
          message: 'このIDは既に使用されています',
        });
      }
    } else {
      handleLower = await generateRandomHandle();
    }

    // パスワードをハッシュ化
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // 新しいユーザーを作成
    const user = await User.create({
      username,
      handle: handleLower,
      email,
      password: hashedPassword,
    });

    // JWTトークンを生成
    const token = generateAccessToken(user._id);

    // リフレッシュトークンを生成・保存（30日有効）
    const refreshToken = generateRefreshToken();
    const refreshTokenHash = crypto
      .createHash('sha256')
      .update(refreshToken)
      .digest('hex');
    await User.findByIdAndUpdate(user._id, {
      refreshToken: refreshTokenHash,
      refreshTokenExpiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
    });

    res.status(201).json({
      success: true,
      message: 'ユーザー登録が完了しました',
      token,
      refreshToken,
      user: {
        id: user._id,
        username: user.username,
        handle: user.handle,
        email: user.email,
        profileImage: user.profileImage,
        headerImage: user.headerImage,
        bio: user.bio,
      },
    });
  } catch (error) {
    console.error('登録エラー:', error);
    res.status(500).json({
      success: false,
      error: 'サーバーエラーが発生しました',
      message: 'サーバーエラーが発生しました',
    });
  }
};

/**
 * ログイン
 * POST /auth/login
 */
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // 入力チェック
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        error: 'メールアドレスとパスワードを入力してください',
        message: 'メールアドレスとパスワードを入力してください',
      });
    }

    // ユーザーを検索（パスワード含む）
    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      return res.status(401).json({
        success: false,
        error: 'メールアドレスまたはパスワードが正しくありません',
        message: 'メールアドレスまたはパスワードが正しくありません',
      });
    }

    // パスワードを検証
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        error: 'メールアドレスまたはパスワードが正しくありません',
        message: 'メールアドレスまたはパスワードが正しくありません',
      });
    }

    // JWTトークンを生成
    const token = generateAccessToken(user._id);

    // リフレッシュトークンを生成・保存（30日有効）
    const refreshToken = generateRefreshToken();
    const refreshTokenHash = crypto
      .createHash('sha256')
      .update(refreshToken)
      .digest('hex');
    await User.findByIdAndUpdate(user._id, {
      refreshToken: refreshTokenHash,
      refreshTokenExpiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
    });

    res.status(200).json({
      success: true,
      message: 'ログインに成功しました',
      token,
      refreshToken,
      user: {
        id: user._id,
        username: user.username,
        handle: user.handle,
        email: user.email,
        profileImage: user.profileImage,
        headerImage: user.headerImage,
        bio: user.bio,
        followersCount: user.followersCount,
        followingCount: user.followingCount,
      },
    });
  } catch (error) {
    console.error('ログインエラー:', error);
    res.status(500).json({
      success: false,
      error: 'サーバーエラーが発生しました',
      message: 'サーバーエラーが発生しました',
    });
  }
};

/**
 * 現在のユーザー情報を取得
 * GET /auth/me
 */
exports.getMe = async (req, res) => {
  try {
    // req.userはミドルウェアで設定される
    const user = await User.findById(req.user.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'ユーザーが見つかりません',
      });
    }

    res.status(200).json({
      success: true,
      data: {
        id: user._id,
        _id: user._id,
        username: user.username,
        handle: user.handle,
        email: user.email,
        profileImage: user.profileImage,
        headerImage: user.headerImage,
        bio: user.bio,
        followersCount: user.followersCount,
        followingCount: user.followingCount,
      }
    });
  } catch (error) {
    console.error('ユーザー情報取得エラー:', error);
    res.status(500).json({
      success: false,
      error: 'サーバーエラーが発生しました',
      message: 'サーバーエラーが発生しました',
    });
  }
};

/**
 * FCMトークンを更新
 * PUT /auth/fcm-token
 * 
 * 【処理フロー】
 * ①リクエストボディからFCMトークンを取得
 * ②現在のユーザーのfcmTokenフィールドを更新
 * ③レスポンスを返す
 * 
 * 【使用例】
 * アプリ起動時やトークン更新時にこのエンドポイントを呼び出して、
 * サーバーに最新のFCMトークンを保存します
 */
exports.updateFcmToken = async (req, res) => {
  try {
    const { fcmToken } = req.body;

    // 入力チェック
    if (!fcmToken) {
      return res.status(400).json({
        success: false,
        error: 'FCMトークンは必須です',
        message: 'FCMトークンは必須です',
      });
    }

    // ユーザーのFCMトークンを更新
    const user = await User.findByIdAndUpdate(
      req.user.id,
      { fcmToken },
      { new: true }
    );

    res.status(200).json({
      success: true,
      message: 'FCMトークンを更新しました',
      data: {
        userId: user._id,
        fcmToken: user.fcmToken,
      },
    });
  } catch (error) {
    console.error('FCMトークン更新エラー:', error);
    res.status(500).json({
      success: false,
      error: 'サーバーエラーが発生しました',
      message: 'サーバーエラーが発生しました',
    });
  }
};

/**
 * ログアウト
 * POST /auth/logout
 *
 * FCMトークンとリフレッシュトークンをDBから削除する。
 * JWTアクセストークン自体はステートレスなのでサーバー側では無効化できないが、
 * リフレッシュトークンを削除することで再発行を防ぐ。
 * クライアント側では受け取り後に保存済みトークンを削除すること。
 */
exports.logout = async (req, res) => {
  try {
    await User.findByIdAndUpdate(req.user.id, {
      fcmToken: null,
      refreshToken: null,
      refreshTokenExpiresAt: null,
    });

    res.status(200).json({
      success: true,
      message: 'ログアウトしました',
    });
  } catch (error) {
    console.error('ログアウトエラー:', error);
    res.status(500).json({
      success: false,
      error: 'サーバーエラーが発生しました',
      message: 'サーバーエラーが発生しました',
    });
  }
};

/**
 * トークンリフレッシュ
 * POST /auth/refresh
 *
 * リフレッシュトークンを検証して新しいアクセストークンを発行する。
 * 同時にリフレッシュトークンを更新（ローテーション）することで、
 * 盗まれたリフレッシュトークンの再利用を防ぐ。
 */
exports.refresh = async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(400).json({
        success: false,
        error: 'リフレッシュトークンは必須です',
        message: 'リフレッシュトークンは必須です',
      });
    }

    // 受け取ったトークンをハッシュ化してDBと照合
    const tokenHash = crypto
      .createHash('sha256')
      .update(refreshToken)
      .digest('hex');

    const user = await User.findOne({
      refreshToken: tokenHash,
      refreshTokenExpiresAt: { $gt: new Date() },
    }).select('+refreshToken');

    if (!user) {
      return res.status(401).json({
        success: false,
        error: 'リフレッシュトークンが無効または期限切れです',
        message: 'リフレッシュトークンが無効または期限切れです',
      });
    }

    // 新しいアクセストークンを発行
    const newAccessToken = generateAccessToken(user._id);

    // リフレッシュトークンをローテーション（旧トークンを無効化）
    const newRefreshToken = generateRefreshToken();
    const newRefreshHash = crypto
      .createHash('sha256')
      .update(newRefreshToken)
      .digest('hex');
    await User.findByIdAndUpdate(user._id, {
      refreshToken: newRefreshHash,
      refreshTokenExpiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
    });

    res.status(200).json({
      success: true,
      message: 'トークンを更新しました',
      data: {
        token: newAccessToken,
        refreshToken: newRefreshToken,
      },
    });
  } catch (error) {
    console.error('トークンリフレッシュエラー:', error);
    res.status(500).json({
      success: false,
      error: 'サーバーエラーが発生しました',
      message: 'サーバーエラーが発生しました',
    });
  }
};

/**
 * パスワードリセットリクエスト
 * POST /auth/forgot-password
 *
 * メールアドレスからリセット用URLを生成してメール送信する。
 * SMTP設定がない場合はコンソールにURLを出力（開発時確認用）。
 */
exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({
        success: false,
        error: 'メールアドレスは必須です',
        message: 'メールアドレスは必須です',
      });
    }

    // メールアドレスからユーザーを検索
    const user = await User.findOne({ email: email.toLowerCase().trim() });

    // ユーザーが見つからなくても同じレスポンスを返す（ユーザー列挙攻撃対策）
    if (!user) {
      return res.status(200).json({
        success: true,
        message:
          '該当するメールアドレスが登録されている場合、リセット用メールを送信しました',
      });
    }

    // リセットトークン生成（URLに含めるのは平文、DBにはハッシュを保存）
    const resetToken = crypto.randomBytes(32).toString('hex');
    const resetTokenHash = crypto
      .createHash('sha256')
      .update(resetToken)
      .digest('hex');

    // トークンをDBに保存（1時間有効）
    await User.findByIdAndUpdate(user._id, {
      resetPasswordToken: resetTokenHash,
      resetPasswordExpires: new Date(Date.now() + 60 * 60 * 1000),
    });

    // リセットURL生成（フロントエンドのURLに合わせて変更すること）
    const resetUrl = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/reset-password/${resetToken}`;

    await sendEmail({
      to: user.email,
      subject: 'パスワードリセットのご案内',
      html: `
        <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
          <h2>パスワードリセット</h2>
          <p>${user.username} さん、こんにちは。</p>
          <p>以下のボタンからパスワードをリセットしてください。</p>
          <p>このリンクは <strong>1時間</strong> 有効です。</p>
          <a href="${resetUrl}"
             style="display:inline-block;padding:12px 24px;background:#7C4DFF;color:#fff;
                    text-decoration:none;border-radius:8px;margin:16px 0;">
            パスワードをリセット
          </a>
          <p style="color:#888;font-size:12px;">
            このメールに心当たりがない場合は無視してください。
          </p>
        </div>
      `,
    });

    res.status(200).json({
      success: true,
      message:
        '該当するメールアドレスが登録されている場合、リセット用メールを送信しました',
    });
  } catch (error) {
    console.error('パスワードリセットリクエストエラー:', error);
    res.status(500).json({
      success: false,
      error: 'サーバーエラーが発生しました',
      message: 'サーバーエラーが発生しました',
    });
  }
};

/**
 * パスワードリセット確定
 * POST /auth/reset-password/:token
 *
 * URLのトークンを検証し、新しいパスワードに更新する。
 */
exports.resetPassword = async (req, res) => {
  try {
    const { token } = req.params;
    const { password } = req.body;

    if (!password) {
      return res.status(400).json({
        success: false,
        error: '新しいパスワードを入力してください',
        message: '新しいパスワードを入力してください',
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        error: 'パスワードは6文字以上で設定してください',
        message: 'パスワードは6文字以上で設定してください',
      });
    }

    // URLのトークンをハッシュ化してDBと照合
    const tokenHash = crypto
      .createHash('sha256')
      .update(token)
      .digest('hex');

    const user = await User.findOne({
      resetPasswordToken: tokenHash,
      resetPasswordExpires: { $gt: new Date() },
    }).select('+resetPasswordToken');

    if (!user) {
      return res.status(400).json({
        success: false,
        error:
          'パスワードリセットトークンが無効または期限切れです。再度リクエストしてください',
        message:
          'パスワードリセットトークンが無効または期限切れです。再度リクエストしてください',
      });
    }

    // パスワードをハッシュ化して更新
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    await User.findByIdAndUpdate(user._id, {
      password: hashedPassword,
      resetPasswordToken: null,
      resetPasswordExpires: null,
      // リフレッシュトークンも無効化（全端末からログアウト）
      refreshToken: null,
      refreshTokenExpiresAt: null,
    });

    res.status(200).json({
      success: true,
      message:
        'パスワードをリセットしました。新しいパスワードでログインしてください',
    });
  } catch (error) {
    console.error('パスワードリセットエラー:', error);
    res.status(500).json({
      success: false,
      error: 'サーバーエラーが発生しました',
      message: 'サーバーエラーが発生しました',
    });
  }
};

/**
 * Google OAuth ログイン/登録
 * POST /auth/google
 */
exports.loginWithGoogle = async (req, res) => {
  try {
    const { googleId, email, username, profileImage } = req.body;

    if (!googleId || !email) {
      return res.status(400).json({
        success: false,
        error: 'Google ID とメールアドレスは必須です',
        message: 'Google ID とメールアドレスは必須です',
      });
    }

    // 既存ユーザーをチェック
    let user = await User.findOne({ googleId });

    // Google ID が登録されていない場合、メールアドレスで検索
    if (!user) {
      user = await User.findOne({ email });
      if (user) {
        // メールアドレスが既に登録されている場合、Google ID をリンク
        user.googleId = googleId;
        user.authType = 'google';
        await user.save();
      }
    }

    // 新規ユーザーの場合、登録処理を実行
    if (!user) {
      // ユニークなハンドルを生成
      let handle = username
        ? username.toLowerCase().replace(/[^a-z0-9_]/g, '_').substr(0, 20)
        : email.split('@')[0].toLowerCase().replace(/[^a-z0-9_]/g, '_').substr(0, 20);

      // ハンドルの重複をチェック
      let existingUser = await User.findOne({ handle });
      if (existingUser) {
        handle = `${handle}_${crypto.randomBytes(3).toString('hex')}`;
        handle = handle.substr(0, 20);
      }

      // 新規ユーザー作成
      user = new User({
        username: username || email.split('@')[0],
        handle,
        email,
        googleId,
        profileImage: profileImage || null,
        authType: 'google',
        password: crypto.randomBytes(16).toString('hex'), // OAuth 用ダミーパスワード
      });
      await user.save();
    }

    // トークン生成
    const accessToken = generateAccessToken(user._id);
    const refreshToken = generateRefreshToken();
    const refreshTokenExpiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days

    // リフレッシュトークンをDBに保存
    user.refreshToken = refreshToken;
    user.refreshTokenExpiresAt = refreshTokenExpiresAt;
    await user.save();

    res.status(200).json({
      success: true,
      message: 'Google ログインに成功しました',
      user: {
        id: user._id,
        username: user.username,
        email: user.email,
        handle: user.handle,
        profileImage: user.profileImage,
      },
      accessToken,
      refreshToken,
    });
  } catch (error) {
    console.error('Google ログインエラー:', error);
    res.status(500).json({
      success: false,
      error: 'Google ログインに失敗しました',
      message: 'Google ログインに失敗しました',
    });
  }
};


