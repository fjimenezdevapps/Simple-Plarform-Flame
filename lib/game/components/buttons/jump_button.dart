import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:platform_game/game/simple_platform.dart';

class JumpButton extends SpriteComponent 
    with HasGameRef<SimplePlatformer>, TapCallbacks {
  // Constantes para configuración
  static const double _defaultSize = 80.0;
  static const double _margin = 32.0;
  static const double _pressedScale = 0.9;

  bool _isPressed = false;
  bool _jumpTriggered = false;  // Nueva bandera para evitar saltos dobles
  late double _originalScale;

  // Getter para consultar el estado del botón si es necesario
  bool get isPressed => _isPressed;

  JumpButton({
    double? size,
    double? margin,
  }) : super(
         size: Vector2.all(size ?? _defaultSize),
         anchor: Anchor.center,
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = Sprite(game.images.fromCache('HUD/JumpButton.png'));
    _originalScale = scale.x;

    position = Vector2(
      game.size.x - _margin - (size.x / 2),
      game.size.y - _margin - (size.y / 2),
    );

    priority = 10;
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (!_jumpTriggered) {  // Solo permite un salto por pulsación
      _isPressed = true;
      game.player.hasJumped = true;  // Realizar el salto
      _jumpTriggered = true;  // Marcar que el salto ha sido activado
      scale = Vector2.all(_originalScale * _pressedScale);
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    _isPressed = false;
    _jumpTriggered = false;  // Reiniciar la bandera para el próximo toque
    scale = Vector2.all(_originalScale);
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    super.onTapCancel(event);
    _isPressed = false;
    _jumpTriggered = false;  // Reiniciar la bandera si el toque es cancelado
    scale = Vector2.all(_originalScale);
  }
}