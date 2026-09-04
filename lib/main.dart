import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/session_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/shell/main_shell.dart';

void main() {
  runApp(const SosApp());
}

class SosApp extends StatelessWidget {
  const SosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SessionProvider(),
      child: MaterialApp(
        title: 'SOS-24 GAMC',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
          useMaterial3: true,
          navigationBarTheme: const NavigationBarThemeData(
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          ),
        ),
        home: const _SessionGate(),
      ),
    );
  }
}

/// Restaura la sesión (si la cookie de NextAuth sigue vigente) antes de
/// decidir si mostrar el login o el dashboard.
class _SessionGate extends StatefulWidget {
  const _SessionGate();

  @override
  State<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<_SessionGate> {
  @override
  void initState() {
    super.initState();
    context.read<SessionProvider>().restore();
  }

  @override
  Widget build(BuildContext context) {
    final status = context.watch<SessionProvider>().status;
    switch (status) {
      case SessionStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case SessionStatus.authenticated:
        return const MainShell();
      case SessionStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
