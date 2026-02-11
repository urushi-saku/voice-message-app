// ============================================================================
// ネットワーク接続状態監視サービス
// ============================================================================
// 目的：インターネット接続状態をリアルタイムで監視し、
//       オフライン/オンラインの切り替えを検出・通知

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class NetworkConnectivityService extends ChangeNotifier {
  // ============================================================================
  // シングルトンパターン
  // ============================================================================
  static final NetworkConnectivityService _instance =
      NetworkConnectivityService._internal();

  factory NetworkConnectivityService() {
    return _instance;
  }

  NetworkConnectivityService._internal();

  // ============================================================================
  // プロパティ
  // ============================================================================

  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;
  DateTime? _lastStatusChangeTime;

  // ============================================================================
  // ゲッター
  // ============================================================================

  /// 現在オンラインかどうか
  bool get isOnline => _isOnline;

  /// 現在オフラインかどうか
  bool get isOffline => !_isOnline;

  /// 最後に接続状態が変わった時刻
  DateTime? get lastStatusChangeTime => _lastStatusChangeTime;

  /// オンラインになってからの経過時間（秒）
  int get onlineDurationSeconds {
    if (_lastStatusChangeTime == null || _isOnline == false) {
      return 0;
    }
    return DateTime.now().difference(_lastStatusChangeTime!).inSeconds;
  }

  // ============================================================================
  // 初期化
  // ============================================================================

  /// ネットワーク監視を初期化
  /// アプリ起動時に一度だけ呼び出す
  Future<void> initialize() async {
    // 初期の接続状態をチェック
    await _checkConnectivity();

    // リアルタイム監視を開始
    _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _handleConnectivityChange(results);
    });
  }

  // ============================================================================
  // 内部処理
  // ============================================================================

  /// 接続状態を確認
  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectivityStatus(results);
    } catch (e) {
      if (kDebugMode) {
        print('接続状態の確認に失敗: $e');
      }
    }
  }

  /// 接続状態の変更を処理
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    _updateConnectivityStatus(results);
  }

  /// 接続状態ステータスを更新
  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;

    // インターネット接続があるか判定
    // NOTE: WiFi/Mobile/Ethernet/VPNのいずれかで接続していれば、
    //       実際のインターネット接続があると判定
    //       (詳細確認はPingなどで別途可能)
    _isOnline =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);

    // 状態が変わった場合のみ処理
    if (wasOnline != _isOnline) {
      _lastStatusChangeTime = DateTime.now();

      if (kDebugMode) {
        print('ネットワーク状態が変更: ${_isOnline ? 'オンライン' : 'オフライン'}');
      }

      // リスナーに通知
      notifyListeners();

      // 状態変更コールバックを実行
      if (_isOnline) {
        _onOnline();
      } else {
        _onOffline();
      }
    }
  }

  // ============================================================================
  // 接続状態イベントハンドラー
  // ============================================================================

  /// オンラインになった時の処理
  Future<void> _onOnline() async {
    if (kDebugMode) {
      print('[ネットワーク] オンラインモードに切り替え');
    }

    // オンライン復帰時のコールバックがあれば実行
    // 同期処理などはSyncServiceで実装
    _onOnlineCallbacks.forEach((callback) => callback());
  }

  /// オフラインになった時の処理
  Future<void> _onOffline() async {
    if (kDebugMode) {
      print('[ネットワーク] オフラインモードに切り替え');
    }

    // オフライン移行時のコールバックがあれば実行
    _onOfflineCallbacks.forEach((callback) => callback());
  }

  // ============================================================================
  // コールバック管理
  // ============================================================================

  final List<Function()> _onOnlineCallbacks = [];
  final List<Function()> _onOfflineCallbacks = [];

  /// オンラインになった時のコールバックを登録
  void addOnOnlineCallback(Function() callback) {
    _onOnlineCallbacks.add(callback);
  }

  /// オフラインになった時のコールバックを登録
  void addOnOfflineCallback(Function() callback) {
    _onOfflineCallbacks.add(callback);
  }

  /// オンラインコールバックを削除
  void removeOnOnlineCallback(Function() callback) {
    _onOnlineCallbacks.remove(callback);
  }

  /// オフラインコールバックを削除
  void removeOnOfflineCallback(Function() callback) {
    _onOfflineCallbacks.remove(callback);
  }

  // ============================================================================
  // ユーティリティメソッド
  // ============================================================================

  /// 接続状態を日本語で取得
  String getStatusText() {
    return _isOnline ? 'オンライン' : 'オフライン';
  }

  /// 接続状態の詳細情報を取得
  Future<String> getDetailedStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();

      if (results.isEmpty || results.contains(ConnectivityResult.none)) {
        return 'インターネット接続なし';
      }

      final statusTexts = results.map((result) {
        switch (result) {
          case ConnectivityResult.mobile:
            return 'モバイル';
          case ConnectivityResult.wifi:
            return 'WiFi';
          case ConnectivityResult.ethernet:
            return 'イーサネット';
          case ConnectivityResult.vpn:
            return 'VPN';
          case ConnectivityResult.bluetooth:
            return 'Bluetooth';
          case ConnectivityResult.other:
            return 'その他';
          case ConnectivityResult.none:
            return 'なし';
        }
      });

      return '接続中: ${statusTexts.join(', ')}';
    } catch (e) {
      return '接続状態確認中';
    }
  }
}
