import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../shared/models/makina.dart';

enum AiProvider { gemini, haiku }

class AIService {
  static String get _geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get _anthropicApiKey => dotenv.env['ANTHROPIC_API_KEY'] ?? '';
  static String get _geminiModel => dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.0-flash';
  static const String _haikuModel = 'claude-3-5-haiku-20241022';
  static const String _anthropicUrl = 'https://api.anthropic.com/v1/messages';

  static bool _isPlaceholder(String apiKey) =>
      apiKey.isEmpty || apiKey.contains('貼り付けてください');

  static String _sanitizeAiText(String raw) {
    var text = raw.trim();
    text = text.replaceAll('\r\n', '\n');
    text = text.replaceAll(RegExp(r'[ \t]+\n'), '\n');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    text = text.replaceAll(RegExp(r'^[\u200B-\u200D\uFEFF]+'), '');
    text = text.replaceAll(RegExp(r'（\d+文字）'), '');
    text = text.replaceAll(RegExp(r'\(\d+文字\)'), '');

    // 返答末尾に混ざる不完全な断片を除去
    final lines = text
        .split('\n')
        .map((line) => line.trimRight())
        .where((line) => line.isNotEmpty)
        .toList();
    while (lines.isNotEmpty) {
      final last = lines.last;
      final looksBroken = last.length <= 8 &&
          (last.endsWith('マキ') ||
              last.endsWith('ですけ') ||
              last.endsWith('ますね') ||
              !RegExp(r'[。！？]$').hasMatch(last));
      if (!looksBroken) break;
      lines.removeLast();
    }
    if (lines.isEmpty) return raw.trim();
    return lines.join('\n').trim();
  }

  static String _friendlyErrorMessage(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('socketexception')) {
      return 'マキナ：電波の精霊さんがいないみたい。場所を変えて、もう一度あたしを呼んでみて！';
    }
    if (s.contains('timeout') || s.contains('timed out')) {
      return 'マキナ：ちょっと考え込みすぎちゃった。もう一回、ゆっくり話しかけてみて！';
    }
    if (s.contains('api key') || s.contains('permission') || s.contains('unauthorized')) {
      return 'マキナ：師匠、なんだか「魔法のつながり」が悪いみたい…。ギルドの運営さんが直してくれるのを待ってみよう！';
    }
    if (s.contains('429') || s.contains('quota') || s.contains('rate')) {
      return 'マキナ：ごめん、魔力を使いすぎちゃって疲れちゃったみたい…。少し休ませてくれたら、また元気になるから待っててね！';
    }
    if (s.contains('404') || s.contains('not_found') || s.contains('model')) {
      return 'マキナ：いま使える魔法の型を調整中みたい…。少ししたらもう一度話しかけてみて！';
    }
    return 'マキナ：うう、頭の中がこんがらがっちゃった…。少し時間をおいてから、また話しかけてね。';
  }

  static Future<String> _callGeminiAPI(String prompt) async {
    final apiKey = _geminiApiKey;
    if (_isPlaceholder(apiKey)) {
      return '（シミュレーションモード）師匠！今は修行中だから決まったお返事しかできないけど、クエストの結果はバッチリ記録しておくね！';
    }

    try {
      final model = GenerativeModel(
        model: _geminiModel,
        apiKey: apiKey,
        generationConfig:
            GenerationConfig(maxOutputTokens: 220, temperature: 0.7),
      );
      final response = await model
          .generateContent([Content.text(prompt)])
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('通信が途切れちゃった'),
          );
      final text = response.text;
      if (text != null && text.trim().isNotEmpty) {
        return _sanitizeAiText(text);
      }
      return 'マキナ：（うまく言葉が出てこない…）';
    } on SocketException {
      return 'マキナ：電波の精霊さんがいないみたい。場所を変えて、もう一度あたしを呼んでみて！';
    } on TimeoutException {
      return 'マキナ：ちょっと考え込みすぎちゃった。もう一回、ゆっくり話しかけてみて！';
    } catch (e) {
      if (kDebugMode) debugPrint('Gemini API error: $e');
      return _friendlyErrorMessage(e);
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
            final text =
                (content[0]['text'] as String?) ?? 'マキナ：（うまく言葉が出てこない…）';
            return _sanitizeAiText(text);
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
      if (kDebugMode) debugPrint('Haiku API error: $e');
      return _friendlyErrorMessage(e);
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
        """
あなたはRPG世界の少女「マキナ」です。明るく素直で、プレイヤーを「マスター」と呼びます。
次の条件で、クエスト報告を自然な日本語で1〜3文で返してください。
- 口調は親しみやすく、前向き
- 不自然な造語や途中で切れた文を出さない
- 120文字以内

クエスト名: ${quest.name}
結果: ${success ? '成功' : '失敗'}
""",
        provider);
  }

  // 会話応答
  static Future<Map<String, dynamic>> generateResponse(
      {required Makina makina,
      required String playerMessage,
      required Quest? lastQuest,
      required bool? lastQuestSuccess,
      AiProvider provider = AiProvider.gemini}) async {
    final lastQuestText = lastQuest == null
        ? 'なし'
        : '${lastQuest.name}（${lastQuestSuccess == true ? '成功' : '失敗'}）';
    final prompt = """
あなたはRPG世界の少女「マキナ」です。明るく素直で、プレイヤーを「マスター」と呼びます。
以下のルールで、プレイヤーの発言に自然な日本語で返答してください。
- 1〜3文、120文字以内
- 丁寧すぎず親しみやすい口調
- 途中で切れた文・不自然な語尾・文字化け風の文を出さない
- プレイヤー発言に短く具体的に反応する

参考情報:
- 親密度: ${makina.intimacy.toStringAsFixed(1)}
- 直近クエスト: $lastQuestText

プレイヤー発言: $playerMessage
""";
    String response = await _callAI(prompt, provider);
    return {
      'response': response,
      'intimacyChange': 1.0,
      'braveChange': 0.0,
      'dependentChange': 0.0,
    };
  }
}
