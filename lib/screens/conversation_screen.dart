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

  @override
  void initState() {
    super.initState();
    
    // 初期メッセージを追加
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
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
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
      alignment: message.isPlayer ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isPlayer 
              ? Colors.deepPurple 
              : Colors.grey.shade200,
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
    if (_isProcessing || _messages.isEmpty) {
      return const SizedBox.shrink();
    }

    // 最後のメッセージがマキナからの場合のみ表示
    if (_messages.last.isPlayer) {
      return const SizedBox.shrink();
    }

    final provider = Provider.of<GameProvider>(context, listen: false);
    final makina = provider.makina;

    List<String> suggestions = [];
    
    // 親密度に応じた提案
    if (makina.intimacy >= 70) {
      suggestions = ['よく頑張ったね！', 'すごいよ！', '大丈夫？'];
    } else if (makina.intimacy >= 40) {
      suggestions = ['よくやった', '次も頑張って', 'お疲れ様'];
    } else {
      suggestions = ['報告ご苦労', 'そうか', '次はもっと頑張れ'];
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions.map((text) {
          return OutlinedButton(
            onPressed: () => _sendMessage(text),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(text),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: const Offset(0, -1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'メッセージを入力...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              enabled: !_isProcessing,
              onSubmitted: (_) => _sendMessage(_messageController.text),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isProcessing 
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
            iconSize: 28,
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isProcessing) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isPlayer: true));
      _messageController.clear();
      _isProcessing = true;
    });

    final provider = Provider.of<GameProvider>(context, listen: false);
    
    try {
      await provider.respondToPlayer(text);
      
      if (provider.currentMessage != null) {
        setState(() {
          _messages.add(ChatMessage(
            text: provider.currentMessage!,
            isPlayer: false,
          ));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'エラーが発生しました...',
          isPlayer: false,
        ));
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

  ChatMessage({
    required this.text,
    required this.isPlayer,
  });
}