class Estudiante {
  final String id;
  final String nombre;
  final String apellido;
  final String grado;
  final String seccion;
  final DateTime fechaNacimiento;
  final String direccion;
  final String rutaId; // Ruta asignada
  final String paraderoId; // Paradero donde lo recogen/dejan

  // Información de contacto de emergencia
  final String contactoEmergencia;
  final String telefonoEmergencia;

  // Padres/acudientes
  final List<String> padresIds;

  // Información adicional
  final String? alergias;
  final String? medicamentos;
  final String? observaciones;

  final bool activo;
  final DateTime createdAt;

  Estudiante({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.grado,
    required this.seccion,
    required this.fechaNacimiento,
    required this.direccion,
    required this.rutaId,
    required this.paraderoId,
    required this.contactoEmergencia,
    required this.telefonoEmergencia,
    required this.padresIds,
    this.alergias,
    this.medicamentos,
    this.observaciones,
    this.activo = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get nombreCompleto => '$nombre $apellido';

  int get edad {
    final now = DateTime.now();
    int age = now.year - fechaNacimiento.year;
    if (now.month < fechaNacimiento.month ||
        (now.month == fechaNacimiento.month && now.day < fechaNacimiento.day)) {
      age--;
    }
    return age;
  }

  factory Estudiante.fromMap(Map<String, dynamic> map) {
    return Estudiante(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      apellido: map['apellido'] ?? '',
      grado: map['grado'] ?? '',
      seccion: map['seccion'] ?? '',
      fechaNacimiento: DateTime.parse(map['fechaNacimiento']),
      direccion: map['direccion'] ?? '',
      rutaId: map['rutaId'] ?? '',
      paraderoId: map['paraderoId'] ?? '',
      contactoEmergencia: map['contactoEmergencia'] ?? '',
      telefonoEmergencia: map['telefonoEmergencia'] ?? '',
      padresIds: List<String>.from(map['padresIds'] ?? []),
      alergias: map['alergias'],
      medicamentos: map['medicamentos'],
      observaciones: map['observaciones'],
      activo: map['activo'] ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'grado': grado,
      'seccion': seccion,
      'fechaNacimiento': fechaNacimiento.toIso8601String(),
      'direccion': direccion,
      'rutaId': rutaId,
      'paraderoId': paraderoId,
      'contactoEmergencia': contactoEmergencia,
      'telefonoEmergencia': telefonoEmergencia,
      'padresIds': padresIds,
      'alergias': alergias,
      'medicamentos': medicamentos,
      'observaciones': observaciones,
      'activo': activo,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
