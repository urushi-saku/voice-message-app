// ========================================
// E2EE（エンドツーエンド暗号化）サービス
// ========================================
// X25519 Diffie-Hellman 鍵交換 + ChaCha20-Poly1305 認証付き暗号化により、
// サーバーを経由しても内容を読めないエンドツーエンド暗号化を実現します
//
// 【暗号アーキテクチャ（ハイブリッド暗号）】
//   1. 各ユーザーが X25519 キーペアをデバイス上で生成
//   2. 公開鍵のみサーバーに登録（秘密鍵はデバイスの SecureStorage にのみ保管）
//   3. 送信時:
//      a. ランダムな 32 バイトのメッセージ鍵 (MK) を生成
//      b. MK で音声/テキストを ChaCha20-Poly1305 で対称暗号化
//      c. 受信者ごとに一時 X25519 キーペアを生成 → DH 鍵合意 → 共有鍵で MK を暗号化
//      d. サーバーへ: [暗号化済みコンテンツ, ノンス, 受信者ごとの暗号化済み MK] を送信
//   4. 受信時:
//      a. 自分宛の encryptedKeyEntry を DH + ChaCha20 で復号 → MK を取得
//      b. MK + ノンスで暗号化済みコンテンツを復号 → 平文を取得
//
// 【パッケージ依存】
//   cryptography: ^2.7.0
//   flutter_secure_storage: ^9.2.4

import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

// ===================================================
// データクラス
// ===================================================

/// 受信者の公開鍵情報（送信側で使用）
class ReceiverKey {
  final String userId;
  final Uint8List publicKey; // X25519 公開鍵 32 バイト

  const ReceiverKey({required this.userId, required this.publicKey});
}

/// 受信者ごとの暗号化済み鍵エントリ
class EncryptedKeyEntry {
  final String userId;
  final String encryptedKey; // Base64: DH共有鍵で暗号化されたメッセージ鍵 + MAC
  final String ephemeralPublicKey; // Base64: このエントリ専用の一時公開鍵 (32 bytes)
  final String keyNonce; // Base64: ChaCha20 ノンス (12 bytes)

  const EncryptedKeyEntry({
    required this.userId,
    required this.encryptedKey,
    required this.ephemeralPublicKey,
    required this.keyNonce,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'encryptedKey': encryptedKey,
    'ephemeralPublicKey': ephemeralPublicKey,
    'keyNonce': keyNonce,
  };
}

/// 暗号化の結果
class E2eePayload {
  final String encryptedContent; // Base64: ChaCha20 暗号化済みコンテンツ + MAC
  final String contentNonce; // Base64: ChaCha20 ノンス (12 bytes)
  final List<EncryptedKeyEntry> encryptedKeys;

  const E2eePayload({
    required this.encryptedContent,
    required this.contentNonce,
    required this.encryptedKeys,
  });
}

// ===================================================
// E2EE サービス本体
// ===================================================
class E2eeService {
  static const _storage = FlutterSecureStorage();
  static const _skStorageKey = 'e2ee_secret_key';
  static const _pkStorageKey = 'e2ee_public_key';

  // 使用する暗号アルゴリズム
  static final _dh = X25519();
  static final _cipher = Chacha20.poly1305Aead();

  // ------------------------------------------------
  // キーペア管理
  // ------------------------------------------------

  /// 既存のキーペアを読み込む or 新規生成してデバイスの SecureStorage に保存する
  /// 戻り値: (publicKeyBytes 32B, privateKeyBytes 32B)
  static Future<(Uint8List, Uint8List)> getOrCreateKeyPair() async {
    final storedSk = await _storage.read(key: _skStorageKey);
    final storedPk = await _storage.read(key: _pkStorageKey);

    if (storedSk != null && storedPk != null) {
      return (base64Decode(storedPk), base64Decode(storedSk));
    }

    // 新規生成
    final keyPair = await _dh.newKeyPair();
    final keyPairData = await keyPair.extract();
    final pkBytes = Uint8List.fromList(keyPairData.publicKey.bytes);
    final skBytes = Uint8List.fromList(keyPairData.bytes);

    await _storage.write(key: _pkStorageKey, value: base64Encode(pkBytes));
    await _storage.write(key: _skStorageKey, value: base64Encode(skBytes));

    return (pkBytes, skBytes);
  }

