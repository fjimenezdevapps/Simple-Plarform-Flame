import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:platform_game/game/simple_platform.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();

  SimplePlatformer game = SimplePlatformer();
  runApp(
    GameWidget(game: kDebugMode ? SimplePlatformer() : game),
  );
}

class MainApp extends StatelessWidget {
  final SimplePlatformer game;

  const MainApp({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        body: GameWidget(game: game),
      ),
    );
  }
}
