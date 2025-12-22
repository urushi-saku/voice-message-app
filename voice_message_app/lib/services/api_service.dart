// ========================================
// APIサービス - サーバー通信を管理
// ========================================
// 初学者向け説明：
// このファイルは、バックエンドサーバーとの通信をすべて管理します
// HTTP通信のロジックをここに集約することで、他のファイルがシンプルになります

import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants.dart';

/// サーバーとの通信を担当するサービスクラス
class ApiService {
  // ========================================
  // 音声ファイル一覧を取得
  // ========================================
  /// サーバーから音声ファイルのリストを取得します
  /// 
  /// 戻り値: ファイル名のリスト（例: ["voice_123.m4a", "voice_456.m4a"]）
  /// エラーが発生した場合は空のリストを返します
  static Future<List<String>> fetchVoices() async {
    try {
      final response = await http.get(Uri.parse('$kServerUrl$kVoicesEndpoint'));
      
      if (response.statusCode == 200) {
        // JSONを簡易的にパース
        final data = response.body;
        final startIndex = data.indexOf('[');
        final endIndex = data.lastIndexOf(']');
        
        if (startIndex != -1 && endIndex != -1) {
          final filesString = data.substring(startIndex + 1, endIndex);
          
          if (filesString.trim().isEmpty) {
            return [];
          }
          
          return filesString
              .split(',')
              .map((f) => f.trim().replaceAll('"', ''))
              .where((f) => f.isNotEmpty)
              .toList();
        }
      }
      
      return [];
    } catch (e) {
      print('音声リスト取得エラー: $e');
      return [];
    }
  }

  // ========================================
  // 音声ファイルをアップロード
  // ========================================
  /// 録音した音声ファイルをサーバーにアップロードします
  /// 
  /// パラメータ:
  ///   - filePath: アップロードするファイルのパス
  /// 
  /// 戻り値:
  ///   - true: アップロード成功
  ///   - false: アップロード失敗
  static Future<bool> uploadVoice(String filePath) async {
    try {
      final file = File(filePath);
      
      // Multipartリクエストを作成
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$kServerUrl$kUploadEndpoint'),
      );
      
      // ファイルをリクエストに追加
      request.files.add(
        await http.MultipartFile.fromPath('voice', file.path),
      );
      
      // サーバーに送信
      final response = await request.send();
      
      return response.statusCode == 200;
    } catch (e) {
      print('アップロードエラー: $e');
      return false;
    }
  }

  // ========================================
  // 音声ファイルのURLを取得
  // ========================================
  /// サーバー上の音声ファイルのURLを生成します
  /// 
  /// パラメータ:
  ///   - filename: 音声ファイル名
  /// 
  /// 戻り値: 音声ファイルの完全なURL
  static String getVoiceUrl(String filename) {
    return '$kServerUrl$kVoiceEndpoint/$filename';
  }
}
