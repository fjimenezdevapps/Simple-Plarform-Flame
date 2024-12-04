import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:platform_game/game/components/utils/collision_block.dart';
import 'package:platform_game/game/simple_platform.dart';

enum FallingPlatformState { available, unavailable }

class FallingPlatform extends SpriteAnimationGroupComponent
    with HasGameRef<SimplePlatformer>, CollisionCallbacks {
  final CollisionBlock collisionPlatform;
  FallingPlatform(
      {super.position, super.size, required this.collisionPlatform});

  late final SpriteAnimation onAnimation;
  late final SpriteAnimation offAnimation;
  static const double stepTime = 0.03;
  late RectangleHitbox _hitbox;
  double _fallSpeed = 0;
  static const double _gravity = 1000;

  @override
  FutureOr<void> onLoad() async {
    //debugMode = true;
    await _loadAllAnimations();
    _createHitbox();
    return super.onLoad();
  }

  Future<void> _loadAllAnimations() async {
    onAnimation = _spriteAnimation('On', 4);
    offAnimation = _spriteAnimation('Off', 1);

    animations = {
      FallingPlatformState.available: onAnimation,
      FallingPlatformState.unavailable: offAnimation,
    };

    current = FallingPlatformState.available;
  }

  void _createHitbox() {
    _hitbox = RectangleHitbox();
    add(_hitbox);
  }

  SpriteAnimation _spriteAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Traps/Falling Platforms/$state (32x10).png'),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: Vector2(32, 10),
      ),
    );
  }

  void collidedWithPlayer() {
    current = FallingPlatformState.unavailable;
    _fallSpeed = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (current == FallingPlatformState.unavailable) {
      _fallSpeed += _gravity * dt;
      position.y += _fallSpeed * dt;

      if (position.y > game.size.y) {
        _hitbox.removeFromParent();
        removeFromParent();
      }
    }
  }
}
