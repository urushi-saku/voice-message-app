// ========================================
// テーマプロバイダー - 状態管理
// ========================================
// 役割：ダークモード/ライトモードの切り替え
// 使用：メイン画面での設定保存・読み込み

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  // ========================================
  // プライベート変数
  // ========================================
  bool _isDarkMode = false;
  SharedPreferences? _prefs;

  // ========================================
  // Getter
  // ========================================
  bool get isDarkMode => _isDarkMode;

  // ========================================
  // 初期化
  // ========================================
  /// SharedPreferences から設定を読み込み
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs?.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  // ========================================
  // テーマ切り替え
  // ========================================
  /// テーマの切り替え（ダーク/ライト）
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _prefs?.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  /// 指定したモードに変更
  void setDarkMode(bool isDark) {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      _prefs?.setBool('isDarkMode', _isDarkMode);
      notifyListeners();
    }
  }

  /// システムテーマに同期
  void setSyncWithSystem(bool sync) {
    _prefs?.setBool('syncWithSystem', sync);
    notifyListeners();
  }

  /// システムテーマ同期設定を取得
  bool getSyncWithSystem() {
    return _prefs?.getBool('syncWithSystem') ?? false;
  }
}
