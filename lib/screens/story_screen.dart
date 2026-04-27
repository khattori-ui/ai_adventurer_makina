import 'package:flutter/material.dart';
import '../data/story_data.dart';

class StoryScreen extends StatefulWidget {
  final List<StoryScene> scenes;
  final VoidCallback onComplete;
  final bool canSkip;

  const StoryScreen({
    super.key,
    required this.scenes,
    required this.onComplete,
    this.canSkip = true,
  });

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen>
    with SingleTickerProviderStateMixin {
  int _currentSceneIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _nextScene() {
    if (_currentSceneIndex < widget.scenes.length - 1) {
      setState(() {
        _fadeController.reset();
        _currentSceneIndex++;
        _fadeController.forward();
      });
    } else {
      widget.onComplete();
    }
  }

  void _skipStory() {
    if (widget.canSkip) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scene = widget.scenes[_currentSceneIndex];

    return Scaffold(
      body: GestureDetector(
        onTap: _nextScene,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black,
                Colors.grey.shade900,
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // メインコンテンツ
                Center(
                  child: Column(
                    children: [
                      const Spacer(flex: 1),

                      // キャラクター画像
                      if (scene.characterImage != null)
                        Expanded(
                          flex: 4,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Image.asset(
                              scene.characterImage!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        )
                      else
                        const Spacer(flex: 4),

                      const Spacer(flex: 1),

                      // テキストボックス
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 話者名
                              if (scene.characterName != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Text(
                                    scene.characterName!,
                                    style: const TextStyle(
                                      color: Colors.amber,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                              // テキスト
                              Text(
                                scene.text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),

                              const SizedBox(height: 10),

                              // 進行インジケーター
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_currentSceneIndex + 1} / ${widget.scenes.length}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.touch_app,
                                        color: Colors.white54,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        _currentSceneIndex <
                                                widget.scenes.length - 1
                                            ? 'タップして次へ'
                                            : 'タップして終了',
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // スキップボタン
                if (widget.canSkip)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: TextButton(
                      onPressed: _skipStory,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      child: const Text(
                        'スキップ',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
