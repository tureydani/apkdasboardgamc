import 'package:flutter/material.dart';

/// Scaffold estándar reutilizado en las pantallas de nivel superior. Sin
/// título: la pestaña activa ya se identifica en la barra de navegación
/// inferior. Cerrar sesión vive en la pantalla de Perfil.
///
/// El AppBar solo aparece cuando hace falta: si hay `actions` que mostrar,
/// o si la pantalla fue empujada con Navigator (p. ej. Perfil) y necesita
/// la flecha de retroceso. Una pestaña raíz sin acciones (Más, y ahora
/// Inicio/Alertas tras mover sus botones al contenido) no reserva esa franja
/// vacía — el `body` es responsable de su propio SafeArea en ese caso.
class AppScaffold extends StatelessWidget {
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AppScaffold({
    super.key,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final needsBackButton = Navigator.of(context).canPop();
    final showAppBar = actions != null || needsBackButton;
    return Scaffold(
      appBar: showAppBar ? AppBar(actions: actions) : null,
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
