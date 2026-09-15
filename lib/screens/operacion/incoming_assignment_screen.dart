import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/index.dart';
import '../../core/animations/motion.dart';
import '../../services/local_alert_service.dart';
import 'dispatch_list_screen.dart';

/// Pantalla de alerta a pantalla completa para "nueva asignación de
/// despacho" — mismo lenguaje visual que la pantalla de llamada entrante de
/// una app de taxi/delivery: ocupa toda la pantalla en rojo, no hay forma
/// de ignorarla sin querer, y hace sonar la sirena en loop + vibración
/// continua (ver [LocalAlertService.startAssignmentAlarm]) hasta que el
/// operador la toca — recién ahí se corta el sonido, sea cual sea el gesto
/// (ver asignación, silenciar, o volver atrás).
class IncomingAssignmentScreen extends StatefulWidget {
  final int count;
  const IncomingAssignmentScreen({super.key, required this.count});

  @override
  State<IncomingAssignmentScreen> createState() => _IncomingAssignmentScreenState();
}

class _IncomingAssignmentScreenState extends State<IncomingAssignmentScreen> {
  final _alertService = LocalAlertService.instance;

  @override
  void initState() {
    super.initState();
    unawaited(_alertService.startAssignmentAlarm());
  }

  @override
  void dispose() {
    // Cubre los tres gestos de salida (botón "Ver asignación", "Silenciar"
    // y el botón atrás del sistema): todos terminan cerrando esta pantalla,
    // así que cortar la alarma acá evita repetir la llamada en cada uno.
    unawaited(_alertService.stopAssignmentAlarm());
    super.dispose();
  }

  void _viewAssignments() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const DispatchListScreen(title: 'Asignaciones pendientes', statusFilter: ['SOLICITADA']),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.count == 1 ? 'Nueva asignación pendiente' : '${widget.count} asignaciones pendientes';
    return GestureDetector(
      // Tocar en cualquier parte de la pantalla también sirve para
      // responder — con la urgencia de una alerta sonando no hace falta
      // acertarle a un botón chico.
      onTap: _viewAssignments,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: AppColors.urgentRedDark,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(flex: 3),
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.12)),
                  child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 76),
                ).pulseGlow(minScale: 1.0, maxScale: 1.12, minOpacity: 0.75, maxOpacity: 1.0, duration: const Duration(milliseconds: 700)),
                const SizedBox(height: 28),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tocá la pantalla para revisar y responder',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14.5),
                ),
                const Spacer(flex: 4),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _viewAssignments,
                    icon: const Icon(Icons.local_shipping_outlined),
                    label: const Text('Ver asignación'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.urgentRedDark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(foregroundColor: Colors.white.withValues(alpha: 0.85)),
                  child: const Text('Silenciar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
