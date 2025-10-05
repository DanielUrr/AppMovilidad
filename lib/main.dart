// lib/main.dart

import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_role_based.dart';
import 'screens/map.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar servicio de autenticación
  final authService = AuthService();
  await authService.initialize();

  runApp(TransporteApp(authService: authService));
}

class TransporteApp extends StatelessWidget {
  final AuthService authService;

  const TransporteApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rutas Escolares CELLANO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),

      // Pantalla inicial según estado de autenticación
      home: authService.isLoggedIn
          ? const HomeRoleBasedScreen()
          : const LoginScreen(),

      // Rutas de navegación
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeRoleBasedScreen(),
        '/map': (context) => const MapScreen(),
      },
    );
  }
}
