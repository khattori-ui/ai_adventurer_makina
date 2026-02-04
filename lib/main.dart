import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 👈 これが必要
import 'firebase_options.dart';
import 'providers/game_provider.dart';
import 'screens/title_screen.dart';

void main() async {
  // 1. Flutterの準備
  WidgetsFlutterBinding.ensureInitialized();

  // 2. 【最優先】設定ファイル(.env)を読み込む
  // これをFirebaseやrunAppより先に書かないとエラーになります
  try {
    await dotenv.load(fileName: ".env");
    debugPrint(".envの読み込みに成功しました");
  } catch (e) {
    debugPrint(".envの読み込みに失敗しました: $e");
  }

  // 3. Firebaseの初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 4. 匿名ログイン
  try {
    await FirebaseAuth.instance.signInAnonymously();
  } catch (e) {
    debugPrint("ログインエラー: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Adventurer Makina',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const TitleScreen(),
    );
  }
}
