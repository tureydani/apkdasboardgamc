import 'package:flutter/foundation.dart';

/// Comparte qué asignación de despacho mostrar en Mapa > Mi ruta. Cualquier
/// pantalla (Inicio, Despacho) puede pedir "ver ruta" llamando a [show];
/// MainShell escucha para cambiar a la pestaña Mapa y MapaScreen escucha
/// para saltar a la subpestaña "Mi ruta" — sin acoplar esas pantallas entre
/// sí ni pasar el id manualmente por los constructores.
class RouteViewProvider extends ChangeNotifier {
  int? assignmentId;

  void show(int assignmentId) {
    this.assignmentId = assignmentId;
    notifyListeners();
  }

  void clear() {
    if (assignmentId == null) return;
    assignmentId = null;
    notifyListeners();
  }
}
