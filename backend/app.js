// ========================================
// ボイスメッセージアプリ - バックエンドサーバー
// ========================================
// このファイルはNode.js + Expressで書かれたサーバーです
// Flutterアプリから送られてきた音声ファイルを受け取ったり、
// 保存されている音声ファイルを取得・再生するための機能を提供します

// 必要なモジュール（Node.jsの機能）をインポート
const express = require('express');          // Webサーバーを作るためのフレームワーク
const multer = require('multer');            // ファイルアップロードを処理するライブラリ
const path = require('path');                // ファイルパスを操作するためのモジュール
const fs = require('fs');                    // ファイル操作を行うためのモジュール

const app = express();                       // Expressアプリケーションを作成
const PORT = 3000;                           // サーバーが待機するポート番号

// ========================================
// ファイル保存設定
// ========================================
// 音声ファイルを保存するディレクトリを指定
const uploadDir = path.join(__dirname, 'uploads');

// uploadsフォルダが存在しない場合は作成する
// __dirname は現在のファイルがあるディレクトリパスを表します
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir);
}

// Multerの設定（ファイルをどのように保存するか）
const storage = multer.diskStorage({
  // destination: ファイルをどこに保存するか
  destination: (req, file, cb) => {
    cb(null, uploadDir);  // uploadsディレクトリに保存
  },
  
  // filename: 保存するファイル名をどうするか
  filename: (req, file, cb) => {
    // 例：1703234567890-voice.m4a
    // タイムスタンプ + ファイル名で、重複しないファイル名を作成
    cb(null, Date.now() + '-' + file.originalname);
  }
});
const upload = multer({ storage });

// ========================================
// API 1: 音声ファイルアップロードAPI
// ========================================
// Flutterアプリから音声ファイルを受け取って保存する
// POST http://localhost:3000/upload
// リクエスト：multipart/form-data で voice フィールドに音声ファイルを含める
app.post('/upload', upload.single('voice'), (req, res) => {
  if (!req.file) {
    // ファイルが送られていない場合はエラーレスポンス
    return res.status(400).json({ error: 'ファイルがありません' });
  }
  // 成功した場合は保存されたファイル名をFlutterアプリに返す
  res.json({ filename: req.file.filename });
});

// ========================================
// API 2: 音声ファイル一覧取得API
// ========================================
// サーバーに保存されている全ての音声ファイルのリストを取得する
// GET http://localhost:3000/voices
// レスポンス例：{ "files": ["1703234567890-voice1.m4a", "1703234890-voice2.m4a"] }
app.get('/voices', (req, res) => {
  // uploadsディレクトリが存在しない場合は空のリストを返す
  if (!fs.existsSync(uploadDir)) {
    return res.json({ files: [] });
  }
  
  // uploadsディレクトリ内の全ファイルを取得
  const files = fs.readdirSync(uploadDir).filter(file => {
    // 正規表現で音声ファイルのみを抽出
    // m4a, mp3, wav, aac, ogg などの拡張子を持つファイルのみフィルタリング
    return /\.(m4a|mp3|wav|aac|ogg)$/i.test(file);
  });
  
  // フィルタリングされたファイルリストをJSONで返す
  res.json({ files });
});

// ========================================
// API 3: 音声ファイルダウンロードAPI
// ========================================
// 特定の音声ファイルを取得して再生する
// GET http://localhost:3000/voice/:filename
// 例：GET http://localhost:3000/voice/1703234567890-voice.m4a
app.get('/voice/:filename', (req, res) => {
  // ダウンロード対象のファイルパスを作成
  const filePath = path.join(uploadDir, req.params.filename);
  
  // ファイルが存在しない場合はエラーレスポンス
  if (!fs.existsSync(filePath)) {
    return res.status(404).json({ error: 'ファイルが見つかりません' });
  }
  
  // ファイルをクライアント（Flutterアプリ）に送信
  // sendFileはファイルを自動的に開いて送信してくれます
  res.sendFile(filePath);
});

// ========================================
// サーバー起動
// ========================================
// 指定したPORTでサーバーを起動
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
