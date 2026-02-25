// ========================================
// メッセージAPI統合テスト
// ========================================

const request = require('supertest');
const app = require('../app');
const User = require('../models/User');
const Follower = require('../models/Follower');
const Message = require('../models/Message');
const fs = require('fs').promises;
const path = require('path');

// セットアップファイルを読み込み
require('./setup');

describe('メッセージAPI (/messages)', () => {
  
  let currentUser;
  let targetUser;
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
    
    // 受信用テストユーザーを作成
    targetUser = await User.create({
      username: 'targetuser',
      handle: 'targetuser',
      email: 'target@example.com',
      password: 'password123'
    });
    
    // フォロー関係を作成（メッセージ送信にはフォローが必須）
    await Follower.create({
      user: targetUser._id,
      follower: currentUser._id
    });
  });
  
  // ========================================
  // テキストメッセージ送信テスト
  // ========================================
  describe('POST /messages/send-text', () => {
    
    it('テキストメッセージを送信できる', async () => {
      const response = await request(app)
        .post('/messages/send-text')
        .set('Authorization', `Bearer ${token}`)
        .send({
          receivers: [targetUser._id.toString()],
          content: 'テストメッセージです'
        })
        .expect(201);
      
      expect(response.body).toHaveProperty('success', true);
      expect(response.body).toHaveProperty('data');
      expect(response.body.data).toHaveProperty('_id');
      
      // データベースで確認
      const message = await Message.findById(response.body.data._id);
      expect(message).toBeTruthy();
      expect(message.textContent).toBe('テストメッセージです');
      expect(message.sender.toString()).toBe(currentUser._id.toString());
    });
    
    it('コンテンツなしはエラー', async () => {
      const response = await request(app)
        .post('/messages/send-text')
        .set('Authorization', `Bearer ${token}`)
        .send({
          receivers: [targetUser._id.toString()]
        })
        .expect(400);
      
      expect(response.body).toHaveProperty('error');
    });
    
    it('受信者なしはエラー', async () => {
      const response = await request(app)
        .post('/messages/send-text')
        .set('Authorization', `Bearer ${token}`)
        .send({
          content: 'テスト'
        })
        .expect(400);
      
      expect(response.body).toHaveProperty('error');
    });
    
    it('フォローしていないユーザーには送信できない', async () => {
      const nonFollowedUser = await User.create({
        username: 'nonfollowed',
        handle: 'nonfollowed',
        email: 'nonfollowed@example.com',
        password: 'password123'
      });
      
      const response = await request(app)
        .post('/messages/send-text')
        .set('Authorization', `Bearer ${token}`)
        .send({
          receivers: [nonFollowedUser._id.toString()],
          content: 'テスト'
        })
        .expect(403);
      
      expect(response.body).toHaveProperty('error');
    });
  });
  
  // ========================================
  // 受信メッセージ一覧テスト
  // ========================================
  describe('GET /messages/received', () => {
    
    beforeEach(async () => {
      // 複数のメッセージを送信
      for (let i = 0; i < 3; i++) {
        await Message.create({
          sender: targetUser._id,
          receivers: [currentUser._id],
          contentType: 'text',
          content: `メッセージ${i + 1}`,
          readStatus: [
            { user: currentUser._id, isRead: false, readAt: null }
          ]
        });
      }
    });
    
    it('受信メッセージ一覧を取得できる', async () => {
      const response = await request(app)
        .get('/messages/received')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      
      expect(response.body).toHaveProperty('messages');
      expect(Array.isArray(response.body.messages)).toBe(true);
      expect(response.body.messages.length).toBeGreaterThan(0);
    });
    
    it('未読フィルターが機能する', async () => {
      const response = await request(app)
        .get('/messages/received?unreadOnly=true')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      
      expect(response.body).toHaveProperty('messages');
      // 全メッセージが未読なので、3つ取得
      expect(response.body.messages.length).toBe(3);
    });
  });
  
  // ========================================
  // メッセージ既読テスト
  // ========================================
  describe('PUT /messages/:id/read', () => {
    
    let testMessage;
    
    beforeEach(async () => {
      testMessage = await Message.create({
        sender: targetUser._id,
        receivers: [currentUser._id],
        contentType: 'text',
        content: 'テストメッセージ',
        readStatus: [
          { user: currentUser._id, isRead: false, readAt: null }
        ]
      });
    });
    
    it('メッセージを既読にできる', async () => {
      const response = await request(app)
        .put(`/messages/${testMessage._id}/read`)
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      
      expect(response.body).toHaveProperty('success', true);
      
      // データベースで確認
      const updatedMessage = await Message.findById(testMessage._id);
      const readStatusForUser = updatedMessage.readStatus.find(
        rs => rs.user.toString() === currentUser._id.toString()
      );
      expect(readStatusForUser.isRead).toBe(true);
      expect(readStatusForUser.readAt).toBeTruthy();
    });
    
    it('存在しないメッセージはエラー', async () => {
      const fakeId = '507f1f77bcf86cd799439011';
      const response = await request(app)
        .put(`/messages/${fakeId}/read`)
        .set('Authorization', `Bearer ${token}`)
        .expect(404);
      
      expect(response.body).toHaveProperty('error');
    });
  });
  
  // ========================================
  // メッセージ削除テスト
  // ========================================
  describe('DELETE /messages/:id', () => {
    
    let testMessage;
    
    beforeEach(async () => {
      testMessage = await Message.create({
        sender: currentUser._id,
        receivers: [targetUser._id],
        contentType: 'text',
        content: 'テストメッセージ',
        readStatus: [
          { user: targetUser._id, isRead: false, readAt: null }
        ]
      });
    });
    
    it('メッセージを削除できる', async () => {
      const response = await request(app)
        .delete(`/messages/${testMessage._id}`)
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      
      expect(response.body).toHaveProperty('success', true);
      
      // データベースで確認（論理削除）
      const deletedMessage = await Message.findById(testMessage._id);
      expect(deletedMessage.isDeleted).toBe(true);
    });
    
    it('関係のないメッセージは削除できない', async () => {
      // 自分が送信者でも受信者でもないメッセージを作成
      const thirdUser = await User.create({
        username: 'thirduser',
        handle: 'thirduser',
        email: 'third@example.com',
        password: 'password123'
      });
      
      const otherMessage = await Message.create({
        sender: targetUser._id,
        receivers: [thirdUser._id],
        contentType: 'text',
        content: 'テストメッセージ',
        readStatus: [
          { user: thirdUser._id, isRead: false, readAt: null }
        ]
      });
      
      const response = await request(app)
        .delete(`/messages/${otherMessage._id}`)
        .set('Authorization', `Bearer ${token}`)
        .expect(403);
      
      expect(response.body).toHaveProperty('error');
    });
  });
  
  // ========================================
  // スレッド一覧テスト
  // ========================================
  describe('GET /messages/threads', () => {
    
    beforeEach(async () => {
      // 複数のスレッド相手からメッセージを受け取る
      const user2 = await User.create({
        username: 'user2',
        handle: 'user2',
        email: 'user2@example.com',
        password: 'password123'
      });
      
      await Message.create({
        sender: targetUser._id,
        receivers: [currentUser._id],
        contentType: 'text',
        content: 'メッセージ1',
        readStatus: [
          { user: currentUser._id, isRead: false, readAt: null }
        ]
      });
      
      await Message.create({
        sender: user2._id,
        receivers: [currentUser._id],
        contentType: 'text',
        content: 'メッセージ2',
        readStatus: [
          { user: currentUser._id, isRead: false, readAt: null }
        ]
      });
    });
    
    it('スレッド一覧を取得できる', async () => {
      const response = await request(app)
        .get('/messages/threads')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      
      expect(response.body).toHaveProperty('threads');
      expect(Array.isArray(response.body.threads)).toBe(true);
      expect(response.body.threads.length).toBeGreaterThan(0);
    });
  });
  
  // ========================================
  // スレッド詳細テスト
  // ========================================
  describe('GET /messages/thread/:senderId', () => {
    
    beforeEach(async () => {
      // 複数のメッセージを作成
      for (let i = 0; i < 3; i++) {
        await Message.create({
          sender: targetUser._id,
          receivers: [currentUser._id],
          contentType: 'text',
          content: `メッセージ${i + 1}`,
          readStatus: [
            { user: currentUser._id, isRead: false, readAt: null }
          ]
        });
      }
    });
    
    it('スレッド詳細を取得できる', async () => {
      const response = await request(app)
        .get(`/messages/thread/${targetUser._id}`)
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      
      expect(response.body).toHaveProperty('messages');
      expect(Array.isArray(response.body.messages)).toBe(true);
      expect(response.body.messages.length).toBe(3);
    });
    
    it('存在しないユーザーのスレッドは空', async () => {
      const fakeId = '507f1f77bcf86cd799439011';
      const response = await request(app)
        .get(`/messages/thread/${fakeId}`)
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      
      expect(response.body).toHaveProperty('messages');
      expect(response.body.messages.length).toBe(0);
    });
  });
  
  // ========================================
  // リアクション追加テスト
  // ========================================
  describe('POST /messages/:id/reactions', () => {
    
    let testMessage;
    
    beforeEach(async () => {
      testMessage = await Message.create({
        sender: targetUser._id,
        receivers: [currentUser._id],
        contentType: 'text',
        content: 'テストメッセージ',
        readStatus: [
          { user: currentUser._id, isRead: false, readAt: null }
        ]
      });
    });
    
    it('リアクションを追加できる', async () => {
      const response = await request(app)
        .post(`/messages/${testMessage._id}/reactions`)
        .set('Authorization', `Bearer ${token}`)
        .send({ emoji: '👍' })
        .expect(201);
      
      expect(response.body).toHaveProperty('success', true);
      
      // データベースで確認
      const updatedMessage = await Message.findById(testMessage._id);
      expect(updatedMessage.reactions).toContainEqual(
        expect.objectContaining({
          emoji: '👍',
          userId: currentUser._id
        })
      );
    });
    
    it('同じリアクションを2回追加するとエラー', async () => {
      await request(app)
        .post(`/messages/${testMessage._id}/reactions`)
        .set('Authorization', `Bearer ${token}`)
        .send({ emoji: '👍' })
        .expect(201);
      
      const response = await request(app)
        .post(`/messages/${testMessage._id}/reactions`)
        .set('Authorization', `Bearer ${token}`)
        .send({ emoji: '👍' })
        .expect(400);
      
      expect(response.body).toHaveProperty('error');
    });
  });
  
  // ========================================
  // リアクション削除テスト
  // ========================================
  describe('DELETE /messages/:id/reactions/:emoji', () => {
    
    let testMessage;
    
    beforeEach(async () => {
      testMessage = await Message.create({
        sender: targetUser._id,
        receivers: [currentUser._id],
        contentType: 'text',
        content: 'テストメッセージ',
        reactions: [
          {
            emoji: '👍',
            userId: currentUser._id,
            username: currentUser.username
          }
        ],
        readStatus: [
          { user: currentUser._id, isRead: false, readAt: null }
        ]
      });
    });
    
    it('リアクションを削除できる', async () => {
      const response = await request(app)
        .delete(`/messages/${testMessage._id}/reactions/👍`)
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      
      expect(response.body).toHaveProperty('success', true);
      
      // データベースで確認
      const updatedMessage = await Message.findById(testMessage._id);
      const hasReaction = updatedMessage.reactions.some(
        r => r.emoji === '👍' && r.userId.toString() === currentUser._id.toString()
      );
      expect(hasReaction).toBe(false);
    });
  });
});
