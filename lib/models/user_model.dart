// lib/models/user_model.dart

enum UserRole {
  rector, // Rector/Coordinador - acceso completo
  padre, // Padres - solo ven rutas de sus hijos
  conductor // Conductores - gestionan entregas
}

class AppUser {
  final String id;
  final String nombre;
  final String email;
  final String telefono;
  final UserRole rol;
  final bool activo;
  final DateTime createdAt;

  // Para padres: IDs de sus hijos
  final List<String>? hijosIds;

  // Para conductores: IDs de rutas asignadas
  final List<String>? rutasAsignadas;

  AppUser({
    required this.id,
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.rol,
    this.activo = true,
    DateTime? createdAt,
    this.hijosIds,
    this.rutasAsignadas,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convertir de/a Map para almacenamiento
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      email: map['email'] ?? '',
      telefono: map['telefono'] ?? '',
      rol: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${map['rol']}',
        orElse: () => UserRole.padre,
      ),
      activo: map['activo'] ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      hijosIds:
          map['hijosIds'] != null ? List<String>.from(map['hijosIds']) : null,
      rutasAsignadas: map['rutasAsignadas'] != null
          ? List<String>.from(map['rutasAsignadas'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'telefono': telefono,
      'rol': rol.toString().split('.').last,
      'activo': activo,
      'createdAt': createdAt.toIso8601String(),
      'hijosIds': hijosIds,
      'rutasAsignadas': rutasAsignadas,
    };
  }

  // Helpers
  bool get esRector => rol == UserRole.rector;
  bool get esPadre => rol == UserRole.padre;
  bool get esConductor => rol == UserRole.conductor;

  String get rolNombre {
    switch (rol) {
      case UserRole.rector:
        return 'Rector/Coordinador';
      case UserRole.padre:
        return 'Padre de Familia';
      case UserRole.conductor:
        return 'Conductor';
    }
  }
}
