
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';


class CharacterWithParticles extends SpriteComponent {
  late final ParticleSystemComponent _particleSystem;

  CharacterWithParticles() : super(size: Vector2(50, 50));

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Crear el sistema de partículas
    _particleSystem = ParticleSystemComponent(
      particle: CircleParticle(paint: Paint()..color = Colors.white),
      // Ajustar la posición de generación, velocidad, etc.
      // según el efecto deseado
      position: Vector2(0, size.y), // Generar partículas debajo del personaje
      // ... otras configuraciones
    );

    add(_particleSystem);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Actualizar la posición del sistema de partículas
    _particleSystem.position = position + Vector2(0, size.y);
  }
}