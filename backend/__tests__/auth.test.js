// ========================================
// 認証API統合テスト
// ========================================
// /auth エンドポイントのテスト

const request = require('supertest');
const app = require('../app');
const User = require('../models/User');

// セットアップファイルを読み込み
require('./setup');

describe('認証API (/auth)', () => {
  
  // ========================================
  // ユーザー登録テスト
  // ========================================
  describe('POST /auth/register', () => {
    
    it('正しいデータで新規ユーザーを登録できる', async () => {
      const userData = {
        username: 'testuser',
        handle: 'testuser',
        email: 'test@example.com',
        password: 'password123'
      };

      const response = await request(app)
        .post('/auth/register')
        .send(userData)
        .expect(201);

      // レスポンス検証
      expect(response.body).toHaveProperty('token');
      expect(response.body.user).toHaveProperty('username', 'testuser');
      expect(response.body.user).toHaveProperty('email', 'test@example.com');
      expect(response.body.user).not.toHaveProperty('password');

      // データベース検証
      const user = await User.findOne({ email: 'test@example.com' });
      expect(user).toBeTruthy();
      expect(user.username).toBe('testuser');
    });

    it('必須フィールドが欠けている場合はエラーを返す', async () => {
      const response = await request(app)
        .post('/auth/register')
        .send({
          username: 'testuser'
          // emailとpasswordが欠けている
        })
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });

    it('重複したusernameでは登録できない', async () => {
      // 最初のユーザーを作成
      await User.create({
        username: 'testuser',
        handle: 'testuser',
        email: 'test1@example.com',
        password: 'password123'
      });

      // 同じusernameで登録を試みる
      const response = await request(app)
        .post('/auth/register')
        .send({
          username: 'testuser',
          handle: 'testuser2',
          email: 'test2@example.com',
          password: 'password123'
        })
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toMatch(/username|既に存在/i);
    });

    it('重複したemailでは登録できない', async () => {
      // 最初のユーザーを作成
      await User.create({
        username: 'testuser1',
        handle: 'testuser1',
        email: 'test@example.com',
        password: 'password123'
      });

      // 同じemailで登録を試みる
      const response = await request(app)
        .post('/auth/register')
        .send({
          username: 'testuser2',
          handle: 'testuser2',
          email: 'test@example.com',
          password: 'password123'
        })
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toMatch(/email|既に存在/i);
    });
  });

  // ========================================
  // ログインテスト
  // ========================================
  describe('POST /auth/login', () => {
    
    // テストユーザーを事前作成
    beforeEach(async () => {
      await request(app)
        .post('/auth/register')
        .send({
          username: 'testuser',
          handle: 'testuser',
          email: 'test@example.com',
          password: 'password123'
        });
    });

    it('正しい認証情報でログインできる', async () => {
      const response = await request(app)
        .post('/auth/login')
        .send({
          email: 'test@example.com',
          password: 'password123'
        })
        .expect(200);

      // レスポンス検証
      expect(response.body).toHaveProperty('token');
      expect(response.body.user).toHaveProperty('username', 'testuser');
      expect(response.body.user).not.toHaveProperty('password');
    });

    it('誤ったパスワードではログインできない', async () => {
      const response = await request(app)
        .post('/auth/login')
        .send({
          email: 'test@example.com',
          password: 'wrongpassword'
        })
        .expect(401);

      expect(response.body).toHaveProperty('error');
    });

    it('存在しないユーザーではログインできない', async () => {
      const response = await request(app)
        .post('/auth/login')
        .send({
          email: 'nonexistent@example.com',
          password: 'password123'
        })
        .expect(401);

      expect(response.body).toHaveProperty('error');
    });

    it('emailが欠けている場合はエラーを返す', async () => {
      const response = await request(app)
        .post('/auth/login')
        .send({
          password: 'password123'
        })
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });

    it('passwordが欠けている場合はエラーを返す', async () => {
      const response = await request(app)
        .post('/auth/login')
        .send({
          email: 'test@example.com'
        })
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });
  });

  // ========================================
  // ユーザー情報取得テスト
  // ========================================
  describe('GET /auth/me', () => {
    
    let authToken;

    // テストユーザーを事前作成してトークン取得
    beforeEach(async () => {
      const registerResponse = await request(app)
        .post('/auth/register')
        .send({
          username: 'testuser',
          handle: 'testuser',
          email: 'test@example.com',
          password: 'password123'
        });
      
      authToken = registerResponse.body.token;
    });

    it('有効なトークンでユーザー情報を取得できる', async () => {
      const response = await request(app)
        .get('/auth/me')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('username', 'testuser');
      expect(response.body).toHaveProperty('email', 'test@example.com');
      expect(response.body).not.toHaveProperty('password');
    });

    it('トークンなしではアクセスできない', async () => {
      const response = await request(app)
        .get('/auth/me')
        .expect(401);

      expect(response.body).toHaveProperty('error');
    });

    it('無効なトークンではアクセスできない', async () => {
      const response = await request(app)
        .get('/auth/me')
        .set('Authorization', 'Bearer invalid_token')
        .expect(401);

      expect(response.body).toHaveProperty('error');
    });
  });
});