  /// 公開鍵をサーバーにアップロードする（登録 / ログイン直後に呼び出す）
  static Future<void> uploadPublicKey() async {
    try {
      final (pk, _) = await getOrCreateKeyPair();
      final token = await AuthService.getToken();
      if (token == null) return;

      final res = await http.put(
        Uri.parse('$BASE_URL/users/public-key'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'publicKey': base64Encode(pk)}),
      );

      if (res.statusCode != 200) {
        print('[E2EE] 公開鍵アップロード失敗: ${res.statusCode}');
      }
    } catch (e) {
      print('[E2EE] 公開鍵アップロードエラー: $e');
    }
  }

  /// 特定ユーザーの公開鍵をサーバーから取得する
  /// 戻り値: null ならそのユーザーは E2EE 未登録
  static Future<Uint8List?> fetchPublicKey(String userId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final res = await http.get(
        Uri.parse('$BASE_URL/users/$userId/public-key'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body);
      final pk = data['publicKey'] as String?;
      return pk != null ? base64Decode(pk) : null;
    } catch (e) {
      print('[E2EE] 公開鍵取得エラー: $e');
      return null;
    }
  }

  // ------------------------------------------------
  // 暗号化
  // ------------------------------------------------

  /// コンテンツ（音声バイト列 or テキストバイト列）を複数受信者向けに暗号化する
  ///
  /// 【パラメータ】
  ///   content   — 暗号化対象バイト列
  ///   receivers — 受信者リスト。送信者自身も含める（自分も復号できるようにするため）
  ///
  /// 【戻り値】
  ///   E2eePayload（encryptedContent, contentNonce, encryptedKeys）
  static Future<E2eePayload> encryptForReceivers(
    Uint8List content,
    List<ReceiverKey> receivers,
  ) async {
    // ① ランダムなメッセージ鍵を生成（ChaCha20 の鍵長 = 32 bytes）
    final messageKey = await _cipher.newSecretKey();
    final messageKeyBytes = await messageKey.extractBytes();

    // ② コンテンツを ChaCha20-Poly1305 で対称暗号化
    final contentNonce = _cipher.newNonce();
    final contentBox = await _cipher.encrypt(
      content.toList(),
      secretKey: messageKey,
      nonce: contentNonce,
    );

    // ciphertext + mac(16B) を結合して保存
    final encryptedContent = Uint8List.fromList([
      ...contentBox.cipherText,
      ...contentBox.mac.bytes,
    ]);

    // ③ 受信者ごとにメッセージ鍵を非対称暗号化
    final encryptedKeys = <EncryptedKeyEntry>[];
    for (final r in receivers) {
      // 受信者ごとに一時キーペアを生成
      final ephKeyPair = await _dh.newKeyPair();
      final ephKeyPairData = await ephKeyPair.extract();
      final ephPublicKeyBytes = Uint8List.fromList(
        ephKeyPairData.publicKey.bytes,
      );

      // DH 鍵合意 → 受信者公開鍵 × 一時秘密鍵 → 共有秘密
      final receiverPublicKey = SimplePublicKey(
        r.publicKey.toList(),
        type: KeyPairType.x25519,
      );
      final sharedSecret = await _dh.sharedSecretKey(
        keyPair: ephKeyPair,
        remotePublicKey: receiverPublicKey,
      );

      // 共有秘密でメッセージ鍵を暗号化
      final keyNonce = _cipher.newNonce();
      final keyBox = await _cipher.encrypt(
        messageKeyBytes,
        secretKey: sharedSecret,
        nonce: keyNonce,
      );
      final encryptedKey = Uint8List.fromList([
        ...keyBox.cipherText,
        ...keyBox.mac.bytes,
      ]);

      encryptedKeys.add(
        EncryptedKeyEntry(
          userId: r.userId,
          encryptedKey: base64Encode(encryptedKey),
          ephemeralPublicKey: base64Encode(ephPublicKeyBytes),
          keyNonce: base64Encode(Uint8List.fromList(keyNonce)),
        ),
      );
    }

    return E2eePayload(
      encryptedContent: base64Encode(encryptedContent),
      contentNonce: base64Encode(Uint8List.fromList(contentNonce)),
      encryptedKeys: encryptedKeys,
    );
  }

