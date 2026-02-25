# バックエンドテスト実行レポート

**プロジェクト:** voice-message-app  
**対象:** バックエンド API（Node.js / Express）  
**テストフレームワーク:** Jest + Supertest  
**テストデータベース:** MongoDB In-Memory Server  
**実行日時:** 2026-02-25  
**実行環境:** Linux (Ubuntu / WSL2)

---

## 総合結果

| 項目 | 結果 |
|---|---|
| テストスイート | ✅ **5 / 5 合格** |
| テストケース | ✅ **68 / 68 合格** |
| 失敗 | 0 |
| スキップ | 0 |
| 合計実行時間 | 49.5 秒 |

---

## テストスイート別結果

### 1. 認証 API — `auth.test.js` ✅ 12/12

> `POST /auth/register` · `POST /auth/login` · `GET /auth/me`

| # | テストケース | 結果 | 時間 |
|---|---|---|---|
| 1 | 正しいデータで新規ユーザーを登録できる | ✅ | 874 ms |
| 2 | 必須フィールドが欠けている場合はエラーを返す | ✅ | 112 ms |
| 3 | 重複した username では登録できない | ✅ | 302 ms |
| 4 | 重複した email では登録できない | ✅ | 259 ms |
| 5 | 正しい認証情報でログインできる | ✅ | 465 ms |
| 6 | 誤ったパスワードではログインできない | ✅ | 454 ms |
| 7 | 存在しないユーザーではログインできない | ✅ | 285 ms |
| 8 | email が欠けている場合はエラーを返す | ✅ | 313 ms |
| 9 | password が欠けている場合はエラーを返す | ✅ | 306 ms |
| 10 | 有効なトークンでユーザー情報を取得できる | ✅ | 322 ms |
| 11 | トークンなしではアクセスできない | ✅ | 276 ms |
| 12 | 無効なトークンではアクセスできない | ✅ | 278 ms |

---

### 2. ユーザー API — `user.test.js` ✅ 12/12

> `GET /users` · `GET /users/:id` · `POST /users/:id/follow` · `DELETE /users/:id/follow` · `DELETE /users/:id`

| # | テストケース | 結果 | 時間 |
|---|---|---|---|
| 1 | ユーザー一覧を取得できる | ✅ | 1757 ms |
| 2 | 自分自身は除外される | ✅ | 1355 ms |
| 3 | クエリで絞り込みができる | ✅ | 1290 ms |
| 4 | ページングが機能する | ✅ | 1303 ms |
| 5 | ユーザー詳細を取得できる | ✅ | 620 ms |
| 6 | 存在しないユーザーは 404 を返す | ✅ | 624 ms |
| 7 | ユーザーをフォローできる | ✅ | 695 ms |
| 8 | 重複フォローはできない | ✅ | 710 ms |
| 9 | ユーザーをフォロー解除できる | ✅ | 658 ms |
| 10 | フォローしていないユーザーはエラー | ✅ | 790 ms |
| 11 | 自分のアカウントを削除できる | ✅ | 520 ms |
| 12 | 他のユーザーのアカウントは削除できない | ✅ | 583 ms |

---

### 3. メッセージ API — `message.test.js` ✅ 16/16

> `POST /messages/send-text` · `GET /messages/received` · `PUT /messages/:id/read` · `DELETE /messages/:id` · `GET /messages/threads` · `GET /messages/thread/:senderId` · `POST /messages/:id/reactions` · `DELETE /messages/:id/reactions/:emoji`

| # | テストケース | 結果 | 時間 |
|---|---|---|---|
| 1 | テキストメッセージを送信できる | ✅ | 664 ms |
| 2 | コンテンツなしはエラー | ✅ | 262 ms |
| 3 | 受信者なしはエラー | ✅ | 281 ms |
| 4 | フォローしていないユーザーには送信できない | ✅ | 376 ms |
| 5 | 受信メッセージ一覧を取得できる | ✅ | 297 ms |
| 6 | 未読フィルターが機能する | ✅ | 288 ms |
| 7 | メッセージを既読にできる | ✅ | 291 ms |
| 8 | 存在しないメッセージはエラー | ✅ | 268 ms |
| 9 | メッセージを削除できる | ✅ | 278 ms |
| 10 | 関係のないメッセージは削除できない | ✅ | 342 ms |
| 11 | スレッド一覧を取得できる | ✅ | 372 ms |
| 12 | スレッド詳細を取得できる | ✅ | 313 ms |
| 13 | 存在しないユーザーのスレッドは空 | ✅ | 298 ms |
| 14 | リアクションを追加できる | ✅ | 284 ms |
| 15 | 同じリアクションを2回追加するとエラー | ✅ | 291 ms |
| 16 | リアクションを削除できる | ✅ | 282 ms |

---

### 4. 通知 API — `notification.test.js` ✅ 11/11

> `GET /notifications` · `PATCH /notifications/:id/read` · `PATCH /notifications/read-all` · `DELETE /notifications/:id`

