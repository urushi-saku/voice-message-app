// ============================================================================
// オフラインバナーウィジェット
// ============================================================================
// 目的：ネットワークがオフラインの時に画面上部にバナーを表示し、
//       オンライン復帰時の同期状態も表示

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voice_message_app/services/network_connectivity_service.dart';
import 'package:voice_message_app/services/sync_service.dart';

/// オフライン状態を表示するバナー
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<NetworkConnectivityService, SyncService>(
      builder: (context, networkService, syncService, child) {
        // オンラインの場合は何も表示しない
        if (networkService.isOnline && !syncService.isSyncing) {
          return const SizedBox.shrink();
        }

        // 同期中の場合は同期バナーを表示
        if (syncService.isSyncing) {
          return _buildSyncingBanner(syncService);
        }

        // オフラインの場合はオフラインバナーを表示
        if (networkService.isOffline) {
          return _buildOfflineBanner();
        }

        return const SizedBox.shrink();
      },
    );
  }

  /// オフラインバナーを構築
  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.grey[800],
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'オフラインモード - 送信したメッセージは接続復帰時に自動送信されます',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  /// 同期中バナーを構築
  Widget _buildSyncingBanner(SyncService syncService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.blue[700],
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'メッセージを同期中...',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// ネットワーク状態を表示するインジケーター（小）
class NetworkStatusIndicator extends StatelessWidget {
  const NetworkStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkConnectivityService>(
      builder: (context, networkService, child) {
        if (networkService.isOnline) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              const Text(
                'オフライン',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// オフライン時の詳細情報を表示するボトムシート
class OfflineInfoBottomSheet extends StatelessWidget {
  const OfflineInfoBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const OfflineInfoBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<NetworkConnectivityService, SyncService>(
      builder: (context, networkService, syncService, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'オフラインモード状態',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              _buildInfoRow(
                icon: Icons.cloud_off,
                title: 'ネットワーク状態',
                value: networkService.getStatusText(),
                valueColor: networkService.isOnline
                    ? Colors.green
                    : Colors.grey,
              ),
              const SizedBox(height: 16),
              FutureBuilder<String>(
                future: networkService.getDetailedStatus(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return _buildInfoRow(
                      icon: Icons.info_outline,
                      title: '接続詳細',
                      value: snapshot.data!,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                icon: Icons.sync,
                title: '同期状態',
                value: syncService.isSyncing ? '同期中...' : '同期待機中',
                valueColor: syncService.isSyncing ? Colors.blue : Colors.grey,
              ),
              const SizedBox(height: 16),
              FutureBuilder<Map<String, int>>(
                future: syncService.getStorageInfo(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final info = snapshot.data!;
                    return _buildInfoRow(
                      icon: Icons.storage,
                      title: 'ローカルストレージ',
                      value:
                          'メッセージ: ${info['offlineMessages']}, キャッシュ: ${info['cachedMessages']}',
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('閉じる'),
                  ),
                  if (networkService.isOnline && !syncService.isSyncing)
                    ElevatedButton.icon(
                      onPressed: () async {
                        await syncService.syncOfflineMessages();
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('同期を開始しました')),
                          );
                        }
                      },
                      icon: const Icon(Icons.sync),
                      label: const Text('今すぐ同期'),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
