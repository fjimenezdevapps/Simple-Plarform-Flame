import 'dart:async';

import 'package:flame/components.dart';
import 'package:platform_game/game/simple_platform.dart';

enum HeartState {
  available,
  unavailable,
}

class HeartHealthComponent extends SpriteAnimationGroupComponent<HeartState>
    with HasGameReference<SimplePlatformer> {
  final int heartNumber;

  HeartHealthComponent({
    required this.heartNumber,
    required super.position,
    required super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.priority,
  });

  final double stepTime = 0.25;
  late final SpriteAnimation lostHealthAnimation;
  late final SpriteAnimation availableAnimation;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Cargar el sprite para el estado disponible (imagen fija)
    availableAnimation = SpriteAnimation.fromFrameData(
        game.images.fromCache('HearTile/Red Heart (32x32 ).png'),
        SpriteAnimationData.sequenced(
            amount: 1,
            stepTime: double.infinity,
            textureSize: Vector2.all(32)));

    // Cargar la animación para el estado no disponible
    lostHealthAnimation = SpriteAnimation.fromFrameData(
      game.images.fromCache('HearTile/32x32 spritesheet.png'),
      SpriteAnimationData.sequenced(
        amount: 3,
        stepTime: stepTime,
        textureSize: Vector2.all(32),
      ),
    );

    animations = {
      HeartState.available: availableAnimation,
      HeartState.unavailable: lostHealthAnimation,
    };

    current = HeartState.available;
  }

  @override
  void update(double dt) async {
    if (game.health < heartNumber) {
      if (current != HeartState.unavailable) {
        current = HeartState.unavailable;
        await animationTicker?.completed;
      }
    } else {
      current = HeartState.available;
    }
    super.update(dt);
  }
}
