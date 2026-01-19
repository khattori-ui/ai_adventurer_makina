import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/makina.dart';

class AIService {
  static String get apiKey => dotenv.env['ANTHROPIC_API_KEY'] ?? '';
  static const String apiUrl = 'https://api.anthropic.com/v1/messages';

  static Future<String> _callClaudeAPI(String prompt) async {
    // ★ APIキーが空白、またはデフォルト文字の場合はシミュレーションモードで返す
    if (apiKey.isEmpty || apiKey.contains('貼り付けてください')) {
      return '（シミュレーションモード）師匠！今はテスト中だから、決まったお返事しかできないけど、クエストの結果はバッチリだよ！';
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-3-5-sonnet-20241022',
          'max_tokens': 1000,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'];
      }
      return 'APIエラーが発生したみたい（コード: ${response.statusCode}）';
    } catch (e) {
      return '通信エラーだよ。ネット環境を確認してみてね。';
    }
  }

  // クエスト報告
  static Future<String> generateQuestReport(
      {required Makina makina,
      required Quest quest,
      required bool success}) async {
    return await _callClaudeAPI("クエスト報告プロンプト");
  }

  // 会話応答
  static Future<Map<String, dynamic>> generateResponse(
      {required Makina makina,
      required String playerMessage,
      required Quest? lastQuest,
      required bool? lastQuestSuccess}) async {
    String response = await _callClaudeAPI("会話プロンプト");
    return {
      'response': response,
      'intimacyChange': 1.0,
      'braveChange': 0.0,
      'dependentChange': 0.0,
    };
  }
}
