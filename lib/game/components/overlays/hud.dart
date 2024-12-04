import 'package:flame/components.dart';
import 'package:platform_game/game/components/overlays/score_points.dart';
import 'package:platform_game/game/components/overlays/heart_health_component.dart';
import 'package:platform_game/game/simple_platform.dart';

class Hud extends PositionComponent with HasGameReference<SimplePlatformer> {
  Hud({
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.children,
    super.priority = 5,
  });

  // Lista de componentes de vida
  final List<HeartHealthComponent> heartComponents = [];
  late ScorePoints _numberDozensSprite;
  late ScorePoints _numberUnitsSprite;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initialize score display
    _numberDozensSprite = ScorePoints(
      colorFontStyle: 'White',
      score: '0',
      position: Vector2(game.size.x - 160, 30),
      size: Vector2.all(32),
      anchor: Anchor.center,
    );

    _numberUnitsSprite = ScorePoints(
      colorFontStyle: 'White',
      score: '0',
      position: Vector2(game.size.x - 130, 30),
      size: Vector2.all(32),
      anchor: Anchor.center,
    );

    add(_numberDozensSprite);
    add(_numberUnitsSprite);

    // Add barrel sprite
    final barrelSprite =
        Sprite(game.images.fromCache('Items/Barrel/barrel_28x30.png'));
    add(
      SpriteComponent(
        sprite: barrelSprite,
        position: Vector2(game.size.x - 190, 30),
        size: Vector2.all(32),
        anchor: Anchor.center,
      ),
    );

    // Add health hearts
    for (var i = 1; i <= game.health; i++) {
      final positionX = 40 * i;
      final heart = HeartHealthComponent(
        heartNumber: i,
        position: Vector2(positionX.toDouble() + 50, 10),
        size: Vector2.all(32),
      );
      heartComponents.add(heart);
      add(heart);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update score display
    final score = game.fruitCollected;
    _numberDozensSprite.score = '${(score ~/ 10) % 10}';
    _numberUnitsSprite.score = '${score % 10}';

    // Update hearts
    for (var i = 0; i < heartComponents.length; i++) {
      if (game.health < i + 1 &&
          heartComponents[i].current != HeartState.unavailable) {
        const healLostDuration = Duration(milliseconds: 400);
        Future.delayed(healLostDuration, () => remove(heartComponents[i]));
      } else if (game.health >= i + 1 &&
          heartComponents[i].current != HeartState.available) {
        heartComponents[i].current = HeartState.available;
      }
    }
  }
}
