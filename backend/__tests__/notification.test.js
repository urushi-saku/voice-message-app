// ========================================
// 通知API統合テスト
// ========================================

const request = require('supertest');
const app = require('../app');
const User = require('../models/User');
const Notification = require('../models/Notification');

// セットアップファイルを読み込み
require('./setup');

describe('通知API (/notifications)', () => {
  
  let currentUser;
  let token;
  
  beforeEach(async () => {
    // テストユーザーを作成
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
  });
  
  // ========================================
  // 通知一覧テスト
  // ========================================
  describe('GET /notifications', () => {
    
    beforeEach(async () => {
      // 複数の通知を作成
      for (let i = 0; i < 5; i++) {
        await Notification.create({
          recipient: currentUser._id,
          type: 'message',
          content: `メッセージ${i + 1}`,
          isRead: i % 2 === 0 // 半分は既読
        });
      }
    });
    
    it('通知一覧を取得できる', async () => {
      const response = await request(app)
        .get('/notifications')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      
      expect(response.body).toHaveProperty('notifications');
      expect(Array.isArray(response.body.notifications)).toBe(true);
      expect(response.body.notifications.length).toBeGreaterThan(0);
    });
    
    it('未読通知数が含まれる', async () => {
      const response = await request(app)
        .get('/notifications')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      
      expect(response.body).toHaveProperty('unreadCount');
      expect(typeof response.body.unreadCount).toBe('number');
      // 5つの内、isRead=false は i=1,3 の2個
      expect(response.body.unreadCount).toBe(2);
    });
    
    it('未読フィルターが機能する', async () => {
      const response = await request(app)
        .get('/notifications?unreadOnly=true')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      
      expect(response.body).toHaveProperty('notifications');
      // 2個の未読通知のみ返却（i=1, i=3）
      expect(response.body.notifications.length).toBe(2);
      
      // すべて未読を確認
      response.body.notifications.forEach(notif => {
        expect(notif.isRead).toBe(false);
      });
    });
    
    it('ページングが機能する', async () => {
      const response = await request(app)
        .get('/notifications?page=1&limit=2')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      
      expect(response.body.notifications.length).toBeLessThanOrEqual(2);
    });
  });
  
  // ========================================
  // 通知既読テスト
  // ========================================
  describe('PATCH /notifications/:id/read', () => {
    
    let testNotification;
    
    beforeEach(async () => {
      testNotification = await Notification.create({
        recipient: currentUser._id,
        type: 'follow',
        content: 'ユーザーがあなたをフォローしました',
        isRead: false
      });
    });
    
    it('通知を既読にできる', async () => {
      const response = await request(app)
        .patch(`/notifications/${testNotification._id}/read`)
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      
      expect(response.body).toHaveProperty('success', true);
      
      // データベースで確認
      const updatedNotif = await Notification.findById(testNotification._id);
      expect(updatedNotif.isRead).toBe(true);
    });
    
    it('存在しない通知はエラー', async () => {
      const fakeId = '507f1f77bcf86cd799439011';
      const response = await request(app)
        .patch(`/notifications/${fakeId}/read`)
        .set('Authorization', `Bearer ${token}`)
        .expect(404);
      
      expect(response.body).toHaveProperty('error');
    });
    
    it('他のユーザーの通知は操作できない', async () => {
      const otherUser = await User.create({
        username: 'otheruser',
        handle: 'otheruser',
        email: 'other@example.com',
        password: 'password123'
      });
      
      const otherNotif = await Notification.create({
        recipient: otherUser._id,
        type: 'message',
        content: 'テスト',
        isRead: false
      });
      
      const response = await request(app)
        .patch(`/notifications/${otherNotif._id}/read`)
        .set('Authorization', `Bearer ${token}`)
        .expect(403);
      
      expect(response.body).toHaveProperty('error');
    });
  });
  
  // ========================================
  // 全通知既読テスト
  // ========================================
  describe('PATCH /notifications/read-all', () => {
    
    beforeEach(async () => {
      // 複数の未読通知を作成
      for (let i = 0; i < 3; i++) {
        await Notification.create({
          recipient: currentUser._id,
          type: 'message',
          content: `メッセージ${i + 1}`,
          isRead: false
        });
      }
    });
    
    it('全通知を既読にできる', async () => {
      const response = await request(app)
        .patch('/notifications/read-all')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      
      expect(response.body).toHaveProperty('success', true);
      
      // データベースで確認
      const unreadCount = await Notification.countDocuments({
        recipient: currentUser._id,
        isRead: false
      });
      expect(unreadCount).toBe(0);
    });
  });
  
  // ========================================
  // 通知削除テスト
  // ========================================
  describe('DELETE /notifications/:id', () => {
    
    let testNotification;
    
    beforeEach(async () => {
      testNotification = await Notification.create({
        recipient: currentUser._id,
        type: 'system',
        content: 'テスト',
        isRead: false
      });
    });
    
    it('通知を削除できる', async () => {
      const response = await request(app)
        .delete(`/notifications/${testNotification._id}`)
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      
      expect(response.body).toHaveProperty('success', true);
      
      // データベースで確認
      const deletedNotif = await Notification.findById(testNotification._id);
      expect(deletedNotif).toBeNull();
    });
    
    it('存在しない通知はエラー', async () => {
      const fakeId = '507f1f77bcf86cd799439011';
      const response = await request(app)
        .delete(`/notifications/${fakeId}`)
        .set('Authorization', `Bearer ${token}`)
        .expect(404);
      
      expect(response.body).toHaveProperty('error');
    });
    
    it('他のユーザーの通知は削除できない', async () => {
      const otherUser = await User.create({
        username: 'otheruser',
        handle: 'otheruser',
        email: 'other@example.com',
        password: 'password123'
      });
      
      const otherNotif = await Notification.create({
        recipient: otherUser._id,
        type: 'follow',
        content: 'テスト',
        isRead: false
      });
      
      const response = await request(app)
        .delete(`/notifications/${otherNotif._id}`)
        .set('Authorization', `Bearer ${token}`)
        .expect(403);
      
      expect(response.body).toHaveProperty('error');
    });
  });
});
