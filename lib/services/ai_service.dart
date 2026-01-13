import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/makina.dart';

class AIService {
  // TODO: 実際のAPIキーに置き換えてください
  // 本番環境では環境変数から読み込むべきです
  static const String apiKey = '';
  static const String apiUrl = 'https://api.anthropic.com/v1/messages';
  
  // クエスト報告時の会話生成
  static Future<String> generateQuestReport({
    required Makina makina,
    required Quest quest,
    required bool success,
  }) async {
    String prompt = _buildQuestReportPrompt(makina, quest, success);
    return await _callClaudeAPI(prompt);
  }
  
  // プレイヤーの返答に対する応答生成
  static Future<Map<String, dynamic>> generateResponse({
    required Makina makina,
    required String playerMessage,
    required Quest? lastQuest,
    required bool? lastQuestSuccess,
  }) async {
    String prompt = _buildResponsePrompt(
      makina, 
      playerMessage, 
      lastQuest, 
      lastQuestSuccess,
    );
    
    String response = await _callClaudeAPI(prompt);
    
    // 感情分析を行い、親密度と性格の変化を計算
    Map<String, double> changes = _analyzePlayerMessage(playerMessage, makina);
    
    return {
      'response': response,
      'intimacyChange': changes['intimacy']!,
      'braveChange': changes['brave']!,
      'dependentChange': changes['dependent']!,
    };
  }
  
