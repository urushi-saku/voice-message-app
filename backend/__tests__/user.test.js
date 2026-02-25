// ========================================
// ユーザーAPI統合テスト
// ========================================

const request = require('supertest');
const app = require('../app');
const User = require('../models/User');
const Follower = require('../models/Follower');

// セットアップファイルを読み込み
require('./setup');

describe('ユーザーAPI (/users)', () => {
  
  // ========================================
  // ユーザー一覧テスト
  // ========================================
  describe('GET /users', () => {
    
    let testUser;
    let token;
    
    beforeEach(async () => {
      // テストユーザーを作成
      testUser = await User.create({
        username: 'testuser',
        handle: 'testuser',
        email: 'test@example.com',
        password: 'password123'
      });
      
      const loginRes = await request(app)
        .post('/auth/login')
        .send({
          email: 'test@example.com',
          password: 'password123'
        });
      
      token = loginRes.body.token;
      
      // 他の複数ユーザーを作成
      for (let i = 0; i < 5; i++) {
        await User.create({
          username: `user${i}`,
          handle: `user${i}`,
          email: `user${i}@example.com`,
          password: 'password123'
        });
      }
    });
    
    it('ユーザー一覧を取得できる', async () => {
      const response = await request(app)
        .get('/users')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      
      expect(response.body).toHaveProperty('users');
      expect(Array.isArray(response.body.users)).toBe(true);
      expect(response.body).toHaveProperty('pagination');
      expect(response.body.pagination).toHaveProperty('total');
      expect(response.body.pagination).toHaveProperty('page', 1);
      expect(response.body.pagination).toHaveProperty('limit', 20);
    });
    
    it('自分自身は除外される', async () => {
      const response = await request(app)
        .get('/users')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      
      const myUserIds = response.body.users.map(u => u._id);
      expect(myUserIds).not.toContain(testUser._id.toString());
    });
    
    it('クエリで絞り込みができる', async () => {
      const response = await request(app)
        .get('/users?q=user1')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      
      expect(response.body.users).toHaveLength(1);
      expect(response.body.users[0]).toHaveProperty('handle', 'user1');
    });
    
    it('ページングが機能する', async () => {
      const response = await request(app)
        .get('/users?page=1&limit=2')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      
      expect(response.body.pagination).toHaveProperty('page', 1);
      expect(response.body.pagination).toHaveProperty('limit', 2);
      expect(response.body.users.length).toBeLessThanOrEqual(2);
    });
  });
  
  // ========================================
  // ユーザー詳細テスト
  // ========================================
  describe('GET /users/:id', () => {
    
    let targetUser;
    let token;
    
    beforeEach(async () => {
      const loginUser = await User.create({
        username: 'testuser',
        handle: 'testuser',
        email: 'test@example.com',
        password: 'password123'
      });
      
      const loginRes = await request(app)
        .post('/auth/login')
        .send({
          email: 'test@example.com',
          password: 'password123'
        });
      
      token = loginRes.body.token;
      
      targetUser = await User.create({
        username: 'targetuser',
        handle: 'targetuser',
        email: 'target@example.com',
        password: 'password123'
      });
    });
    
    it('ユーザー詳細を取得できる', async () => {
      const response = await request(app)
        .get(`/users/${targetUser._id}`)
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      
      expect(response.body).toHaveProperty('_id', targetUser._id.toString());
      expect(response.body).toHaveProperty('username', 'targetuser');
      expect(response.body).toHaveProperty('handle', 'targetuser');
      expect(response.body).not.toHaveProperty('password');
    });
    
    it('存在しないユーザーは 404 を返す', async () => {
      const fakeId = '507f1f77bcf86cd799439011';
      const response = await request(app)
        .get(`/users/${fakeId}`)
        .set('Authorization', `Bearer ${token}`)
        .expect(404);
      
      expect(response.body).toHaveProperty('error');
    });
  });
  
  // ========================================
  // フォローテスト
  // ========================================
  describe('POST /users/:id/follow', () => {
    
    let currentUser;
    let targetUser;
    let token;
    
    beforeEach(async () => {
      currentUser = await User.create({
        username: 'testuser',
        handle: 'testuser',
        email: 'test@example.com',
        password: 'password123'
      });
      
      const loginRes = await request(app)
        .post('/auth/login')
        .send({
          email: 'test@example.com',
          password: 'password123'
        });
      
      token = loginRes.body.token;
      
      targetUser = await User.create({
        username: 'targetuser',
        handle: 'targetuser',
        email: 'target@example.com',
        password: 'password123'
      });
    });
    
    it('ユーザーをフォローできる', async () => {
      const response = await request(app)
        .post(`/users/${targetUser._id}/follow`)
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      
      expect(response.body).toHaveProperty('success', true);
      
      // データベースで確認
      const follower = await Follower.findOne({
        user: targetUser._id,
        follower: currentUser._id
      });
      expect(follower).toBeTruthy();
    });
    
    it('重複フォローはできない', async () => {
      // 最初のフォロー
      await request(app)
        .post(`/users/${targetUser._id}/follow`)
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      
      // 2回目のフォロー
      const response = await request(app)
        .post(`/users/${targetUser._id}/follow`)
        .set('Authorization', `Bearer ${token}`)
        .expect(400);
      
      expect(response.body).toHaveProperty('error');
    });
  });
  
  // ========================================
  // フォロー解除テスト
  // ========================================
  describe('DELETE /users/:id/follow', () => {
    
    let currentUser;
    let targetUser;
    let token;
    
    beforeEach(async () => {
      currentUser = await User.create({
        username: 'testuser',
        handle: 'testuser',
        email: 'test@example.com',
        password: 'password123'
      });
      
      const loginRes = await request(app)
        .post('/auth/login')
        .send({
          email: 'test@example.com',
          password: 'password123'
        });
      
      token = loginRes.body.token;
      
      targetUser = await User.create({
        username: 'targetuser',
        handle: 'targetuser',
        email: 'target@example.com',
        password: 'password123'
      });
      
      // 事前にフォロー
      await Follower.create({
        user: targetUser._id,
        follower: currentUser._id
      });
    });
    
    it('ユーザーをフォロー解除できる', async () => {
      const response = await request(app)
        .delete(`/users/${targetUser._id}/follow`)
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      
      expect(response.body).toHaveProperty('success', true);
      
      // データベースで確認
      const follower = await Follower.findOne({
        user: targetUser._id,
        follower: currentUser._id
      });
      expect(follower).toBeNull();
    });
    
    it('フォローしていないユーザーはエラー', async () => {
      const newUser = await User.create({
        username: 'newuser',
        handle: 'newuser',
        email: 'new@example.com',
        password: 'password123'
      });
      
      const response = await request(app)
        .delete(`/users/${newUser._id}/follow`)
        .set('Authorization', `Bearer ${token}`)
        .expect(400);
      
      expect(response.body).toHaveProperty('error');
    });
  });
  
  // ========================================
  // アカウント削除テスト
  // ========================================
  describe('DELETE /users/:id', () => {
    
    let testUser;
    let token;
    
    beforeEach(async () => {
      testUser = await User.create({
        username: 'testuser',
        handle: 'testuser',
        email: 'test@example.com',
        password: 'password123'
      });
      
      const loginRes = await request(app)
        .post('/auth/login')
        .send({
          email: 'test@example.com',
          password: 'password123'
        });
      
      token = loginRes.body.token;
    });
    
    it('自分のアカウントを削除できる', async () => {
      const response = await request(app)
        .delete(`/users/${testUser._id}`)
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      
      expect(response.body).toHaveProperty('success', true);
      
      // データベースで確認
      const deletedUser = await User.findById(testUser._id);
      expect(deletedUser).toBeNull();
    });
    
    it('他のユーザーのアカウントは削除できない', async () => {
      const otherUser = await User.create({
        username: 'otheruser',
        handle: 'otheruser',
        email: 'other@example.com',
        password: 'password123'
      });
      
      const response = await request(app)
        .delete(`/users/${otherUser._id}`)
        .set('Authorization', `Bearer ${token}`)
        .expect(403);
      
      expect(response.body).toHaveProperty('error');
    });
  });
});
