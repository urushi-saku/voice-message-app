#!/bin/bash
# ========================================
# 開発環境起動スクリプト
# 使い方: ./dev.sh
# ========================================
ADB=/home/xiaox/Android/Sdk/platform-tools/adb
BACKEND_DIR=/home/xiaox/voice-message-app/backend
FLUTTER_DIR=/home/xiaox/voice-message-app/voice_message_app

# デバイス接続を監視してadb reverseを自動設定するバックグラウンドプロセス
adb_reverse_watcher() {
  echo "[adb-watcher] デバイス監視を開始..."
  while true; do
    $ADB wait-for-device 2>/dev/null
    echo "[adb-watcher] デバイス接続検出 → adb reverse tcp:3000 tcp:3000"
    $ADB reverse tcp:3000 tcp:3000 2>/dev/null && echo "[adb-watcher] ✓ adb reverse 完了"
    # 切断を待つ
    $ADB wait-for-disconnect 2>/dev/null
    echo "[adb-watcher] デバイス切断を検出"
    sleep 1
  done
}

# バックグラウンドで監視開始
adb_reverse_watcher &
WATCHER_PID=$!

# 既に接続済みのデバイスにも即時適用
echo "[adb] 接続済みデバイスに adb reverse を適用..."
$ADB reverse tcp:3000 tcp:3000 2>/dev/null && echo "[adb] ✓ adb reverse 完了" || echo "[adb] デバイス未接続（watcher が接続待機中）"

# バックエンド起動（バックグラウンド）
echo "[backend] バックエンドサーバーを起動中..."
cd "$BACKEND_DIR" && npm start &
BACKEND_PID=$!
sleep 2

# Flutter起動
echo "[flutter] Flutter アプリを起動中..."
cd "$FLUTTER_DIR" && flutter run -d pixel

# 終了時のクリーンアップ
echo ""
echo "終了中..."
kill $WATCHER_PID 2>/dev/null
kill $BACKEND_PID 2>/dev/null
wait 2>/dev/null
echo "完了"
