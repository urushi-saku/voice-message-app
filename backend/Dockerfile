# ========================================
# Vio Backend — マルチステージ Dockerfile
# ========================================
# 「自分のPCでは動いたのに…」を撲滅する Dockerfile
#
# Stage 1 (deps):   全依存パッケージをインストール
# Stage 2 (build):  本番用 node_modules のみに絞り込み
# Stage 3 (runner): 軽量ランタイムイメージ（最終成果物）
# ========================================

# ── Stage 1: 依存解決 ──────────────────────────────────────
FROM node:20-alpine AS deps

# セキュリティパッチ適用
RUN apk add --no-cache libc6-compat

WORKDIR /app

# package.json と package-lock.json だけ先にコピー（レイヤーキャッシュ活用）
COPY package.json package-lock.json* ./

# 全依存（devDependencies含む）をインストール
RUN npm ci --frozen-lockfile

# ── Stage 2: 本番依存のみ抽出 ───────────────────────────────
FROM node:20-alpine AS prod-deps

RUN apk add --no-cache libc6-compat

WORKDIR /app

COPY package.json package-lock.json* ./

# 本番依存のみ（devDependencies はインストールしない）
RUN npm ci --frozen-lockfile --omit=dev

# ── Stage 3: ランタイムイメージ ─────────────────────────────
FROM node:20-alpine AS runner

# 必要最小限のシステムパッケージ
RUN apk add --no-cache dumb-init

# セキュリティ: root以外のユーザーで動かす
RUN addgroup --system --gid 1001 viogroup && \
    adduser  --system --uid 1001 viouser

WORKDIR /app

# 本番 node_modules をコピー
COPY --from=prod-deps --chown=viouser:viogroup /app/node_modules ./node_modules

# アプリケーションコードをコピー
COPY --chown=viouser:viogroup . .

# uploads ディレクトリが存在することを保証（ボリュームマウント前の初期化）
RUN mkdir -p uploads/profiles uploads/groups uploads/headers

ENV NODE_ENV=production
ENV PORT=3000

# NOTE: serviceAccountKey.json は docker-compose の secrets or volume でマウントする
#       コンテナイメージに含めない（セキュリティ上の理由）

EXPOSE 3000

# dumb-init を使って PID 1 問題・シグナル伝播を適切に処理
USER viouser
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "app.js"]