  // Claude APIを呼び出す
  static Future<String> _callClaudeAPI(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 1000,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'];
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return 'ごめんね...今ちょっと調子が悪いみたい...';
      }
    } catch (e) {
      print('Error calling Claude API: $e');
      return 'ごめんね...うまく話せないみたい...';
    }
  }
  
  // クエスト報告用のプロンプト構築
  static String _buildQuestReportPrompt(
    Makina makina, 
    Quest quest, 
    bool success,
  ) {
    String personalityDesc = _getPersonalityDescription(makina);
    String toneDesc = _getToneDescription(makina);
    String memoryContext = _getMemoryContext(makina);
    
    return '''
あなたは「マキナ」という冒険者AIです。以下の設定で、クエストから帰還した報告をしてください。

【マキナの現在の状態】
- レベル: ${makina.level}
- 親密度: ${makina.intimacy.toStringAsFixed(1)}/100
- 性格: $personalityDesc

【口調・態度】
$toneDesc

【直近の記憶】
$memoryContext

【今回のクエスト】
- クエスト名: ${quest.name}
- 内容: ${quest.description}
- 結果: ${success ? '成功' : '失敗'}

【指示】
1. クエストの結果を報告してください
2. ${success ? '成功した喜びや、どのように戦ったか' : '失敗した悔しさや、何が足りなかったか'}を表現してください
3. 140文字以内で、あなたの性格と親密度に合った口調で話してください
4. プレイヤー（師匠/パートナー）への感謝や期待も込めてください

報告のみを生成してください（説明や前置きは不要です）。
''';
  }
  
  // プレイヤーへの応答用プロンプト構築
  static String _buildResponsePrompt(
    Makina makina,
    String playerMessage,
    Quest? lastQuest,
    bool? lastQuestSuccess,
  ) {
    String personalityDesc = _getPersonalityDescription(makina);
    String toneDesc = _getToneDescription(makina);
    String memoryContext = _getMemoryContext(makina);
    
    return '''
あなたは「マキナ」という冒険者AIです。プレイヤーの言葉に応答してください。

【マキナの現在の状態】
- レベル: ${makina.level}
- 親密度: ${makina.intimacy.toStringAsFixed(1)}/100
- 性格: $personalityDesc

【口調・態度】
$toneDesc

【直近の記憶】
$memoryContext

【現在の状況】
${lastQuest != null ? '「${lastQuest.name}」から帰還したばかり。結果は${lastQuestSuccess! ? '成功' : '失敗'}。' : '待機中。'}

【プレイヤーからの言葉】
「$playerMessage」

【指示】
1. プレイヤーの言葉に対して、あなたの性格と親密度に合った反応をしてください
2. 140文字以内で応答してください
3. 感情を込めて、自然な会話を心がけてください

応答のみを生成してください（説明や前置きは不要です）。
''';
  }
  
  // 性格の説明文を生成
  static String _getPersonalityDescription(Makina makina) {
    String braveDesc = makina.brave < -30 
        ? '勇敢で攻撃的' 
        : makina.brave > 30 
            ? '慎重で防御的' 
            : 'バランス型';
    
    String dependentDesc = makina.dependent < -30 
        ? '甘えん坊で頼りがち' 
        : makina.dependent > 30 
            ? '自立していて対等' 
            : '適度に頼る';
    
    return '$braveDesc、$dependentDesc';
  }
  
  // 口調の説明文を生成
  static String _getToneDescription(Makina makina) {
    if (makina.intimacy >= 80) {
      return makina.dependent < -30 
          ? '「師匠〜！」「ねえねえ！」など、とても甘えた口調。語尾は「〜だよ！」「〜なの！」'
          : '親しみを込めた対等な口調。語尾は「〜ね」「〜よ」';
    } else if (makina.intimacy >= 50) {
      return '普通の友好的な口調。語尾は「〜です」「〜ますよ」';
    } else if (makina.intimacy >= 20) {
      return 'やや距離のある丁寧な口調。語尾は「〜です」「〜ます」';
    } else {
      return '冷たく素っ気ない口調。時々嫌味や皮肉も。語尾は「...」「〜だね」';
    }
  }
  
  // 記憶のコンテキストを生成
  static String _getMemoryContext(Makina makina) {
    if (makina.recentMemories.isEmpty) {
      return 'まだ会話の記憶はありません。';
    }
    
    String context = '';
    for (var memory in makina.recentMemories) {
      context += 'プレイヤー: ${memory.playerMessage}\n';
      context += 'マキナ: ${memory.makinaResponse}\n\n';
    }
    return context;
  }
  
  // プレイヤーのメッセージを分析して変化量を計算
  static Map<String, double> _analyzePlayerMessage(
    String message, 
    Makina makina,
  ) {
    double intimacyChange = 0.0;
    double braveChange = 0.0;
    double dependentChange = 0.0;
    
    // 簡易的な感情分析（実際はより高度な分析が必要）
    message = message.toLowerCase();
    
    // 褒め言葉 → 親密度アップ
    if (message.contains('すごい') || 
        message.contains('えらい') ||
        message.contains('よくやった') ||
        message.contains('頑張った')) {
      intimacyChange += 3.0;
      dependentChange -= 2.0; // やや甘えん坊に
    }
    
    // 慰め → 親密度アップ
    if (message.contains('大丈夫') || 
        message.contains('次は') ||
        message.contains('ドンマイ')) {
      intimacyChange += 2.0;
      dependentChange -= 1.0;
    }
    
    // 厳しい言葉 → 親密度ダウン、自立度アップ
    if (message.contains('ダメ') || 
        message.contains('情けない') ||
        message.contains('もっと')) {
      intimacyChange -= 2.0;
      dependentChange += 2.0; // より自立的に
    }
    
    // 戦略的なアドバイス → 賢さアップ、慎重に
    if (message.contains('気をつけ') || 
        message.contains('作戦') ||
        message.contains('考え')) {
      braveChange += 2.0; // より慎重に
    }
    
    // 激励 → 勇敢に
    if (message.contains('頑張れ') || 
        message.contains('いけ') ||
        message.contains('やっちゃえ')) {
      braveChange -= 2.0; // より勇敢に
    }
    
    return {
      'intimacy': intimacyChange,
      'brave': braveChange,
      'dependent': dependentChange,
    };
  }
}