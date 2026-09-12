import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Mismo lenguaje de animación que arconde-gamc
/// (lib/core/animations/motion.dart) — por ahora solo el efecto de
/// "parpadeo" que usa para marcar íconos como urgentes/en vivo en el mapa.
extension MotionExtensions on Widget {
  /// Efecto de "respiración" (escala + opacidad) en bucle lento. Usar con
  /// moderación, solo para el elemento que debe leerse como "en vivo": un
  /// pin de emergencia crítica, un punto sin leer, un FAB principal.
  Widget pulseGlow({
    double minScale = 1.0,
    double maxScale = 1.15,
    double minOpacity = 0.55,
    double maxOpacity = 1.0,
    Duration duration = const Duration(milliseconds: 900),
  }) {
    return animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: Offset(minScale, minScale),
          end: Offset(maxScale, maxScale),
          duration: duration,
          curve: Curves.easeInOut,
        )
        .fade(begin: minOpacity, end: maxOpacity, duration: duration, curve: Curves.easeInOut);
  }
}
