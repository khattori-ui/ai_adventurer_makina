import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/makina.dart';

class AIService {
  static String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _model = 'gemini-1.5-flash';
  static String get _apiUrl =>
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$apiKey';

  static Future<String> _callGeminiAPI(String prompt) async {
    // 開発用のシミュレーションモード
    if (apiKey.isEmpty || apiKey.contains('貼り付けてください')) {
      return '（シミュレーションモード）師匠！今は修行中だから決まったお返事しかできないけど、クエストの結果はバッチリ記録しておくね！';
    }

    try {
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'generationConfig': {
                'maxOutputTokens': 500,
                'temperature': 0.9,
              },
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('通信が途切れちゃった'),
          );

      switch (response.statusCode) {
        case 200:
          final data = jsonDecode(response.body);
          final candidates = data['candidates'];
          if (candidates is List &&
              candidates.isNotEmpty &&
              candidates[0]['content']?['parts'] is List &&
              (candidates[0]['content']['parts'] as List).isNotEmpty) {
            return candidates[0]['content']['parts'][0]['text'] as String;
          }
          return 'マキナ：（うまく言葉が出てこない…）';

        case 400:
          return 'マキナ：なんだか言葉がうまくまとまらないみたい……もう一度話しかけてみて？';

        case 401:
        case 403:
          return 'マキナ：師匠、なんだか「魔法のつながり」が悪いみたい…。ギルドの運営さんが直してくれるのを待ってみよう！';

        case 429:
          return 'マキナ：ごめん、魔力を使いすぎちゃって疲れちゃったみたい…。少し休ませてくれたら、また元気になるから待っててね！';

        case 500:
        case 502:
        case 503:
          return 'マキナ：ううっ、世界の理（サーバー）が荒れているみたい…。こればっかりは仕方ないから、落ち着くまで待とう？';

        default:
          return 'マキナ：なんだか不思議な力が働いて、うまく話せないよ…。';
      }
    } on SocketException {
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
    return await _callGeminiAPI(
        "マキナとして、${quest.name}の結果が${success ? '成功' : '失敗'}したことを報告して。");
  }

  // 会話応答
  static Future<Map<String, dynamic>> generateResponse(
      {required Makina makina,
      required String playerMessage,
      required Quest? lastQuest,
      required bool? lastQuestSuccess}) async {
    String response =
        await _callGeminiAPI("マキナとして次のメッセージに応答して：$playerMessage");
    return {
      'response': response,
      'intimacyChange': 1.0,
      'braveChange': 0.0,
      'dependentChange': 0.0,
    };
  }
}
