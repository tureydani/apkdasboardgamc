import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme/index.dart';

/// Botón circular flotante único usado sobre el mapa (zoom, ubicación, etc).
/// Réplica exacta de arconde-gamc
/// (lib/features/home/presentation/widgets/map_controls.dart) para mantener
/// la misma posición/tamaño/color en ambas apps.
class MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool isLoading;
  final Gradient? gradient;

  const MapControlButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.isLoading = false,
    this.gradient,
  });

  static const double _size = 52;

  @override
  Widget build(BuildContext context) {
    final iconColor = gradient != null ? AppColors.textOnPrimary : AppColors.textPrimary;

    final button = Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? AppColors.surfacePrimary : null,
        shape: BoxShape.circle,
        border: gradient == null ? Border.all(color: AppColors.borderPrimary, width: 0.5) : null,
        boxShadow: [
          BoxShadow(
            color: gradient != null ? AppColors.shadowColor.withValues(alpha: 0.35) : AppColors.shadowColor,
            blurRadius: gradient != null ? AppSpacing.elevationMd : AppSpacing.elevationSm,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: isLoading ? null : onPressed,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                    ),
                  )
                : Icon(icon, size: AppSpacing.iconMd, color: iconColor),
          ),
        ),
      ),
    );

    return tooltip != null ? Tooltip(message: tooltip!, child: button) : button;
  }
}

/// Par de zoom in/out, anclado arriba a la derecha del mapa (mismo lugar y
/// color -primaryGradient- que en arconde-gamc).
class MapZoomControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const MapZoomControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MapControlButton(
          icon: Icons.add,
          tooltip: 'Acercar',
          onPressed: onZoomIn,
          gradient: AppColors.primaryGradient,
        ),
        const SizedBox(height: AppSpacing.sm),
        MapControlButton(
          icon: Icons.remove,
          tooltip: 'Alejar',
          onPressed: onZoomOut,
          gradient: AppColors.primaryGradient,
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.2, end: 0);
  }
}

/// Par actualizar/ubicarme, anclado abajo a la derecha del mapa (mismo
/// lugar que el fullscreen/locate-me de arconde-gamc, encima del FAB
/// "Reportar" para no superponerse).
class MapActionControls extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onLocateMe;
  final bool isLocating;

  const MapActionControls({
    super.key,
    required this.onRefresh,
    required this.onLocateMe,
    required this.isLocating,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MapControlButton(
          icon: Icons.refresh,
          tooltip: 'Actualizar',
          onPressed: onRefresh,
          gradient: AppColors.accentGradient,
        ),
        const SizedBox(height: AppSpacing.sm),
        MapControlButton(
          icon: Icons.my_location,
          tooltip: 'Mi ubicación',
          onPressed: onLocateMe,
          isLoading: isLocating,
          gradient: AppColors.secondaryGradient,
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.2, end: 0);
  }
}
