import 'package:flutter/material.dart';

/// Ancho "cómodo" para el contenido de un [AlertDialog]: el [preferred] en
/// pantallas anchas, o el ancho disponible del dispositivo (con margen) en
/// un teléfono angosto — así un mismo diálogo pensado para escritorio/
/// tablet no fuerza overflow horizontal en un celular chico.
double dialogContentWidth(BuildContext context, double preferred) {
  // AlertDialog reserva ~40dp de insetPadding a cada lado por defecto.
  final available = MediaQuery.sizeOf(context).width - 80;
  return preferred < available ? preferred : available;
}
