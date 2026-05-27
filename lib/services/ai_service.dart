import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/makina.dart';

enum AiProvider { gemini, haiku }

class AIService {
  static String get _geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get _anthropicApiKey => dotenv.env['ANTHROPIC_API_KEY'] ?? '';

  static const String _geminiModel = 'gemini-1.5-flash';
  static const String _haikuModel = 'claude-3-5-haiku-20241022';

  static String _geminiUrl(String apiKey) =>
      'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent?key=$apiKey';
  static const String _anthropicUrl = 'https://api.anthropic.com/v1/messages';

  static bool _isPlaceholder(String apiKey) =>
      apiKey.isEmpty || apiKey.contains('貼り付けてください');

  static Future<String> _callGeminiAPI(String prompt) async {
    final apiKey = _geminiApiKey;
    if (_isPlaceholder(apiKey)) {
      return '（シミュレーションモード）師匠！今は修行中だから決まったお返事しかできないけど、クエストの結果はバッチリ記録しておくね！';
    }

    try {
      final response = await http
          .post(
            Uri.parse(_geminiUrl(apiKey)),
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

  static Future<String> _callHaikuAPI(String prompt) async {
    final apiKey = _anthropicApiKey;
    if (_isPlaceholder(apiKey)) {
      return '（シミュレーションモード）師匠！今は修行中だから決まったお返事しかできないけど、クエストの結果はバッチリ記録しておくね！';
    }

    try {
      final response = await http
          .post(
            Uri.parse(_anthropicUrl),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
            },
            body: jsonEncode({
              'model': _haikuModel,
              'max_tokens': 500,
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
          if (content is List &&
              content.isNotEmpty &&
              content[0] is Map &&
              (content[0] as Map).containsKey('text')) {
            return (content[0]['text'] as String?) ?? 'マキナ：（うまく言葉が出てこない…）';
          }
          return 'マキナ：（うまく言葉が出てこない…）';

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

  static Future<String> _callAI(String prompt, AiProvider provider) {
    switch (provider) {
      case AiProvider.gemini:
        return _callGeminiAPI(prompt);
      case AiProvider.haiku:
        return _callHaikuAPI(prompt);
    }
  }

  // クエスト報告
  static Future<String> generateQuestReport(
      {required Makina makina,
      required Quest quest,
      required bool success,
      AiProvider provider = AiProvider.gemini}) async {
    return await _callAI(
        "マキナとして、${quest.name}の結果が${success ? '成功' : '失敗'}したことを報告して。",
        provider);
  }

  // 会話応答
  static Future<Map<String, dynamic>> generateResponse(
      {required Makina makina,
      required String playerMessage,
      required Quest? lastQuest,
      required bool? lastQuestSuccess,
      AiProvider provider = AiProvider.gemini}) async {
    String response =
        await _callAI("マキナとして次のメッセージに応答して：$playerMessage", provider);
    return {
      'response': response,
      'intimacyChange': 1.0,
      'braveChange': 0.0,
      'dependentChange': 0.0,
    };
  }
}
