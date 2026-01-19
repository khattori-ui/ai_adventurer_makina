import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 追加
import 'providers/game_provider.dart';
import 'screens/title_screen.dart';

Future<void> main() async {
  // Flutterの初期化を確実に行う
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // .envファイルを読み込む (画像 image_07cc68.png で設定済みのアセット)
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Warning: .env file not found. Simulation mode will be used.");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameProvider(),
      child: MaterialApp(
        title: 'AI冒険者マキナ',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
          ),
        ),
        home: const TitleScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
