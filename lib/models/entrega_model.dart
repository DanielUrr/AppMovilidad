enum EstadoEntrega {
  pendiente, // Aún no ha llegado al paradero
  enCamino, // Bus en camino al paradero
  entregado, // Estudiante entregado exitosamente
  noRecibido, // Nadie recibió al estudiante
  retornadoColegio // Devuelto al colegio
}

class RegistroEntrega {
  final String id;
  final String estudianteId;
  final String rutaId;
  final String conductorId;
  final DateTime fecha;
  final EstadoEntrega estado;
  final String paraderoId;

  // Información de entrega
  final DateTime? horaEntrega;
  final String? personaRecibe; // Quién recibió al estudiante
  final String? observaciones;
  final String? fotoEvidencia; // URL de foto (opcional)

  RegistroEntrega({
    required this.id,
    required this.estudianteId,
    required this.rutaId,
    required this.conductorId,
    required this.fecha,
    required this.estado,
    required this.paraderoId,
    this.horaEntrega,
    this.personaRecibe,
    this.observaciones,
    this.fotoEvidencia,
  });

  factory RegistroEntrega.fromMap(Map<String, dynamic> map) {
    return RegistroEntrega(
      id: map['id'] ?? '',
      estudianteId: map['estudianteId'] ?? '',
      rutaId: map['rutaId'] ?? '',
      conductorId: map['conductorId'] ?? '',
      fecha: DateTime.parse(map['fecha']),
      estado: EstadoEntrega.values.firstWhere(
        (e) => e.toString() == 'EstadoEntrega.${map['estado']}',
        orElse: () => EstadoEntrega.pendiente,
      ),
      paraderoId: map['paraderoId'] ?? '',
      horaEntrega: map['horaEntrega'] != null
          ? DateTime.parse(map['horaEntrega'])
          : null,
      personaRecibe: map['personaRecibe'],
      observaciones: map['observaciones'],
      fotoEvidencia: map['fotoEvidencia'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'estudianteId': estudianteId,
      'rutaId': rutaId,
      'conductorId': conductorId,
      'fecha': fecha.toIso8601String(),
      'estado': estado.toString().split('.').last,
      'paraderoId': paraderoId,
      'horaEntrega': horaEntrega?.toIso8601String(),
      'personaRecibe': personaRecibe,
      'observaciones': observaciones,
      'fotoEvidencia': fotoEvidencia,
    };
  }

  String get estadoTexto {
    switch (estado) {
      case EstadoEntrega.pendiente:
        return 'Pendiente';
      case EstadoEntrega.enCamino:
        return 'En Camino';
      case EstadoEntrega.entregado:
        return 'Entregado';
      case EstadoEntrega.noRecibido:
        return 'No Recibido';
      case EstadoEntrega.retornadoColegio:
        return 'Retornado al Colegio';
    }
  }
}