| # | テストケース | 結果 | 時間 |
|---|---|---|---|
| 1 | 通知一覧を取得できる | ✅ | 974 ms |
| 2 | 未読通知数が含まれる | ✅ | 518 ms |
| 3 | 未読フィルターが機能する | ✅ | 594 ms |
| 4 | ページングが機能する | ✅ | 578 ms |
| 5 | 通知を既読にできる | ✅ | 521 ms |
| 6 | 存在しない通知はエラー | ✅ | 511 ms |
| 7 | 他のユーザーの通知は操作できない | ✅ | 753 ms |
| 8 | 全通知を既読にできる | ✅ | 550 ms |
| 9 | 通知を削除できる | ✅ | 541 ms |
| 10 | 存在しない通知はエラー | ✅ | 441 ms |
| 11 | 他のユーザーの通知は削除できない | ✅ | 679 ms |

---

### 5. グループ API — `group.test.js` ✅ 17/17

> `POST /groups` · `GET /groups` · `GET /groups/:id` · `PUT /groups/:id` · `POST /groups/:id/members` · `DELETE /groups/:id/members/:userId` · `DELETE /groups/:id`

| # | テストケース | 結果 | 時間 |
|---|---|---|---|
| 1 | グループを作成できる | ✅ | 774 ms |
| 2 | グループ名なしはエラー | ✅ | 351 ms |
| 3 | メンバーを指定してグループを作成できる | ✅ | 371 ms |
| 4 | 参加しているグループ一覧を取得できる | ✅ | 371 ms |
| 5 | 参加していないグループは含まれない | ✅ | 511 ms |
| 6 | グループ詳細を取得できる | ✅ | 363 ms |
| 7 | 存在しないグループは 404 | ✅ | 349 ms |
| 8 | 管理者がグループ情報を更新できる | ✅ | 373 ms |
| 9 | メンバーは更新できない | ✅ | 356 ms |
| 10 | 管理者がメンバーを追加できる | ✅ | 436 ms |
| 11 | メンバーは追加できない | ✅ | 419 ms |
| 12 | 既に参加しているユーザーは追加できない | ✅ | 449 ms |
| 13 | 管理者がメンバーを削除できる | ✅ | 354 ms |
| 14 | メンバーは自分から脱出できる | ✅ | 354 ms |
| 15 | メンバーは他を削除できない | ✅ | 348 ms |
| 16 | 管理者がグループを削除できる | ✅ | 364 ms |
| 17 | メンバーは削除できない | ✅ | 352 ms |

---

## カバレッジ対象エンドポイント

| カテゴリ | エンドポイント | テスト済み |
|---|---|---|
| 認証 | `POST /auth/register` | ✅ |
| 認証 | `POST /auth/login` | ✅ |
| 認証 | `GET /auth/me` | ✅ |
| ユーザー | `GET /users` | ✅ |
| ユーザー | `GET /users/:id` | ✅ |
| ユーザー | `POST /users/:id/follow` | ✅ |
| ユーザー | `DELETE /users/:id/follow` | ✅ |
| ユーザー | `DELETE /users/:id` | ✅ |
| メッセージ | `POST /messages/send-text` | ✅ |
| メッセージ | `GET /messages/received` | ✅ |
| メッセージ | `PUT /messages/:id/read` | ✅ |
| メッセージ | `DELETE /messages/:id` | ✅ |
| メッセージ | `GET /messages/threads` | ✅ |
| メッセージ | `GET /messages/thread/:senderId` | ✅ |
| メッセージ | `POST /messages/:id/reactions` | ✅ |
| メッセージ | `DELETE /messages/:id/reactions/:emoji` | ✅ |
| 通知 | `GET /notifications` | ✅ |
| 通知 | `PATCH /notifications/:id/read` | ✅ |
| 通知 | `PATCH /notifications/read-all` | ✅ |
| 通知 | `DELETE /notifications/:id` | ✅ |
| グループ | `POST /groups` | ✅ |
| グループ | `GET /groups` | ✅ |
| グループ | `GET /groups/:id` | ✅ |
| グループ | `PUT /groups/:id` | ✅ |
| グループ | `POST /groups/:id/members` | ✅ |
| グループ | `DELETE /groups/:id/members/:userId` | ✅ |
| グループ | `DELETE /groups/:id` | ✅ |

---

## テスト環境

| 項目 | 値 |
|---|---|
| Node.js バージョン | 18+ |
| Jest バージョン | `^29.x` |
| Supertest | `^7.x` |
| mongodb-memory-server | `^10.x` |
| テスト実行オプション | `--runInBand --detectOpenHandles` |
| NODE_ENV | `test` |
| データベース | MongoDB In-Memory（本番DBへの影響なし） |
| レート制限 | テスト環境では自動スキップ |
| Firebase / Redis | モック接続（テスト環境用） |

---

## テスト実行コマンド

```bash
# バックエンドディレクトリで実行
cd /home/xiaox/voice-message-app/backend
npm test -- --testTimeout=5000 --forceExit

# ルートから実行
cd /home/xiaox/voice-message-app
npm test
```

---

*このレポートは 2026-02-25 に自動生成されました。*
