// lib/services/auth_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _userKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';

  AppUser? _currentUser;

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Getter para el usuario actual
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // Usuarios de prueba (en producción esto vendría de una BD)
  final List<Map<String, dynamic>> _usuariosPrueba = [
    {
      'email': 'rector@cellano.edu.co',
      'password': 'rector123',
      'user': AppUser(
        id: '1',
        nombre: 'Juan Pérez',
        email: 'rector@cellano.edu.co',
        telefono: '3201234567',
        rol: UserRole.rector,
      ),
    },
    {
      'email': 'padre@email.com',
      'password': 'padre123',
      'user': AppUser(
        id: '2',
        nombre: 'María González',
        email: 'padre@email.com',
        telefono: '3109876543',
        rol: UserRole.padre,
        hijosIds: ['est_001', 'est_002'],
      ),
    },
    {
      'email': 'conductor@cellano.edu.co',
      'password': 'conductor123',
      'user': AppUser(
        id: '3',
        nombre: 'Carlos Rodríguez',
        email: 'conductor@cellano.edu.co',
        telefono: '3157894561',
        rol: UserRole.conductor,
        rutasAsignadas: ['Ruta 1', 'Ruta 2'],
      ),
    },
  ];

  // Inicializar - cargar sesión guardada
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;

      if (isLoggedIn) {
        final userJson = prefs.getString(_userKey);
        if (userJson != null) {
          final userMap = json.decode(userJson);
          _currentUser = AppUser.fromMap(userMap);
        }
      }
    } catch (e) {
      print('Error inicializando auth: $e');
    }
  }

  // Login
  Future<LoginResult> login(String email, String password) async {
    try {
      // Simular delay de red
      await Future.delayed(const Duration(seconds: 1));

      // Buscar usuario
      final userData = _usuariosPrueba.firstWhere(
        (u) => u['email'] == email && u['password'] == password,
        orElse: () => {},
      );

      if (userData.isEmpty) {
        return LoginResult(
          success: false,
          message: 'Credenciales incorrectas',
        );
      }

      // Guardar usuario
      _currentUser = userData['user'] as AppUser;
      await _saveUserSession();

      return LoginResult(
        success: true,
        message: 'Bienvenido ${_currentUser!.nombre}',
        user: _currentUser,
      );
    } catch (e) {
      return LoginResult(
        success: false,
        message: 'Error al iniciar sesión: $e',
      );
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      _currentUser = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.setBool(_isLoggedInKey, false);
    } catch (e) {
      print('Error en logout: $e');
    }
  }

  // Guardar sesión
  Future<void> _saveUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = json.encode(_currentUser!.toMap());
      await prefs.setString(_userKey, userJson);
      await prefs.setBool(_isLoggedInKey, true);
    } catch (e) {
      print('Error guardando sesión: $e');
    }
  }

  // Verificar si tiene permiso para una acción
  bool hasPermission(String permission) {
    if (_currentUser == null) return false;

    switch (permission) {
      case 'admin':
        return _currentUser!.esRector;
      case 'view_all_routes':
        return _currentUser!.esRector;
      case 'manage_students':
        return _currentUser!.esRector;
      case 'manage_deliveries':
        return _currentUser!.esConductor;
      case 'view_children':
        return _currentUser!.esPadre;
      default:
        return false;
    }
  }

  // Obtener usuarios de prueba (para mostrar en pantalla de login)
  List<Map<String, String>> getTestUsers() {
    return _usuariosPrueba.map((u) {
      final user = u['user'] as AppUser;
      return {
        'email': u['email'] as String,
        'password': u['password'] as String,
        'rol': user.rolNombre,
      };
    }).toList();
  }
}

// Resultado del login
class LoginResult {
  final bool success;
  final String message;
  final AppUser? user;

  LoginResult({
    required this.success,
    required this.message,
    this.user,
  });
}
