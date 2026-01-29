import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({Key? key}) : super(key: key);

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isProcessing = false;
  int _characterCount = 0;
  static const int _maxCharacters = 500;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {
        _characterCount = _messageController.text.length;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<GameProvider>(context, listen: false);
      if (provider.currentMessage != null) {
        setState(() {
          _messages.add(ChatMessage(
            text: provider.currentMessage!,
            isPlayer: false,
          ));
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('マキナとの会話'),
        backgroundColor: Colors.deepPurple,
        // 👈 右上に残り回数を表示！
        actions: [
          Consumer<GameProvider>(
            builder: (context, provider, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Chip(
                    label: Text('あと ${provider.remainingConversations}回'),
                    backgroundColor: Colors.white24,
                    labelStyle:
                        const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildSuggestionButtons(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment:
          message.isPlayer ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isPlayer ? Colors.deepPurple : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isPlayer ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionButtons() {
    if (_isProcessing || _messages.isEmpty || _messages.last.isPlayer) {
      return const SizedBox.shrink();
    }
    final provider = Provider.of<GameProvider>(context, listen: false);
    final makina = provider.makina;
    List<String> suggestions = makina.intimacy >= 70
        ? ['よく頑張ったね！', 'すごいよ！', '大丈夫？']
        : (makina.intimacy >= 40
            ? ['よくやった', '次も頑張って', 'お疲れ様']
            : ['報告ご苦労', 'そうか', '次はもっと頑張れ']);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions
            .map((text) => OutlinedButton(
                  onPressed: () => _sendMessage(text),
                  child: Text(text),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildInputArea() {
    final provider = Provider.of<GameProvider>(context);
    final isOverLimit = _characterCount > _maxCharacters;
    // 👈 会話制限に達しているかチェック
    final isStaminaEmpty = provider.remainingConversations <= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_characterCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$_characterCount / $_maxCharacters',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOverLimit ? Colors.red : Colors.grey,
                      fontWeight:
                          isOverLimit ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText:
                        isStaminaEmpty ? '今日はもう疲れちゃったみたい...' : 'メッセージを入力...',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isOverLimit ? Colors.red : Colors.grey,
                      ),
                    ),
                    errorText: isOverLimit
                        ? '文字数制限を超えています'
                        : (isStaminaEmpty ? '1日の制限に達しました' : null),
                  ),
                  enabled: !_isProcessing && !isStaminaEmpty, // 👈 制限時は入力不可
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: (_isProcessing || isOverLimit || isStaminaEmpty)
                    ? null
                    : () => _sendMessage(_messageController.text),
                icon: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                color: Colors.deepPurple,
                disabledColor: Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isProcessing) return;
    if (text.length > _maxCharacters) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('メッセージは500文字以内にしてください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _messages.add(ChatMessage(text: text, isPlayer: true));
      _messageController.clear();
      _characterCount = 0;
      _isProcessing = true;
    });
    final provider = Provider.of<GameProvider>(context, listen: false);
    try {
      await provider.respondToPlayer(text);
      if (provider.currentMessage != null) {
        setState(() {
          _messages.add(
              ChatMessage(text: provider.currentMessage!, isPlayer: false));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: 'エラーが発生しました...', isPlayer: false));
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
}

class ChatMessage {
  final String text;
  final bool isPlayer;
  ChatMessage({required this.text, required this.isPlayer});
}
