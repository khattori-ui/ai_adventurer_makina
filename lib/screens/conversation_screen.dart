import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/firestore_service.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isProcessing = false;

  // タイピング演出用の状態
  String _typingText = '';
  String _fullText = '';
  bool _isTyping = false;
  int _currentCharIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<GameProvider>(context, listen: false);
      if (provider.currentMessage != null) {
        setState(() {
          _messages.add(
              ChatMessage(text: provider.currentMessage!, isPlayer: false));
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- タイピング演出ロジック ---
  void _startTypingAnimation(String text) {
    setState(() {
      _fullText = text;
      _typingText = '';
      _currentCharIndex = 0;
      _isTyping = true;
    });
    _typeNextCharacter();
  }

  void _typeNextCharacter() {
    if (!_isTyping || !mounted) return;
    if (_currentCharIndex < _fullText.length) {
      setState(() {
        _typingText = _fullText.substring(0, _currentCharIndex + 1);
        _currentCharIndex++;
      });
      Future.delayed(
          const Duration(milliseconds: 40), () => _typeNextCharacter());
      _scrollToBottom();
    } else {
      setState(() => _isTyping = false);
    }
  }

  void _skipTyping() {
    if (_isTyping) {
      setState(() {
        _typingText = _fullText;
        _currentCharIndex = _fullText.length;
        _isTyping = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);
    final m = provider.makina;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    String imagePath = 'assets/images/makina.png';
    if (m.currentOutfitId != null && m.currentOutfitId != 'default') {
      imagePath =
          'assets/images/costume_${m.currentOutfitId!.replaceAll('costume_', '')}.png';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('マキナとの会話'),
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            provider.clearMessage();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: Stack(
          children: [
            // 1. 背景としてのマキナ画像
            Positioned(
              bottom: 80,
              right: -20,
              child: Opacity(
                opacity: 0.5,
                child: Image.asset(
                  imagePath,
                  height: MediaQuery.of(context).size.height * 0.6,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.person, size: 200, color: Colors.grey),
                ),
              ),
            ),

            // 2. メインレイアウト
            Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _skipTyping,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isLastAI =
                            (index == _messages.length - 1 && !message.isPlayer);

                        if (isLastAI && _isTyping) {
                          return _buildMessageBubble(_typingText, false,
                              canReport: false);
                        }
                        return _buildMessageBubble(message.text, message.isPlayer,
                            canReport: !message.isPlayer);
                      },
                    ),
                  ),
                ),
                // キーボード表示中は縦幅を確保するためサジェストを隠す
                if (!keyboardVisible) _buildSuggestionButtons(),
                _buildInputArea(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isPlayer,
      {bool canReport = false}) {
    final bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isPlayer
            ? Colors.deepPurple.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Text(
        text,
        style: TextStyle(
            color: isPlayer ? Colors.white : Colors.black87, fontSize: 16),
      ),
    );

    if (isPlayer) {
      return Align(alignment: Alignment.centerRight, child: bubble);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: bubble),
          if (canReport)
            Tooltip(
              message: '不適切な発言を報告',
              child: IconButton(
                icon: const Icon(Icons.flag_outlined, size: 18),
                color: Colors.grey.shade400,
                splashRadius: 18,
                onPressed: () => _showReportDialog(text),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showReportDialog(String reportedText) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('発言を報告'),
        content: const Text('この発言を不適切として報告しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('報告する'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await FirestoreService.saveReport(reportedText);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('報告を送信しました。ご協力ありがとうございます'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('通報エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('送信に失敗しました'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // ★ 復活させたサジェストボタンのコード
  Widget _buildSuggestionButtons() {
    // タイピング中や通信中はボタンを出さない
    if (_isProcessing ||
        _messages.isEmpty ||
        _messages.last.isPlayer ||
        _isTyping) {
      return const SizedBox.shrink();
    }

    final provider = Provider.of<GameProvider>(context, listen: false);
    final makina = provider.makina;

    // 親密度によって選択肢を変える
    List<String> suggestions = makina.intimacy >= 70
        ? ['よく頑張ったね', 'すごいよ', '大丈夫？']
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
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(text),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                  hintText: 'メッセージを入力...', border: OutlineInputBorder()),
              enabled: !_isProcessing && !_isTyping,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: (_isProcessing || _isTyping)
                ? null
                : () => _sendMessage(_messageController.text),
            icon: _isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send),
            color: Colors.deepPurple,
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(text: text, isPlayer: true));
      _isProcessing = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final provider = Provider.of<GameProvider>(context, listen: false);
      await provider.respondToPlayer(text);

      if (mounted && provider.currentMessage != null) {
        setState(() {
          _messages.add(
              ChatMessage(text: provider.currentMessage!, isPlayer: false));
        });
        _startTypingAnimation(provider.currentMessage!);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}

class ChatMessage {
  final String text;
  final bool isPlayer;
  ChatMessage({required this.text, required this.isPlayer});
}
