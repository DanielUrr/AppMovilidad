// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transporte_app/main.dart';
import 'package:transporte_app/services/auth_service.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    // Crear instancia de AuthService para el test
    final authService = AuthService();

    // Build our app and trigger a frame.
    await tester.pumpWidget(TransporteApp(authService: authService));

    // Verificar que la pantalla de login se muestra (ya que no hay sesión activa)
    expect(find.text('RUTAS ESCOLARES'), findsOneWidget);
    expect(find.text('CELLANO'), findsOneWidget);

    // Verificar que hay campos de email y password
    expect(find.byType(TextFormField), findsNWidgets(2));

    // Verificar que el botón de login existe
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
  });

  testWidgets('Login screen shows test users button',
      (WidgetTester tester) async {
    final authService = AuthService();

    await tester.pumpWidget(TransporteApp(authService: authService));

    // Verificar que el botón de usuarios de prueba existe
    expect(find.text('Ver usuarios de prueba'), findsOneWidget);
  });

  testWidgets('Login form validation works', (WidgetTester tester) async {
    final authService = AuthService();

    await tester.pumpWidget(TransporteApp(authService: authService));

    // Intentar hacer login sin llenar los campos
    await tester.tap(find.text('INICIAR SESIÓN'));
    await tester.pump();

    // Verificar que aparecen mensajes de error
    expect(find.text('Por favor ingresa tu correo'), findsOneWidget);
    expect(find.text('Por favor ingresa tu contraseña'), findsOneWidget);
  });
}
