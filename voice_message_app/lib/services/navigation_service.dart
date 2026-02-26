// ========================================
// NavigationService - グローバルナビゲーション管理
// ========================================
// ウィジェットツリー外（FCMサービス等）から
// 画面遷移を行うためのサービス。
// GlobalKey<NavigatorState> を保持し、
// BuildContext なしで Navigator を操作できる。

import 'package:flutter/material.dart';
import '../screens/home_page.dart';
import '../screens/thread_detail_screen.dart';
import '../screens/user_profile_screen.dart';
import 'user_service.dart';

class NavigationService {
  // ========================================
  // グローバル NavigatorKey（シングルトン）
  // ========================================
  /// MaterialApp の navigatorKey に渡すキー。
  /// このキーを通じて BuildContext なしで画面遷移できる。
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// 現在の NavigatorState を返す
  static NavigatorState? get navigator => navigatorKey.currentState;

  // ========================================
  // 通知タップ時のナビゲーション
  // ========================================
  /// FCM通知データに基づいて適切な画面に遷移する。
  ///
  /// 優先順位：
  /// 1. type == 'new_message' かつ senderId あり → ThreadDetailScreen へ
  /// 2. type == 'follow' かつ senderId あり → UserProfileScreen へ
  /// 3. それ以外 → ホーム（メッセージタブ）へ
  static void navigateFromNotification(Map<String, dynamic> data) {
    final nav = navigator;
    if (nav == null) {
      print('⚠️  NavigationService: NavigatorState が未初期化です');
      return;
    }

    final type = data['type'] as String?;
    final senderId = data['senderId'] as String?;
    final senderUsername = data['senderUsername'] as String? ?? '送信者';
    final senderProfileImage = data['senderProfileImage'] as String?;

    print('🗺️  NavigationService: type=$type, senderId=$senderId');

    if (type == 'new_message' && senderId != null && senderId.isNotEmpty) {
      // メッセージスレッド詳細画面へ遷移
      // まず HomePage まで遷移しつつ、並行してAPIから正確なユーザー情報を取得する。
      // これによりThreadDetailScreen表示時には既に正確な名前・画像が揃っており
      // 再描画によるちらつきがない。
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );

      // HomePage 描画とユーザー情報取得を並行実行。
      // delay と API 呼び出しを同時に開始し、両方終わり次第 ThreadDetailScreen へ遷移。
      // これにより画面表示時には既に正確な名前・画像が揃っており再描画が起きない。
      Future(() async {
        // 二つを同時に開始
        final userFuture = UserService.getUserById(
          senderId,
        ).then<UserInfo?>((u) => u).catchError((_) => null as UserInfo?);
        await Future.delayed(const Duration(milliseconds: 300));
        final user = await userFuture;

        final resolvedUsername = user?.username ?? senderUsername;
        final resolvedProfileImage = user?.profileImage ?? senderProfileImage;

        navigator?.push(
          MaterialPageRoute(
            builder: (_) => ThreadDetailScreen(
              senderId: senderId,
              senderUsername: resolvedUsername,
              senderProfileImage: resolvedProfileImage,
            ),
          ),
        );
      });
    } else if (type == 'follow' && senderId != null && senderId.isNotEmpty) {
      // フォロー通知の場合はそのユーザーのプロフィール画面へ遷移
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );

      Future(() async {
        final userFuture = UserService.getUserById(
          senderId,
        ).then<UserInfo?>((u) => u).catchError((_) => null as UserInfo?);
        await Future.delayed(const Duration(milliseconds: 300));
        final user = await userFuture;

        if (user != null) {
          navigator?.push(
            MaterialPageRoute(builder: (_) => UserProfileScreen(user: user)),
          );
        }
      });
    } else {
      // その他の通知またはデータが不完全な場合はホームへ
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    }
  }
}
