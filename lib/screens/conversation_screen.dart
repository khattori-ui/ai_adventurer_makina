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
  final FocusNode _inputFocusNode = FocusNode();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<_TypingMessageBubbleState> _typingBubbleKey = GlobalKey();
  bool _isProcessing = false;
  bool _isTyping = false;

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
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTypingFinished() {
    if (!mounted) return;
    setState(() => _isTyping = false);
  }

  void _startTypingAnimation(String text) {
    setState(() => _isTyping = true);
    _scrollToBottom();
  }

  void _skipTyping() {
    _typingBubbleKey.currentState?.skip();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if ((_scrollController.offset - max).abs() > 4) {
        _scrollController.jumpTo(max);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // listen: true だと GameProvider の更新のたびに TextField が再ビルドされキーボードが閉じる
    final provider = Provider.of<GameProvider>(context, listen: false);
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
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.manual,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isLastAI =
                            (index == _messages.length - 1 && !message.isPlayer);

                        if (isLastAI && _isTyping) {
                          return _TypingMessageBubble(
                            key: _typingBubbleKey,
                            fullText: message.text,
                            onScroll: _scrollToBottom,
                            onFinished: _onTypingFinished,
                            bubbleBuilder: (text) => _buildMessageBubble(
                              text,
                              false,
                              canReport: false,
                            ),
                          );
                        }
                        return _buildMessageBubble(message.text, message.isPlayer,
                            canReport: !message.isPlayer);
                      },
                    ),
                  ),
                ),
                // キーボード表示中は見えなくするが高さは維持（消すと TextField が再ビルドされキーボードが閉じる）
                Visibility(
                  visible: !keyboardVisible,
                  maintainState: true,
                  maintainAnimation: true,
                  maintainSize: true,
                  child: _buildSuggestionButtons(),
                ),
                _ConversationInputBar(
                  focusNode: _inputFocusNode,
                  controller: _messageController,
                  isProcessing: _isProcessing,
                  isTyping: _isTyping,
                  onSend: _sendMessage,
                ),
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

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(text: text, isPlayer: true));
      _isProcessing = true;
    });
    _messageController.clear();
    _inputFocusNode.unfocus();
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

/// 親の setState やキーボード表示の影響を受けず入力欄だけを維持する
class _ConversationInputBar extends StatelessWidget {
  final FocusNode focusNode;
  final TextEditingController controller;
  final bool isProcessing;
  final bool isTyping;
  final ValueChanged<String> onSend;

  const _ConversationInputBar({
    required this.focusNode,
    required this.controller,
    required this.isProcessing,
    required this.isTyping,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              focusNode: focusNode,
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'メッセージを入力...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: (isProcessing || isTyping)
                ? null
                : () => onSend(controller.text),
            icon: isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            color: Colors.deepPurple,
          ),
        ],
      ),
    );
  }
}

/// タイピング演出だけを再ビルドし、親の TextField に影響させない
class _TypingMessageBubble extends StatefulWidget {
  final String fullText;
  final VoidCallback onScroll;
  final VoidCallback onFinished;
  final Widget Function(String text) bubbleBuilder;

  const _TypingMessageBubble({
    super.key,
    required this.fullText,
    required this.onScroll,
    required this.onFinished,
    required this.bubbleBuilder,
  });

  @override
  State<_TypingMessageBubble> createState() => _TypingMessageBubbleState();
}

class _TypingMessageBubbleState extends State<_TypingMessageBubble> {
  String _typingText = '';
  int _currentCharIndex = 0;
  bool _isTyping = true;

  @override
  void initState() {
    super.initState();
    _typeNextCharacter();
  }

  void _typeNextCharacter() {
    if (!_isTyping || !mounted) return;
    if (_currentCharIndex < widget.fullText.length) {
      setState(() {
        _typingText =
            widget.fullText.substring(0, _currentCharIndex + 1);
        _currentCharIndex++;
      });
      // 毎文字スクロールすると Android でキーボードが閉じることがある
      if (_currentCharIndex == 1 || _currentCharIndex == widget.fullText.length) {
        widget.onScroll();
      }
      Future.delayed(
          const Duration(milliseconds: 40), () => _typeNextCharacter());
    } else {
      setState(() => _isTyping = false);
      widget.onFinished();
    }
  }

  void skip() {
    if (!_isTyping) return;
    setState(() {
      _typingText = widget.fullText;
      _currentCharIndex = widget.fullText.length;
      _isTyping = false;
    });
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: skip,
      child: widget.bubbleBuilder(_typingText),
    );
  }
}
