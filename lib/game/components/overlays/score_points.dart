import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:platform_game/game/simple_platform.dart';

class ScorePoints extends SpriteComponent with HasGameRef<SimplePlatformer> {
  String _score;
  final String colorFontStyle;
  late SpriteSheet _spriteSheet;
  
  ScorePoints({
    required this.colorFontStyle,
    required String score,
    super.position,
    super.size,
    super.anchor,
  }) : _score = score;

  String get score => _score;
  set score(String value) {
    if (_score != value) {
      _score = value;
      _updateSprite();
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    _spriteSheet = SpriteSheet(
      image: game.images.fromCache('Menu/Text/Numbers ($colorFontStyle) (8x10).png'),
      srcSize: Vector2(8, 10),
    );
    
    _updateSprite();
  }

  void _updateSprite() {
    try {
      sprite = _spriteSheet.getSpriteById(int.parse(_score));
    } catch (e) {
      // Fallback to 0 if parsing fails
      sprite = _spriteSheet.getSpriteById(0);
    }
  }
}
