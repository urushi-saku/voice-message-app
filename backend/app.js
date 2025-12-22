const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const app = express();
const PORT = 3000;

// 音声ファイル保存用ディレクトリ
const uploadDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir);
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + '-' + file.originalname);
  }
});
const upload = multer({ storage });

// 音声ファイルアップロードAPI
app.post('/upload', upload.single('voice'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'ファイルがありません' });
  }
  res.json({ filename: req.file.filename });
});

// 音声ファイル一覧取得API
app.get('/voices', (req, res) => {
  if (!fs.existsSync(uploadDir)) {
    return res.json({ files: [] });
  }
  
  const files = fs.readdirSync(uploadDir).filter(file => {
    // 音声ファイルのみフィルタ（m4a, mp3, wav, aac など）
    return /\.(m4a|mp3|wav|aac|ogg)$/i.test(file);
  });
  
  res.json({ files });
});

// 音声ファイルダウンロードAPI
app.get('/voice/:filename', (req, res) => {
  const filePath = path.join(uploadDir, req.params.filename);
  if (!fs.existsSync(filePath)) {
    return res.status(404).json({ error: 'ファイルが見つかりません' });
  }
  res.sendFile(filePath);
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
