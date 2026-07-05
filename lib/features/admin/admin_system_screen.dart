import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/game_provider.dart';
import '../../core/ai/ai_service.dart';

class AdminSystemScreen extends StatelessWidget {
  const AdminSystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(builder: (context, provider, _) {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '(unknown)';
      final current = provider.aiProvider;

      return Scaffold(
        appBar: AppBar(
          title: const Text('システム管理（管理者専用）'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('管理者UID',
                      style:
                          TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 4),
                  SelectableText(uid,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  const Text(
                    'このUIDを Firestore の `admins/{uid}` に登録すると管理者になります。',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('使用するAI（全ユーザー共通）',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    const Text('現在の設定',
                        style:
                            TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 6),
                    SegmentedButton<AiProvider>(
                      segments: const [
                        ButtonSegment(
                          value: AiProvider.gemini,
                          label: Text('Gemini'),
                        ),
                        ButtonSegment(
                          value: AiProvider.haiku,
                          label: Text('Haiku'),
                        ),
                      ],
                      selected: {current},
                      onSelectionChanged: (s) async {
                        final v = s.first;
                        await provider.setSystemAiProvider(v);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('AI設定を更新しました（全ユーザーに反映）'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      current == AiProvider.gemini
                          ? 'Gemini（コスト重視）'
                          : 'Claude Haiku（品質重視）',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const Divider(height: 24),
                    const Text(
                      '注意: 切り替えは「次のAI呼び出し」から反映されます。',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

