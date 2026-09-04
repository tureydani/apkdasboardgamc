import 'package:flutter/material.dart';

/// El sistema NO tiene una tabla editable de "estados" — son enums fijos
/// del esquema Prisma. Esta pantalla es de solo lectura, a modo de
/// referencia para el operador (mismos valores que usan los formularios
/// de Emergencias, Despacho, Unidades y Requerimientos).
class EstadosScreen extends StatelessWidget {
  const EstadosScreen({super.key});

  static const _groups = <String, List<String>>{
    'Estado de emergencia': [
      'REPORTADA', 'EN_ANALISIS', 'CLASIFICADA', 'ASIGNADA',
      'EN_ATENCION', 'RESUELTA', 'FALSA_ALARMA', 'CANCELADA',
    ],
    'Prioridad de emergencia': ['BAJA', 'MEDIA', 'ALTA', 'CRITICA'],
    'Estado de unidad': ['DISPONIBLE', 'EN_CAMINO', 'EN_SITIO', 'OCUPADA', 'FUERA_DE_SERVICIO'],
    'Estado de asignación (despacho)': [
      'SOLICITADA', 'ACEPTADA', 'EN_CAMINO', 'EN_SITIO', 'FINALIZADA', 'RECHAZADA', 'CANCELADA',
    ],
    'Estado de requerimiento de recurso': ['PENDIENTE', 'ASIGNADO', 'ATENDIDO'],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estados')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: _groups.entries
            .map(
              (g) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: g.value.map((v) => Chip(label: Text(v))).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
