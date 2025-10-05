// lib/screens/home_role_based.dart

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'auth/login_screen.dart';

class HomeRoleBasedScreen extends StatefulWidget {
  const HomeRoleBasedScreen({super.key});

  @override
  State<HomeRoleBasedScreen> createState() => _HomeRoleBasedScreenState();
}

class _HomeRoleBasedScreenState extends State<HomeRoleBasedScreen> {
  final _authService = AuthService();

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _authService.logout();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    // Mostrar interfaz según el rol
    switch (user.rol) {
      case UserRole.rector:
        return _buildRectorHome(user);
      case UserRole.padre:
        return _buildPadreHome(user);
      case UserRole.conductor:
        return _buildConductorHome(user);
    }
  }

  // ========== INTERFAZ PARA RECTOR/COORDINADOR ==========
  Widget _buildRectorHome(AppUser user) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saludo personalizado
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.admin_panel_settings,
                        size: 35,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Bienvenido, ${user.nombre}!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.rolNombre,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Opciones del administrador
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.1,
                children: [
                  _buildAdminOption(
                    'Gestionar Rutas',
                    Icons.route,
                    Colors.green,
                    () {
                      // TODO: Navegar a gestión de rutas
                      _showComingSoon();
                    },
                  ),
                  _buildAdminOption(
                    'Estudiantes',
                    Icons.school,
                    Colors.blue,
                    () {
                      // TODO: Navegar a gestión de estudiantes
                      _showComingSoon();
                    },
                  ),
                  _buildAdminOption(
                    'Conductores',
                    Icons.drive_eta,
                    Colors.orange,
                    () {
                      // TODO: Navegar a gestión de conductores
                      _showComingSoon();
                    },
                  ),
                  _buildAdminOption(
                    'Padres',
                    Icons.family_restroom,
                    Colors.purple,
                    () {
                      // TODO: Navegar a gestión de padres
                      _showComingSoon();
                    },
                  ),
                  _buildAdminOption(
                    'Ver Mapa',
                    Icons.map,
                    Colors.teal,
                    () {
                      // Navegar al mapa existente
                      Navigator.pushNamed(context, '/map');
                    },
                  ),
                  _buildAdminOption(
                    'Reportes',
                    Icons.analytics,
                    Colors.red,
                    () {
                      // TODO: Navegar a reportes
                      _showComingSoon();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminOption(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 35, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== INTERFAZ PARA PADRES ==========
  Widget _buildPadreHome(AppUser user) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Hijos - Rutas'),
        backgroundColor: Colors.purple.shade400,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saludo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.purple.shade400,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.family_restroom,
                        size: 35,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Hola, ${user.nombre}!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${user.hijosIds?.length ?? 0} hijo(s) registrado(s)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Opciones para padres
              _buildParentOption(
                'Rastrear Buses',
                'Ver ubicación en tiempo real',
                Icons.location_on,
                Colors.green,
                () => Navigator.pushNamed(context, '/map'),
              ),
              const SizedBox(height: 15),
              _buildParentOption(
                'Mis Hijos',
                'Ver información de estudiantes',
                Icons.child_care,
                Colors.blue,
                () => _showComingSoon(),
              ),
              const SizedBox(height: 15),
              _buildParentOption(
                'Historial',
                'Ver entregas y eventos',
                Icons.history,
                Colors.orange,
                () => _showComingSoon(),
              ),
              const SizedBox(height: 15),
              _buildParentOption(
                'Notificaciones',
                'Mensajes y alertas',
                Icons.notifications,
                Colors.red,
                () => _showComingSoon(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParentOption(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // ========== INTERFAZ PARA CONDUCTOR ==========
  Widget _buildConductorHome(AppUser user) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Conductor'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saludo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.drive_eta,
                        size: 35,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Hola, ${user.nombre}!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${user.rutasAsignadas?.length ?? 0} ruta(s) asignada(s)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Botón destacado - Iniciar Ruta
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showComingSoon(),
                    borderRadius: BorderRadius.circular(15),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_circle_filled,
                              size: 50, color: Colors.white),
                          SizedBox(height: 10),
                          Text(
                            'INICIAR RUTA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Otras opciones
              _buildParentOption(
                'Mis Rutas',
                'Ver rutas asignadas',
                Icons.route,
                Colors.blue,
                () => _showComingSoon(),
              ),
              const SizedBox(height: 15),
              _buildParentOption(
                'Estudiantes',
                'Lista de estudiantes',
                Icons.school,
                Colors.purple,
                () => _showComingSoon(),
              ),
              const SizedBox(height: 15),
              _buildParentOption(
                'Ver Mapa',
                'Navegar con GPS',
                Icons.map,
                Colors.teal,
                () => Navigator.pushNamed(context, '/map'),
              ),
              const SizedBox(height: 15),
              _buildParentOption(
                'Historial',
                'Entregas realizadas',
                Icons.history,
                Colors.orange,
                () => _showComingSoon(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Esta función estará disponible próximamente'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
