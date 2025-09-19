import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CardService {
  static const String _saldoKey = 'tarjeta_saldo';
  static const String _transaccionesKey = 'tarjeta_transacciones';

  // Obtener el saldo actual
  Future<double> getSaldo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_saldoKey) ?? 0.0;
  }

  // Establecer el saldo
  Future<void> _setSaldo(double saldo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_saldoKey, saldo);
  }

  // Recargar saldo
  Future<bool> recargar(double monto) async {
    try {
      if (monto <= 0) return false;

      final saldoActual = await getSaldo();
      final nuevoSaldo = saldoActual + monto;

      await _setSaldo(nuevoSaldo);
      await _agregarTransaccion('recarga', monto, 'Recarga de saldo');

      return true;
    } catch (e) {
      return false;
    }
  }

  // Pagar pasaje
  Future<bool> pagarPasaje(double tarifa) async {
    try {
      final saldoActual = await getSaldo();

      if (saldoActual < tarifa) {
        return false; // Saldo insuficiente
      }

      final nuevoSaldo = saldoActual - tarifa;
      await _setSaldo(nuevoSaldo);
      await _agregarTransaccion('pago', tarifa, 'Pago de pasaje');

      return true;
    } catch (e) {
      return false;
    }
  }

  // Obtener historial de transacciones
  Future<List<Map<String, dynamic>>> getTransacciones() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? transaccionesJson = prefs.getString(_transaccionesKey);

      if (transaccionesJson == null) return [];

      final List<dynamic> transaccionesList = json.decode(transaccionesJson);
      return transaccionesList
          .map((t) => Map<String, dynamic>.from(t))
          .toList()
          .reversed
          .toList(); // Mostrar las más recientes primero
    } catch (e) {
      return [];
    }
  }

  // Agregar una nueva transacción
  Future<void> _agregarTransaccion(
    String tipo,
    double monto,
    String descripcion,
  ) async {
    try {
      final transacciones = await getTransacciones();

      final nuevaTransaccion = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'tipo': tipo, // 'recarga' o 'pago'
        'monto': monto,
        'descripcion': descripcion,
        'fecha': _formatearFecha(DateTime.now()),
        'timestamp': DateTime.now().toIso8601String(),
      };

      transacciones.insert(0, nuevaTransaccion); // Agregar al inicio

      // Mantener solo las últimas 50 transacciones
      if (transacciones.length > 50) {
        transacciones.removeRange(50, transacciones.length);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_transaccionesKey, json.encode(transacciones));
    } catch (e) {
      // Manejar error silenciosamente
    }
  }

  // Formatear fecha para mostrar
  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inMinutes < 1) {
      return 'Hace un momento';
    } else if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes} ${diferencia.inMinutes == 1 ? 'minuto' : 'minutos'}';
    } else if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours} ${diferencia.inHours == 1 ? 'hora' : 'horas'}';
    } else if (diferencia.inDays == 1) {
      return 'Ayer a las ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
    } else if (diferencia.inDays < 7) {
      return 'Hace ${diferencia.inDays} días';
    } else {
      final meses = [
        '',
        'Ene',
        'Feb',
        'Mar',
        'Abr',
        'May',
        'Jun',
        'Jul',
        'Ago',
        'Sep',
        'Oct',
        'Nov',
        'Dic',
      ];
      return '${fecha.day} ${meses[fecha.month]} ${fecha.year}';
    }
  }

  // Limpiar todos los datos (útil para testing o reset)
  Future<void> limpiarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saldoKey);
    await prefs.remove(_transaccionesKey);
  }

  // Obtener estadísticas de uso
  Future<Map<String, dynamic>> getEstadisticas() async {
    try {
      final transacciones = await getTransacciones();
      final ahora = DateTime.now();
      final inicioMes = DateTime(ahora.year, ahora.month, 1);

      double totalRecargas = 0;
      double totalGastos = 0;
      int viajesEsteMes = 0;

      for (final transaccion in transacciones) {
        final fechaTransaccion = DateTime.parse(transaccion['timestamp']);

        if (transaccion['tipo'] == 'recarga') {
          totalRecargas += transaccion['monto'];
        } else if (transaccion['tipo'] == 'pago') {
          totalGastos += transaccion['monto'];

          if (fechaTransaccion.isAfter(inicioMes)) {
            viajesEsteMes++;
          }
        }
      }

      return {
        'total_recargas': totalRecargas,
        'total_gastos': totalGastos,
        'viajes_este_mes': viajesEsteMes,
        'ahorro_potencial': (viajesEsteMes * 2500) - totalGastos,
        'promedio_viajes_dia': viajesEsteMes / ahora.day,
      };
    } catch (e) {
      return {
        'total_recargas': 0.0,
        'total_gastos': 0.0,
        'viajes_este_mes': 0,
        'ahorro_potencial': 0.0,
        'promedio_viajes_dia': 0.0,
      };
    }
  }
}
