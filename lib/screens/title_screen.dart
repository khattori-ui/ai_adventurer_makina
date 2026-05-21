import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../data/story_data.dart';
import 'story_screen.dart';
import 'home_screen.dart';

class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _sparkleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade400,
              Colors.deepPurple.shade800,
              Colors.indigo.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Consumer<GameProvider>(
              builder: (context, provider, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // タイトルロゴ
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 300,
                                height: 150,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Text(
                                    'AI冒険者マキナ',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 60),

                    // スタートボタンエリア（読み込み中はインジケーターを表示）
                    if (provider.isLoading)
                      const Column(
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text("データを読み込んでいます...",
                              style: TextStyle(color: Colors.white70)),
                        ],
                      )
                    else
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: ElevatedButton(
                              onPressed: () => _handleStart(context, provider),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.deepPurple,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 60,
                                  vertical: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 10,
                              ),
                              child: const Text(
                                'スタート',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    const Spacer(flex: 1),

                    // キラキラエフェクト
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildSparkle(0.0),
                              const SizedBox(width: 20),
                              _buildSparkle(0.3),
                              const SizedBox(width: 20),
                              _buildSparkle(0.6),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // バージョン表記
                    const Text(
                      'Version 1.0',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _handleStart(BuildContext context, GameProvider provider) {
    // プロローグを見ていない場合はプロローグへ
    if (!provider.hasSeenPrologue) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StoryScreen(
            scenes: StoryData.getPrologueScenes(),
            canSkip: true,
            onComplete: () async {
              await provider.markPrologueSeen();
              if (context.mounted) {
                // プロローグ後はチュートリアルへ
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StoryScreen(
                      scenes: StoryData.getTutorialScenes(),
                      canSkip: false,
                      onComplete: () async {
                        await provider.markTutorialSeen();
                        if (context.mounted) {
                          // チュートリアル後はホームへ
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomeScreen(),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              }
            },
          ),
        ),
      );
    } else if (!provider.makina.hasSeenTutorial) {
      // プロローグ済みだがチュートリアル未完了の場合はチュートリアルへ
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StoryScreen(
            scenes: StoryData.getTutorialScenes(),
            canSkip: false,
            onComplete: () async {
              await provider.markTutorialSeen();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                  ),
                );
              }
            },
          ),
        ),
      );
    } else {
      // すでに見ている場合は直接ホームへ
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    }
  }

  Widget _buildSparkle(double phaseOffset) {
    return AnimatedBuilder(
      animation: _sparkleController,
      builder: (context, child) {
        final value =
            ((_sparkleController.value + phaseOffset) % 1.0);
        final opacity = (value < 0.5 ? value * 2 : (1.0 - value) * 2)
            .clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      child: Icon(
        Icons.star,
        color: Colors.yellow.shade300,
        size: 30,
      ),
    );
  }
}