  // ------------------------------------------------
  // 復号（Base64 バージョン — テキストメッセージ用）
  // ------------------------------------------------

  /// 暗号化されたコンテンツ（Base64）を復号する
  static Future<Uint8List?> decryptContent({
    required String encryptedContentB64,
    required String contentNonceB64,
    required List<Map<String, dynamic>> encryptedKeys,
    required String myUserId,
  }) async {
    return decryptBytes(
      encryptedBytes: base64Decode(encryptedContentB64),
      contentNonceB64: contentNonceB64,
      encryptedKeys: encryptedKeys,
      myUserId: myUserId,
    );
  }

  // ------------------------------------------------
  // 復号（生バイト列バージョン — 音声ファイルダウンロード用）
  // ------------------------------------------------

  /// ダウンロードした暗号化済み音声バイト列を復号する
  ///
  /// 格納形式: [ciphertext ... | MAC(16B)]
  static Future<Uint8List?> decryptBytes({
    required Uint8List encryptedBytes,
    required String contentNonceB64,
    required List<Map<String, dynamic>> encryptedKeys,
    required String myUserId,
  }) async {
    try {
      // 自分の秘密鍵を取得
      final (myPkBytes, mySkBytes) = await getOrCreateKeyPair();

      // 自分宛のエントリを検索
      final myEntry = encryptedKeys.firstWhere(
        (k) => k['userId'] == myUserId,
        orElse: () => {},
      );
      if (myEntry.isEmpty) {
        print('[E2EE] 自分宛の暗号化鍵エントリが見つかりません (userId=$myUserId)');
        return null;
      }

      final ephPkBytes = base64Decode(myEntry['ephemeralPublicKey'] as String);
      final keyNonceBytes = base64Decode(myEntry['keyNonce'] as String);
      final encKeyBytes = base64Decode(myEntry['encryptedKey'] as String);

      // 自分のキーペアを復元
      final myKeyPair = SimpleKeyPairData(
        mySkBytes.toList(),
        publicKey: SimplePublicKey(
          myPkBytes.toList(),
          type: KeyPairType.x25519,
        ),
        type: KeyPairType.x25519,
      );

      // DH 鍵合意: 自分の秘密鍵 × 送信側の一時公開鍵 → 共有秘密
      final ephPublicKey = SimplePublicKey(
        ephPkBytes.toList(),
        type: KeyPairType.x25519,
      );
      final sharedSecret = await _dh.sharedSecretKey(
        keyPair: myKeyPair,
        remotePublicKey: ephPublicKey,
      );

      // メッセージ鍵を復号（末尾 16 バイトが MAC）
      const macLength = 16;
      final keySecretBox = SecretBox(
        encKeyBytes.sublist(0, encKeyBytes.length - macLength).toList(),
        nonce: keyNonceBytes.toList(),
        mac: Mac(encKeyBytes.sublist(encKeyBytes.length - macLength).toList()),
      );
      final messageKeyBytes = await _cipher.decrypt(
        keySecretBox,
        secretKey: sharedSecret,
      );

      // コンテンツを復号
      final contentNonceBytes = base64Decode(contentNonceB64);
      final contentSecretBox = SecretBox(
        encryptedBytes.sublist(0, encryptedBytes.length - macLength).toList(),
        nonce: contentNonceBytes.toList(),
        mac: Mac(
          encryptedBytes.sublist(encryptedBytes.length - macLength).toList(),
        ),
      );
      final plaintext = await _cipher.decrypt(
        contentSecretBox,
        secretKey: SecretKey(messageKeyBytes),
      );

      return Uint8List.fromList(plaintext);
    } catch (e) {
      print('[E2EE] 復号エラー: $e');
      return null;
    }
  }
}
