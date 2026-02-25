// ========================================
// グループAPI統合テスト
// ========================================

const request = require('supertest');
const app = require('../app');
const User = require('../models/User');
const Group = require('../models/Group');

// セットアップファイルを読み込み
require('./setup');

describe('グループAPI (/groups)', () => {
  
  let adminUser;
  let memberUser;
  let adminToken;
  let memberToken;
  
  beforeEach(async () => {
    // 管理者ユーザーを作成
    adminUser = await User.create({
      username: 'adminuser',
      handle: 'adminuser',
      email: 'admin@example.com',
      password: 'password123'
    });
    
    const adminLoginRes = await request(app)
      .post('/auth/login')
      .send({
        email: 'admin@example.com',
        password: 'password123'
      });
    
    adminToken = adminLoginRes.body.token;
    
    // メンバーユーザーを作成
    memberUser = await User.create({
      username: 'memberuser',
      handle: 'memberuser',
      email: 'member@example.com',
      password: 'password123'
    });
    
    const memberLoginRes = await request(app)
      .post('/auth/login')
      .send({
        email: 'member@example.com',
        password: 'password123'
      });
    
    memberToken = memberLoginRes.body.token;
  });
  
  // ========================================
  // グループ作成テスト
  // ========================================
  describe('POST /groups', () => {
    
    it('グループを作成できる', async () => {
      const response = await request(app)
        .post('/groups')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          name: 'テストグループ',
          description: 'テスト用のグループです',
          members: [adminUser._id.toString(), memberUser._id.toString()]
        })
        .expect(201);
      
      expect(response.body).toHaveProperty('success', true);
      expect(response.body).toHaveProperty('group');
      expect(response.body.group).toHaveProperty('_id');
      expect(response.body.group).toHaveProperty('name', 'テストグループ');
    });
    
    it('グループ名なしはエラー', async () => {
      const response = await request(app)
        .post('/groups')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          description: 'テスト',
          members: [adminUser._id.toString()]
        })
        .expect(400);
      
      expect(response.body).toHaveProperty('error');
    });
    
    it('メンバーを指定してグループを作成できる', async () => {
      const response = await request(app)
        .post('/groups')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          name: 'テストグループオンリー',
          description: 'テスト',
          memberIds: [memberUser._id.toString()]
        })
        .expect(201);
      
      expect(response.body).toHaveProperty('success', true);
      expect(response.body.group.members.length).toBeGreaterThanOrEqual(2); // admin + member
    });
  });
  
  // ========================================
  // グループ一覧テスト
  // ========================================
  describe('GET /groups', () => {
    
    let testGroup;
    
    beforeEach(async () => {
      testGroup = await Group.create({
        name: 'テストグループ',
        description: 'テスト用',
        admin: adminUser._id,
        members: [adminUser._id, memberUser._id]
      });
    });
    
    it('参加しているグループ一覧を取得できる', async () => {
      const response = await request(app)
        .get('/groups')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);
      
      expect(response.body).toHaveProperty('groups');
      expect(Array.isArray(response.body.groups)).toBe(true);
      expect(response.body.groups.length).toBeGreaterThan(0);
    });
    
    it('参加していないグループは含まれない', async () => {
      const otherUser = await User.create({
        username: 'other',
        handle: 'other',
        email: 'other@example.com',
        password: 'password123'
      });
      
      const otherLoginRes = await request(app)
        .post('/auth/login')
        .send({
          email: 'other@example.com',
          password: 'password123'
        });
      
      const otherToken = otherLoginRes.body.token;
      
      const response = await request(app)
        .get('/groups')
        .set('Authorization', `Bearer ${otherToken}`)
        .expect(200);
      
      const groupIds = response.body.groups.map(g => g._id);
      expect(groupIds).not.toContain(testGroup._id.toString());
    });
  });
  
  // ========================================
  // グループ詳細テスト
  // ========================================
  describe('GET /groups/:id', () => {
    
    let testGroup;
    
    beforeEach(async () => {
      testGroup = await Group.create({
        name: 'テストグループ',
        description: 'テスト用',
        admin: adminUser._id,
        members: [adminUser._id, memberUser._id]
      });
    });
    
    it('グループ詳細を取得できる', async () => {
      const response = await request(app)
        .get(`/groups/${testGroup._id}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);
      
      // レスポンスは {group: {...}} 形式
      const group = response.body.group || response.body;
      expect(group).toHaveProperty('_id', testGroup._id.toString());
      expect(group).toHaveProperty('name', 'テストグループ');
      expect(group).toHaveProperty('members');
    });
    
    it('存在しないグループは 404', async () => {
      const fakeId = '507f1f77bcf86cd799439011';
      const response = await request(app)
        .get(`/groups/${fakeId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(404);
      
      expect(response.body).toHaveProperty('error');
    });
  });
  
  // ========================================
  // グループ更新テスト
  // ========================================
  describe('PUT /groups/:id', () => {
    
    let testGroup;
    
    beforeEach(async () => {
      testGroup = await Group.create({
        name: 'テストグループ',
        description: 'テスト用',
        admin: adminUser._id,
        members: [adminUser._id, memberUser._id]
      });
    });
    
    it('管理者がグループ情報を更新できる', async () => {
      const response = await request(app)
        .put(`/groups/${testGroup._id}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          name: '更新されたグループ',
          description: '更新されました'
        })
        .expect(200);
      
      expect(response.body).toHaveProperty('success', true);
      expect(response.body.group).toHaveProperty('name', '更新されたグループ');
    });
    
    it('メンバーは更新できない', async () => {
      const response = await request(app)
        .put(`/groups/${testGroup._id}`)
        .set('Authorization', `Bearer ${memberToken}`)
        .send({
          name: '更新されたグループ'
        })
        .expect(403);
      
      expect(response.body).toHaveProperty('error');
    });
  });
  
  // ========================================
  // メンバー追加テスト
  // ========================================
  describe('POST /groups/:id/members', () => {
    
    let testGroup;
    let newUser;
    
    beforeEach(async () => {
      testGroup = await Group.create({
        name: 'テストグループ',
        admin: adminUser._id,
        members: [adminUser._id]
      });
      
      newUser = await User.create({
        username: 'newuser',
        handle: 'newuser',
        email: 'newuser@example.com',
        password: 'password123'
      });
    });
    
    it('管理者がメンバーを追加できる', async () => {
      const response = await request(app)
        .post(`/groups/${testGroup._id}/members`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          userId: newUser._id.toString()
        })
        .expect(200);
      
      expect(response.body).toHaveProperty('success', true);
      
      // データベースで確認（追加した newUser がメンバーにいるか）
      const updatedGroup = await Group.findById(testGroup._id);
      const isMember = updatedGroup.members.some(
        m => m.toString() === newUser._id.toString()
      );
      expect(isMember).toBe(true);
    });
    
    it('メンバーは追加できない', async () => {
      const response = await request(app)
        .post(`/groups/${testGroup._id}/members`)
        .set('Authorization', `Bearer ${memberToken}`)
        .send({
          userId: newUser._id.toString()
        })
        .expect(403);
      
      expect(response.body).toHaveProperty('error');
    });
    
    it('既に参加しているユーザーは追加できない', async () => {
      // 最初の追加
      await request(app)
        .post(`/groups/${testGroup._id}/members`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          userId: newUser._id.toString()
        })
        .expect(200);
      
      // 2回目の追加
      const response = await request(app)
        .post(`/groups/${testGroup._id}/members`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          userId: newUser._id.toString()
        })
        .expect(400);
      
      expect(response.body).toHaveProperty('error');
    });
  });
  
  // ========================================
  // メンバー削除テスト
  // ========================================
  describe('DELETE /groups/:id/members/:userId', () => {
    
    let testGroup;
    
    beforeEach(async () => {
      testGroup = await Group.create({
        name: 'テストグループ',
        admin: adminUser._id,
        members: [adminUser._id, memberUser._id]
      });
    });
    
    it('管理者がメンバーを削除できる', async () => {
      const response = await request(app)
        .delete(`/groups/${testGroup._id}/members/${memberUser._id}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);
      
      expect(response.body).toHaveProperty('success', true);
      
      // データベースで確認
      const updatedGroup = await Group.findById(testGroup._id);
      const isMember = updatedGroup.members.some(
        m => m.toString() === memberUser._id.toString()
      );
      expect(isMember).toBe(false);
    });
    
    it('メンバーは自分から脱出できる', async () => {
      const response = await request(app)
        .delete(`/groups/${testGroup._id}/members/${memberUser._id}`)
        .set('Authorization', `Bearer ${memberToken}`)
        .expect(200);
      
      expect(response.body).toHaveProperty('success', true);
    });
    
    it('メンバーは他を削除できない', async () => {
      const response = await request(app)
        .delete(`/groups/${testGroup._id}/members/${adminUser._id}`)
        .set('Authorization', `Bearer ${memberToken}`)
        .expect(403);
      
      expect(response.body).toHaveProperty('error');
    });
  });
  
  // ========================================
  // グループ削除テスト
  // ========================================
  describe('DELETE /groups/:id', () => {
    
    let testGroup;
    
    beforeEach(async () => {
      testGroup = await Group.create({
        name: 'テストグループ',
        description: 'テスト用',
        admin: adminUser._id,
        members: [adminUser._id, memberUser._id]
      });
    });
    
    it('管理者がグループを削除できる', async () => {
      const response = await request(app)
        .delete(`/groups/${testGroup._id}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);
      
      expect(response.body).toHaveProperty('success', true);
      
      // データベースで確認
      const deletedGroup = await Group.findById(testGroup._id);
      expect(deletedGroup).toBeNull();
    });
    
    it('メンバーは削除できない', async () => {
      const response = await request(app)
        .delete(`/groups/${testGroup._id}`)
        .set('Authorization', `Bearer ${memberToken}`)
        .expect(403);
      
      expect(response.body).toHaveProperty('error');
    });
  });
});
