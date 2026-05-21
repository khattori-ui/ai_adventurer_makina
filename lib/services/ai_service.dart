import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/makina.dart';

class AIService {
  static String get apiKey => dotenv.env['ANTHROPIC_API_KEY'] ?? '';
  static const String apiUrl = 'https://api.anthropic.com/v1/messages';

  static Future<String> _callClaudeAPI(String prompt) async {
    // 開発用のシミュレーションモード
    if (apiKey.isEmpty || apiKey.contains('貼り付けてください')) {
      return '（シミュレーションモード）師匠！今は修行中だから決まったお返事しかできないけど、クエストの結果はバッチリ記録しておくね！';
    }

    try {
      final response = await http
          .post(
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
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('通信が途切れちゃった'),
          );

      switch (response.statusCode) {
        case 200:
          final data = jsonDecode(response.body);
          final content = data['content'];
          if (content is List && content.isNotEmpty && content[0]['text'] != null) {
            return content[0]['text'] as String;
          }
          return 'マキナ：（うまく言葉が出てこない…）';

        case 401:
          // 401: 契約エラー（システム設定ミス）
          return 'マキナ：師匠、なんだか「魔法のつながり」が悪いみたい…。ギルドの運営さんが直してくれるのを待ってみよう！';

        case 429:
          // 429: 利用制限（APIの回数制限）
          return 'マキナ：ごめん、魔力を使いすぎちゃって疲れちゃったみたい…。少し休ませてくれたら、また元気になるから待っててね！';

        case 500:
        case 502:
        case 503:
          // 500系: サーバーエラー（AI側のトラブル）
          return 'マキナ：ううっ、世界の理（サーバー）が荒れているみたい…。こればっかりは仕方ないから、落ち着くまで待とう？';

        default:
          return 'マキナ：なんだか不思議な力が働いて、うまく話せないよ…。';
      }
    } on SocketException {
      // ネットワーク未接続（ユーザーの通信不良）
      return 'マキナ：電波の精霊さんがいないみたい。場所を変えて、もう一度あたしを呼んでみて！';
    } on TimeoutException {
      return 'マキナ：ちょっと考え込みすぎちゃった。もう一回、ゆっくり話しかけてみて！';
    } catch (e) {
      return 'マキナ：うう、頭の中がこんがらがっちゃった…。少し時間をおいてから、また話しかけてね。';
    }
  }

  // クエスト報告
  static Future<String> generateQuestReport(
      {required Makina makina,
      required Quest quest,
      required bool success}) async {
    return await _callClaudeAPI(
        "マキナとして、${quest.name}の結果が${success ? '成功' : '失敗'}したことを報告して。");
  }

  // 会話応答
  static Future<Map<String, dynamic>> generateResponse(
      {required Makina makina,
      required String playerMessage,
      required Quest? lastQuest,
      required bool? lastQuestSuccess}) async {
    String response = await _callClaudeAPI("マキナとして次のメッセージに応答して：$playerMessage");
    return {
      'response': response,
      'intimacyChange': 1.0,
      'braveChange': 0.0,
      'dependentChange': 0.0,
    };
  }
}
