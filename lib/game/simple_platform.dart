import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';
import 'package:platform_game/game/components/buttons/jump_button.dart';
import 'package:platform_game/game/components/overlays/hud.dart';
import 'package:platform_game/game/components/players/player.dart';
import 'package:platform_game/game/components/core/level.dart';
//import 'package:platform_game/game/components/utils/character_witth_particles.dart';

class SimplePlatformer extends FlameGame
    with
        HasKeyboardHandlerComponents,
        DragCallbacks,
        HasCollisionDetection,
        TapCallbacks {
  @override
  Color backgroundColor() => const Color(0xFF211F30);
  late CameraComponent cam;
  Player player = Player(character: 'Mask Dude');
  late JoystickComponent joystick;
  late Hud livesHud = Hud(
    position: Vector2(10, 10), // Posición del HUD en la pantalla
  ); // Instancia de LivesHud
  bool showControls = true;
  bool playSounds = true;
  double soundVolume = 1.0;
  List<String> levelNames = ['level-02', 'level-03', 'level-04'];
  int currentLevelIndex = 0;
  int health = 3;
  int fruitCollected = 0;
 // CharacterWithParticles dust = CharacterWithParticles();

  @override
  FutureOr<void> onLoad() async {
    // Cargar todas las imágenes en caché
    await images.loadAllImages();

    _loadLevel();

    // Agregar HUD de Vidas

    add(livesHud);

    // Agregar controles si están habilitados
    if (showControls) {
      addJoystick();
      add(JumpButton(size: 70));
    }

    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (showControls) {
      updateJoystick();
    }

    super.update(dt);
  }

  void addJoystick() {
    joystick = JoystickComponent(
      priority: 10,
      knob: SpriteComponent(
        sprite: Sprite(
          images.fromCache('HUD/Knob.png'),
        ),
        size: Vector2.all(30), // Ajusta este valor para el tamaño del knob
      ),
      background: SpriteComponent(
        sprite: Sprite(
          images.fromCache('HUD/Joystick.png'),
        ),
        size:
            Vector2.all(80), // Ajusta este valor para el tamaño del background
      ),
      margin: const EdgeInsets.only(left: 32, bottom: 32),
    );

    add(joystick);
  }

  void updateJoystick() {
    switch (joystick.direction) {
      case JoystickDirection.left:
      case JoystickDirection.upLeft:
      case JoystickDirection.downLeft:
        player.horizontalMovement = -1;
        break;
      case JoystickDirection.right:
      case JoystickDirection.upRight:
      case JoystickDirection.downRight:
        player.horizontalMovement = 1;
        break;
      default:
        player.horizontalMovement = 0;
        break;
    }
  }

  void loadNextLevel() {
    removeWhere((component) => component is Level);

    if (currentLevelIndex < levelNames.length - 1) {
      currentLevelIndex++;
      _loadLevel();
    } else {
      currentLevelIndex = 0;
      _loadLevel();
    }
  }

  void _loadLevel() {
    Future.delayed(const Duration(seconds: 1), () {
      Level world = Level(
        player: player,
        levelName: levelNames[currentLevelIndex],
      );

      cam = CameraComponent.withFixedResolution(
        world: world,
        width: 640,
        height: 360,
      );
      cam.priority = 0;
      cam.viewfinder.anchor = Anchor.topLeft;

      addAll([cam, world]);
    });
  }
}
