import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';

import 'package:flutter/services.dart';

import 'package:platform_game/game/components/core/checkpoint.dart';
import 'package:platform_game/game/components/enemies/chicken.dart';
import 'package:platform_game/game/components/utils/collision_block.dart';
import 'package:platform_game/game/components/utils/custom_hitbox.dart';
import 'package:platform_game/game/components/traps/falling_platform.dart';
import 'package:platform_game/game/components/items/fruit.dart';
import 'package:platform_game/game/components/traps/saw.dart';
import 'package:platform_game/game/components/utils/utils.dart';

import 'package:platform_game/game/simple_platform.dart';

enum PlayerState {
  idle,
  running,
  jumping,
  doubleJumping,
  falling,
  hit,
  appearing,
  disappearing,
  wallSlide
}

class Player extends SpriteAnimationGroupComponent
    with HasGameRef<SimplePlatformer>, KeyboardHandler, CollisionCallbacks {
  String character;
  Player({
    super.position,
    this.character = 'Ninja Frog',
  });

  final double stepTime = 0.05;
  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runningAnimation;
  late final SpriteAnimation jumpingAnimation;
  late final SpriteAnimation doubleJumpingAnimation;
  late final SpriteAnimation fallingAnimation;
  late final SpriteAnimation hitAnimation;
  late final SpriteAnimation appearingAnimation;
  late final SpriteAnimation disappearingAnimation;
  late final SpriteAnimation wallSlideAnimation;

  final double _gravity = 9.8;
  final double _wallGravity = 6.8;
  final double _wallJumpForce = 200;
  final double _jumpForce = 260;
  final double _terminalVelocity = 300;
  double horizontalMovement = 0;
  double moveSpeed = 100;
  Vector2 startingPosition = Vector2.zero();
  Vector2 velocity = Vector2.zero();
  bool isOnGround = false;
  bool isOnWall = false;
  bool hasJumped = false;
  bool hasDoubleJumped = false;
  bool gotHit = false;
  bool reachedCheckpoint = false;
  bool destroyPlatform = false;
  List<CollisionBlock> collisionBlocks = [];
  CustomHitbox hitbox = CustomHitbox(
    offsetX: 10,
    offsetY: 4,
    width: 14,
    height: 28,
  );
  double fixedDeltaTime = 1 / 60;
  double accumulatedTime = 0;

  @override
  FutureOr<void> onLoad() {
    _loadAllAnimations();
    // debugMode = true;

    startingPosition = Vector2(position.x, position.y);

    add(RectangleHitbox(
      position: Vector2(hitbox.offsetX, hitbox.offsetY),
      size: Vector2(hitbox.width, hitbox.height),
    ));

    return super.onLoad();
  }

  @override
  void update(double dt) {
    accumulatedTime += dt;

    while (accumulatedTime >= fixedDeltaTime) {
      if (!gotHit && !reachedCheckpoint) {
        _updatePlayerState();
        _updatePlayerMovement(fixedDeltaTime);

        _checkHorizontalCollisions();
        _applyGravity(fixedDeltaTime);
        _checkVerticalCollisions();
      }

      accumulatedTime -= fixedDeltaTime;
    }

    super.update(dt);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    horizontalMovement = 0;
    horizontalMovement += (keysPressed.contains(LogicalKeyboardKey.keyA) ||
            keysPressed.contains(LogicalKeyboardKey.arrowLeft))
        ? -1
        : 0;
    horizontalMovement += (keysPressed.contains(LogicalKeyboardKey.keyD) ||
            keysPressed.contains(LogicalKeyboardKey.arrowRight))
        ? 1
        : 0;

    final isJumpPressed = keysPressed.contains(LogicalKeyboardKey.space);

    if (isJumpPressed && !hasJumped) {
      hasJumped = true;
    }

    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (!reachedCheckpoint) {
      if (other is Fruit) other.collidedWithPlayer();
      if (other is Saw) _respawn();
      if (other is Chicken) other.collidedWithPlayer();
      if (other is Checkpoint) _reachedCheckpoint();
      if (other is FallingPlatform) {
        for (final block in collisionBlocks) {
          if (other.collisionPlatform.position == block.position) {
            Future.delayed(
                const Duration(milliseconds: 500),
                () => {
                      other.collidedWithPlayer(),
                      collisionBlocks.remove(block)
                    });
            break;
          }
        }
      }
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  void _loadAllAnimations() {
    idleAnimation = _spriteAnimation('Idle', 11);
    runningAnimation = _spriteAnimation('Run', 12);
    jumpingAnimation = _spriteAnimation('Jump', 1);
    doubleJumpingAnimation = _spriteAnimation('Double Jump', 6)..loop = false;
    fallingAnimation = _spriteAnimation('Fall', 1);
    hitAnimation = _spriteAnimation('Hit', 7)..loop = false;
    appearingAnimation = _specialSpriteAnimation('Appearing', 7);
    disappearingAnimation = _specialSpriteAnimation('Desappearing', 7);
    wallSlideAnimation = _spriteAnimation('Wall Jump', 5);

    // List of all animations
    animations = {
      PlayerState.idle: idleAnimation,
      PlayerState.running: runningAnimation,
      PlayerState.jumping: jumpingAnimation,
      PlayerState.doubleJumping: doubleJumpingAnimation,
      PlayerState.falling: fallingAnimation,
      PlayerState.hit: hitAnimation,
      PlayerState.appearing: appearingAnimation,
      PlayerState.disappearing: disappearingAnimation,
      PlayerState.wallSlide: wallSlideAnimation
    };

    // Set current animation
    current = PlayerState.idle;
  }

  SpriteAnimation _spriteAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Main Characters/$character/$state (32x32).png'),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: Vector2.all(32),
      ),
    );
  }

  SpriteAnimation _specialSpriteAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Main Characters/$state (96x96).png'),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: Vector2.all(96),
        loop: false,
      ),
    );
  }

  void _updatePlayerState() {
    PlayerState playerState = PlayerState.idle;

    if (velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }

    // Check if moving, set running
    if (velocity.x > 0 || velocity.x < 0 && !isOnWall) {
      playerState = PlayerState.running;
    }

    // check if Falling set to falling
    if (velocity.y > 0) playerState = PlayerState.falling;

    // Checks if jumping, set to jumping
    if (velocity.y < 0) playerState = PlayerState.jumping;

    // Checks if has jumping, set to double jumping
    if (velocity.y < 0 && !hasDoubleJumped) {
      playerState = PlayerState.doubleJumping;
    }

    current = playerState;
  }

  void _updatePlayerMovement(double dt) {
    if (hasJumped && isOnGround) {
      _playerJump(dt);
    } else if (hasJumped && !isOnGround && hasDoubleJumped) {
      _playerDoubleJump(dt);
    }

    velocity.x = horizontalMovement * moveSpeed;
    position.x += velocity.x * dt;
  }

  void _playerJump(double dt) {
    if (game.playSounds) FlameAudio.play('jump.wav', volume: game.soundVolume);
    velocity.y = isOnWall ? -_wallJumpForce : -_jumpForce;
    position.y += velocity.y * dt;
    isOnGround = false;
    hasJumped = false;
    hasDoubleJumped = true; // Permite el doble salto después del primer salto
    //game.dust.update(dt);
  }

  void _playerDoubleJump(double dt) {
    if (game.playSounds) FlameAudio.play('jump.wav', volume: game.soundVolume);
    velocity.y = -_jumpForce;
    position.y += velocity.y * dt;

    // Desactiva el doble salto después de ejecutarlo
    hasDoubleJumped = false;
  }

  void _checkHorizontalCollisions() {
    bool collidedWithWall = false;

    for (final block in collisionBlocks) {
      if (!block.isPlatform && checkCollision(this, block)) {
        collidedWithWall = true;

        if (!isOnGround) {
          current = PlayerState.wallSlide;
          isOnWall = true;
          velocity.y = 0; // Detener el movimiento vertical en la pared
        }

        if (velocity.x > 0) {
          velocity.x = 0;
          position.x = block.x - hitbox.offsetX - hitbox.width;
          break;
        }
        if (velocity.x < 0) {
          velocity.x = 0;
          position.x = block.x + block.width + hitbox.width + hitbox.offsetX;
          break;
        }
      }
    }

    // Si no hubo colisión con una pared, dejar de estar en la pared
    if (!collidedWithWall) {
      isOnWall = false;
    }
  }

  void _applyGravity(double dt) {
    velocity.y += isOnWall ? _wallGravity : _gravity;
    velocity.y = velocity.y.clamp(-_jumpForce, _terminalVelocity);
    position.y += velocity.y * dt;
  }

  void _checkVerticalCollisions() {
    for (final block in collisionBlocks) {
      if (block.isPlatform) {
        if (checkCollision(this, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            // Restablece los estados de salto al aterrizar
            hasJumped = false;
            hasDoubleJumped = false;
            isOnWall = false;

            break;
          }
        }
      } else {
        if (checkCollision(this, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            // Restablece los estados de salto al aterrizar
            hasJumped = false;
            hasDoubleJumped = false;
            isOnWall = false;
            break;
          }
          if (velocity.y < 0) {
            velocity.y = 0;
            position.y = block.y + block.height - hitbox.offsetY;
            break;
          }
        }
      }
    }
  }

  void _respawn() async {
    if (game.playSounds) FlameAudio.play('hit.wav', volume: game.soundVolume);
    game.health -= 1;

    const canMoveDuration = Duration(milliseconds: 400);
    gotHit = true;
    current = PlayerState.hit;

    await animationTicker?.completed;
    animationTicker?.reset();

    scale.x = 1;
    position = startingPosition - Vector2.all(32);
    current = PlayerState.appearing;

    await animationTicker?.completed;
    animationTicker?.reset();

    velocity = Vector2.zero();
    position = startingPosition;
    _updatePlayerState();
    Future.delayed(canMoveDuration, () => gotHit = false);
  }

  void _reachedCheckpoint() async {
    reachedCheckpoint = true;
    if (game.playSounds) {
      FlameAudio.play('disappear.wav', volume: game.soundVolume);
    }
    if (scale.x > 0) {
      position = position - Vector2.all(32);
    } else if (scale.x < 0) {
      position = position + Vector2(32, -32);
    }

    current = PlayerState.disappearing;

    await animationTicker?.completed;
    animationTicker?.reset();

    reachedCheckpoint = false;
    position = Vector2.all(-640);

    const waitToChangeDuration = Duration(seconds: 3);
    Future.delayed(waitToChangeDuration, () => game.loadNextLevel());
  }

  void collidedwithEnemy() {
    _respawn();
  }

}
