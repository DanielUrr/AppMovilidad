import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

class ChatbotService {
  Map<String, dynamic> _rutasData = {};
  bool _isLoaded = false;

  // Contexto de conversación para mantener memoria
  List<Map<String, String>> _conversationHistory = [];
  final Map<String, dynamic> _userContext = {};

  Future<void> _loadRutasData() async {
    if (!_isLoaded) {
      try {
        final String jsonString =
            await rootBundle.loadString('assets/data/rutas.json');
        _rutasData = json.decode(jsonString);
        _isLoaded = true;
      } catch (e) {
        _rutasData = {};
        _isLoaded = true;
      }
    }
  }

  Future<String> getResponse(String userMessage) async {
    await _loadRutasData();

    // Guardar mensaje en el historial
    _conversationHistory.add({
      'role': 'user',
      'message': userMessage,
    });

    String response = await _processMessage(userMessage);

    // Guardar respuesta en el historial
    _conversationHistory.add({
      'role': 'assistant',
      'message': response,
    });

    // Mantener solo los últimos 10 mensajes
    if (_conversationHistory.length > 20) {
      _conversationHistory =
          _conversationHistory.sublist(_conversationHistory.length - 20);
    }

    return response;
  }

  Future<String> _processMessage(String userMessage) async {
    final message = userMessage.toLowerCase().trim();

    // Análisis de intención del usuario
    final intent = _analyzeIntent(message);

    switch (intent['type']) {
      case 'greeting':
        return _getGreetingResponse(message);
      case 'farewell':
        return _getFarewellResponse();
      case 'route_info':
        return _getRutaResponse(message);
      case 'fare':
        return _getTarifaResponse(message);
      case 'schedule':
        return _getHorarioResponse(message);
      case 'stops':
        return _getParaderosResponse(message);
      case 'navigation':
        return _getNavigationResponse(message);
      case 'real_time':
        return _getRealTimeResponse(message);
      case 'payment':
        return _getPaymentResponse(message);
      case 'help':
        return _getHelpResponse();
      case 'emergency':
        return _getEmergencyResponse();
      case 'complaint':
        return _getComplaintResponse();
      case 'suggestion':
        return _getSuggestionResponse(message);
      case 'weather':
        return _getWeatherResponse();
      case 'tourism':
        return _getTourismResponse(message);
      case 'accessibility':
        return _getAccessibilityResponse(message);
      case 'lost_found':
        return _getLostFoundResponse(message);
      case 'statistics':
        return _getStatisticsResponse();
      case 'comparison':
        return _getComparisonResponse(message);
      case 'recommendation':
        return _getRecommendationResponse(message);
      default:
        return _getIntelligentResponse(message);
    }
  }

  Map<String, dynamic> _analyzeIntent(String message) {
    // Análisis más sofisticado de intención
    if (_containsAny(message, [
      'hola',
      'buenos días',
      'buenas tardes',
      'qué tal',
      'saludos',
      'hey'
    ])) {
      return {'type': 'greeting'};
    }
    if (_containsAny(
        message, ['adiós', 'chao', 'hasta luego', 'bye', 'nos vemos'])) {
      return {'type': 'farewell'};
    }
    if (_containsAny(message, [
      'tarifa',
      'precio',
      'costo',
      'valor',
      'cuánto cuesta',
      'cuánto vale'
    ])) {
      return {'type': 'fare'};
    }
    if (_containsAny(
        message, ['horario', 'hora', 'cuando', 'abre', 'cierra', 'funciona'])) {
      return {'type': 'schedule'};
    }
    if (_containsAny(message,
        ['paradero', 'parada', 'estación', 'dónde para', 'dónde pasa'])) {
      return {'type': 'stops'};
    }
    if (_containsAny(message, [
      'cómo llego',
      'cómo voy',
      'ruta para',
      'quiero ir',
      'necesito ir',
      'llegar a'
    ])) {
      return {'type': 'navigation'};
    }
    if (_containsAny(message,
        ['dónde está', 'tiempo real', 'cuánto falta', 'ya viene', 'demora'])) {
      return {'type': 'real_time'};
    }
    if (_containsAny(message,
        ['pagar', 'tarjeta', 'recarga', 'saldo', 'efectivo', 'pago'])) {
      return {'type': 'payment'};
    }
    if (_containsAny(message,
        ['emergencia', 'accidente', 'problema', 'ayuda urgente', 'policía'])) {
      return {'type': 'emergency'};
    }
    if (_containsAny(message,
        ['queja', 'reclamo', 'mal servicio', 'problema con', 'molesto'])) {
      return {'type': 'complaint'};
    }
    if (_containsAny(message,
        ['sugerir', 'sugerencia', 'mejorar', 'propongo', 'sería bueno'])) {
      return {'type': 'suggestion'};
    }
    if (_containsAny(message, ['clima', 'lluvia', 'tiempo', 'pronóstico'])) {
      return {'type': 'weather'};
    }
    if (_containsAny(
        message, ['turismo', 'visitar', 'conocer', 'lugares', 'sitios'])) {
      return {'type': 'tourism'};
    }
    if (_containsAny(
        message, ['discapacidad', 'silla de ruedas', 'accesible', 'rampa'])) {
      return {'type': 'accessibility'};
    }
    if (_containsAny(
        message, ['perdí', 'encontré', 'olvidé', 'dejé', 'perdido'])) {
      return {'type': 'lost_found'};
    }
    if (_containsAny(
        message, ['estadística', 'cuántos', 'promedio', 'datos'])) {
      return {'type': 'statistics'};
    }
    if (_containsAny(
        message, ['mejor', 'más rápido', 'más barato', 'comparar', 'versus'])) {
      return {'type': 'comparison'};
    }
    if (_containsAny(
        message, ['recomienda', 'qué me sugieres', 'cuál es mejor'])) {
      return {'type': 'recommendation'};
    }
    if (_containsAny(message, ['ruta', 'línea', 'bus', 'información'])) {
      return {'type': 'route_info'};
    }
    if (_containsAny(message, ['ayuda', 'help', 'qué puedes', 'opciones'])) {
      return {'type': 'help'};
    }

    return {'type': 'general'};
  }

  String _getGreetingResponse(String message) {
    final hour = DateTime.now().hour;
    String timeGreeting = '';

    if (hour < 12) {
      timeGreeting = 'Buenos días';
    } else if (hour < 18) {
      timeGreeting = 'Buenas tardes';
    } else {
      timeGreeting = 'Buenas noches';
    }

    final responses = [
      '$timeGreeting! 👋 Soy tu asistente inteligente de transporte. Puedo ayudarte con rutas, horarios, tarifas, navegación y mucho más. ¿Qué necesitas hoy?',
      '¡Hola! $timeGreeting 😊 Estoy aquí para hacer tu viaje más fácil. Pregúntame sobre rutas, paraderos, o cómo llegar a tu destino.',
      '$timeGreeting! 🚌 ¿Listo para viajar? Te puedo ayudar con toda la información del transporte público.',
    ];

    return responses[Random().nextInt(responses.length)];
  }

  String _getFarewellResponse() {
    final responses = [
      '¡Hasta luego! 👋 Que tengas un excelente viaje. Recuerda que estoy aquí cuando me necesites.',
      '¡Adiós! 😊 Fue un placer ayudarte. ¡Buen viaje y que llegues bien a tu destino!',
      '¡Nos vemos! 🚌 Espero haberte sido útil. ¡Cuídate y viaja seguro!',
    ];

    return responses[Random().nextInt(responses.length)];
  }

  String _getNavigationResponse(String message) {
    // Extraer posibles destinos del mensaje
    String origen = '';
    String destino = '';

    if (message.contains('centro')) destino = 'Centro';
    if (message.contains('hospital')) destino = 'Hospital';
    if (message.contains('terminal')) destino = 'Terminal';
    if (message.contains('unillanos')) destino = 'Unillanos';

    if (destino.isNotEmpty) {
      List<String> rutasRecomendadas = [];
      _rutasData.forEach((ruta, datos) {
        final paraderos = datos['paraderos'] as List;
        if (paraderos.any((p) => p['nombre']
            .toString()
            .toLowerCase()
            .contains(destino.toLowerCase()))) {
          rutasRecomendadas.add(ruta);
        }
      });

      if (rutasRecomendadas.isNotEmpty) {
        String respuesta = '🗺️ **Para llegar a $destino**, puedes tomar:\n\n';
        for (String ruta in rutasRecomendadas) {
          final datos = _rutasData[ruta];
          respuesta += '🚌 **$ruta**\n';
          respuesta += '   • Tarifa: \$${datos['tarifa']}\n';
          respuesta +=
              '   • Frecuencia: ${datos['frecuencia'] ?? 'Cada 15 minutos'}\n\n';
        }
        respuesta +=
            '💡 **Tip:** Revisa el mapa en tiempo real para ver la ubicación actual de los buses.';
        return respuesta;
      }
    }

    return '''
🗺️ **Navegación y Rutas**

Para ayudarte mejor a llegar a tu destino, necesito saber:
• ¿Dónde estás ahora? (o usaré tu ubicación actual)
• ¿A dónde quieres ir?

Puedo recomendarte:
✅ La ruta más rápida
✅ La más económica
✅ Con menos transbordos
✅ La más accesible

Por ejemplo, pregúntame:
• "Cómo llego al Centro desde Unillanos"
• "Quiero ir al Hospital"
• "Rutas para llegar a Terminal"
''';
  }

  String _getRealTimeResponse(String message) {
    // Simular respuesta en tiempo real
    final random = Random();
    final minutos = random.nextInt(15) + 1;

    String rutaMencionada = '';
    for (String ruta in _rutasData.keys) {
      if (message.toLowerCase().contains(ruta.toLowerCase())) {
        rutaMencionada = ruta;
        break;
      }
    }

    if (rutaMencionada.isNotEmpty) {
      return '''
🕐 **Estado en Tiempo Real - $rutaMencionada**

📍 Próximo bus llegará en: **$minutos minutos**

🚌 Buses en ruta:
• Bus #${random.nextInt(100) + 200}: A $minutos min
• Bus #${random.nextInt(100) + 200}: A ${minutos + 10} min
• Bus #${random.nextInt(100) + 200}: A ${minutos + 20} min

📊 Estado actual:
• Tráfico: ${random.nextBool() ? 'Normal ✅' : 'Congestionado ⚠️'}
• Ocupación: ${random.nextInt(70) + 20}%
• Tiempo estimado de viaje: ${random.nextInt(20) + 15} minutos

💡 **Tip:** Activa las notificaciones para recibir alertas cuando el bus esté cerca.
''';
    }

    return '''
🕐 **Información en Tiempo Real**

Para darte información actualizada necesito saber:
• ¿Qué ruta estás esperando?
• ¿En qué paradero estás?

Puedo informarte sobre:
• ⏱️ Tiempo de llegada del próximo bus
• 🚌 Cantidad de buses en ruta
• 📍 Ubicación actual de los buses
• 🚦 Estado del tráfico
• 👥 Nivel de ocupación

Ejemplo: "¿Cuánto falta para que llegue la Ruta 1?"
''';
  }

  String _getPaymentResponse(String message) {
    return '''
💳 **Opciones de Pago y Tarjeta**

**Formas de pago disponibles:**
• 💵 Efectivo (pago exacto recomendado)
• 💳 Tarjeta de Transporte (recargable)
• 📱 Pago con QR (próximamente)

**Tarjeta de Transporte:**
• Precio de la tarjeta: \$5,000
• Recarga mínima: \$5,000
• Recarga máxima: \$100,000
• Descuento con tarjeta: 10%

**Puntos de recarga:**
• 🏪 Tiendas autorizadas
• 🏦 Estaciones principales
• 📱 App móvil (con PSE)
• 🏧 Cajeros automáticos

**Beneficios de la tarjeta:**
✅ Descuentos en pasajes
✅ Transbordos gratuitos (30 min)
✅ Historial de viajes
✅ Recarga en línea
✅ Bloqueo por pérdida

¿Necesitas ayuda con algo específico sobre pagos?
''';
  }

  String _getEmergencyResponse() {
    return '''
🚨 **NÚMEROS DE EMERGENCIA**

**Líneas de Emergencia:**
• 🚓 Policía: 123
• 🚑 Ambulancia: 125
• 🚒 Bomberos: 119
• 📞 Línea de emergencias: 123

**Seguridad en el Transporte:**
• 📱 WhatsApp Seguridad: +57 320 123 4567
• 📞 Central de Radio: (8) 678-9012

**En caso de emergencia en el bus:**
1. Mantén la calma
2. Notifica al conductor
3. Usa el botón de pánico si está disponible
4. Llama a las autoridades
5. Toma foto de la placa del bus

**Hospitales cercanos:**
• 🏥 Hospital Departamental - Calle 37 #33-04
• 🏥 Clínica Martha - Carrera 33 #15-48
• 🏥 Clínica Meta - Calle 15 #23-17

¿Necesitas ayuda inmediata? Por favor llama al 123.
''';
  }

  String _getComplaintResponse() {
    return '''
📝 **Quejas y Reclamos**

Lamento que hayas tenido una mala experiencia. Puedes reportar tu queja a través de:

**Canales de atención:**
• 📧 Email: quejas@transportevillavicencio.gov.co
• 📞 Línea gratuita: 018000-123456
• 📱 WhatsApp: +57 320 987 6543
• 🏢 Oficina: Calle 40 #29-51 (Lun-Vie 8am-5pm)

**Información necesaria para tu queja:**
• 🚌 Número de ruta
• 📅 Fecha y hora del incidente
• 🚌 Número de placa del bus (si lo tienes)
• 👤 Descripción del conductor (si aplica)
• 📝 Descripción detallada del problema

**Tipos de quejas comunes:**
• Mal trato del conductor
• Bus en mal estado
• Incumplimiento de ruta
• Cobro excesivo
• Negación del servicio

Tu queja será atendida en máximo 15 días hábiles.
¿Te gustaría que te ayude a redactar tu queja?
''';
  }

  String _getSuggestionResponse(String message) {
    return '''
💡 **Gracias por tu sugerencia!**

Valoramos mucho tu opinión para mejorar el servicio. 

**Puedes enviar tus sugerencias a:**
• 📧 sugerencias@transportevillavicencio.gov.co
• 📱 App oficial (sección "Sugerencias")
• 🏢 Buzón físico en terminales principales

**Temas frecuentes de mejora:**
• 🚏 Nuevos paraderos
• 🕐 Ajustes de horarios
• 🛣️ Modificación de rutas
• ♿ Accesibilidad
• 🌱 Sostenibilidad ambiental

Tu sugerencia será evaluada por el comité de mejoramiento continuo.

**¿Sabías que...?**
Las mejores sugerencias del mes reciben reconocimiento y pueden ganar premios como recargas gratis en la tarjeta de transporte.

¡Gracias por ayudarnos a mejorar! 🌟
''';
  }

  String _getWeatherResponse() {
    // Simular condiciones climáticas
    final random = Random();
    final temp = random.nextInt(10) + 20;
    final isRaining = random.nextBool();

    return '''
🌤️ **Clima y Transporte**

**Pronóstico de hoy en Villavicencio:**
• 🌡️ Temperatura: $temp°C
• ${isRaining ? '🌧️ Lluvia esperada' : '☀️ Día soleado'}
• 💨 Viento: 12 km/h

${isRaining ? '''
⚠️ **Precauciones por lluvia:**
• Los buses pueden demorar 5-10 min más
• Lleva paraguas o impermeable
• Ten cuidado al subir/bajar del bus
• Algunos paraderos no tienen techo

**Rutas afectadas por lluvia:**
🚌 Ruta 3 y 4: Posibles retrasos en zona Catama
🚌 Ruta 6: Precaución en La Esperanza
''' : '''
✅ **Condiciones favorables para viajar**
• Tiempos normales en todas las rutas
• Buena visibilidad
• Sin afectaciones en el servicio
'''}

💡 **Tip:** Consulta el clima antes de salir para planear mejor tu viaje.
''';
  }

  String _getTourismResponse(String message) {
    return '''
🎭 **Turismo en Villavicencio - Cómo Llegar en Bus**

**Sitios Turísticos y Rutas:**

🏛️ **Catedral Nuestra Señora del Carmen**
• 📍 Centro - Rutas 1, 3, 4
• 🚌 Paradero: Centro

🌳 **Parque Los Fundadores**
• 📍 Centro - Rutas 1, 3, 4
• 🚌 Paradero: Centro

🎪 **Parque Las Malocas**
• 📍 Vía Catama - Ruta 2
• 🚌 Paradero: Catama

🏛️ **Casa de la Cultura**
• 📍 Centro - Rutas 1, 3, 4
• 🚌 Paradero: Centro

🌊 **Bioparque Los Ocarros**
• 📍 Vía Restrepo - Ruta especial (consultar)
• 🚌 Salida desde Terminal

**Eventos y Festivales:**
• 🎭 Festival Llanero (Julio)
• 🎵 Torneo Internacional del Joropo
• 🎨 Feria Agroindustrial

**Tips para turistas:**
• 🎫 Compra un pase diario: \$15,000
• 📱 Descarga el mapa offline
• 🌅 Mejores horas: 6-10am y 4-7pm
• 💧 Lleva agua, hace calor

¿Qué lugar te gustaría visitar?
''';
  }

  String _getAccessibilityResponse(String message) {
    return '''
♿ **Accesibilidad en el Transporte**

**Servicios para personas con discapacidad:**

**Buses accesibles:**
• 🚌 30% de la flota con rampa
• 🪑 Espacios para sillas de ruedas
• 🔔 Timbres accesibles
• 📢 Anuncios auditivos

**Rutas con mayor accesibilidad:**
✅ Ruta 1: 80% buses accesibles
✅ Ruta 3: 70% buses accesibles
✅ Ruta 5: 60% buses accesibles

**Paraderos accesibles:**
• 🚏 Centro - Rampa y señalización braille
• 🚏 Hospital - Totalmente accesible
• 🚏 Terminal - Ascensor y rampas
• 🚏 Unillanos - Parcialmente accesible

**Servicios especiales:**
• 📞 Línea preferencial: (8) 678-3456
• 🆓 Descuento 50% con carnet
• 👥 Asistencia personalizada
• 📱 App con modo accesibilidad

**Horarios con asistencia:**
• Lunes a Viernes: 6am - 8pm
• Sábados: 7am - 5pm

¿Necesitas información específica sobre accesibilidad?
''';
  }

  String _getLostFoundResponse(String message) {
    return '''
📦 **Objetos Perdidos**

**¿Perdiste algo en el bus?**

**Pasos a seguir:**
1. 📞 Llama inmediatamente: (8) 678-5555
2. 📝 Proporciona:
   • Ruta y número de bus
   • Hora aproximada
   • Descripción del objeto
   • Tu información de contacto

**Oficina de Objetos Perdidos:**
• 📍 Terminal de Transporte, Oficina 201
• 🕐 Lun-Vie: 8am-5pm, Sáb: 8am-12pm
• 📧 objetosperdidos@transportevilla.gov.co

**Objetos más comunes:**
• 📱 Celulares (40%)
• 👛 Billeteras (25%)
• 🎒 Mochilas (15%)
• 🔑 Llaves (10%)
• 📚 Otros (10%)

**Tips para no perder objetos:**
✅ Revisa tu asiento antes de bajar
✅ Guarda objetos de valor en bolsillos con cierre
✅ Mantén tu mochila al frente
✅ Toma foto del número del bus

**Tiempo de custodia:** 30 días

¿Qué objeto perdiste? Te puedo ayudar con el reporte.
''';
  }

  String _getStatisticsResponse() {
    final random = Random();

    return '''
📊 **Estadísticas del Sistema de Transporte**

**Datos del servicio (mes actual):**
• 🚌 Buses en operación: 127
• 👥 Pasajeros diarios: ${(random.nextInt(5000) + 15000).toString()}
• 📍 Paraderos activos: 84
• 🛣️ Kilómetros recorridos: ${(random.nextInt(50000) + 150000).toString()}

**Rutas más utilizadas:**
1. 🥇 Ruta 1: 35% de pasajeros
2. 🥈 Ruta 2: 25% de pasajeros
3. 🥉 Ruta 3: 20% de pasajeros

**Horas pico:**
• 🌅 Mañana: 6:30am - 8:30am
• 🌆 Tarde: 5:00pm - 7:30pm
• 📈 Incremento: +150% pasajeros

**Satisfacción del usuario:**
• ⭐⭐⭐⭐ 4.2/5.0
• 😊 78% satisfechos
• 🔄 92% puntualidad

**Datos ambientales:**
• 🌱 CO₂ evitado: 2,500 ton/mes
• ⚡ Buses eléctricos: 12 (10%)
• 🌳 Equivalente: 10,000 árboles

¿Te interesa algún dato específico?
''';
  }

  String _getComparisonResponse(String message) {
    return '''
⚖️ **Comparación de Rutas**

Analizaré las mejores opciones para ti:

**Comparación General de Rutas:**

📊 **Por Velocidad:**
• 🚀 Más rápida: Ruta 1 (menos paradas)
• 🐢 Más lenta: Ruta 6 (más paradas)

💰 **Por Precio:**
• Todas las rutas: \$2,500
• Con tarjeta: \$2,250 (10% desc.)

⏰ **Por Frecuencia:**
• Mejor: Ruta 1 - cada 10 min
• Regular: Ruta 2,3,5 - cada 15 min
• Menor: Ruta 6 - cada 25 min

🚏 **Por Cobertura:**
• Mayor: Ruta 4 (cruza toda la ciudad)
• Menor: Ruta 6 (sector específico)

**¿Qué es más importante para ti?**
• ⚡ Velocidad
• 💰 Economía
• 🕐 Frecuencia
• 📍 Cobertura

Dime tu prioridad y te recomendaré la mejor opción.
''';
  }

  String _getRecommendationResponse(String message) {
    final hour = DateTime.now().hour;
    String recomendacion = '';

    if (hour >= 6 && hour <= 9) {
      recomendacion = '''
🌅 **Recomendaciones para la Hora Pico Matutina:**

✅ Sal 10 minutos antes
✅ Usa la Ruta 1 o 3 (mayor frecuencia)
✅ Evita llevar maletas grandes
✅ Ten el pasaje exacto listo
''';
    } else if (hour >= 17 && hour <= 19) {
      recomendacion = '''
🌆 **Recomendaciones para la Hora Pico Vespertina:**

✅ Considera rutas alternativas
✅ La Ruta 2 suele estar menos congestionada
✅ Espera en paraderos techados
✅ Activa notificaciones de llegada
''';
    } else {
      recomendacion = '''
😌 **Recomendaciones Hora Valle:**

✅ Buen momento para viajar
✅ Buses menos llenos
✅ Tiempos de viaje más cortos
✅ Mayor disponibilidad de asientos
''';
    }

    return '''
🎯 **Mis Recomendaciones Personalizadas**

$recomendacion

**Apps útiles:**
• 📱 Waze - Para ver tráfico
• 🗺️ Google Maps - Rutas alternativas
• ⏰ Alarma - No perder el bus

**Consejos de seguridad:**
• 👀 Mantén tus pertenencias vigiladas
• 📵 Evita mostrar el celular innecesariamente
• 🚪 Espera que el bus se detenga completamente
• 💺 Cede el asiento a quien lo necesite

**Mejores momentos para viajar:**
• 🌤️ 9am - 11am: Poco tráfico
• ☕ 2pm - 4pm: Tranquilo
• 🌙 Después de 8pm: Rápido

¿Necesitas una recomendación específica?
''';
  }

  String _getTarifaResponse(String message) {
    // Buscar ruta específica en el mensaje
    for (String rutaName in _rutasData.keys) {
      if (message.contains(rutaName.toLowerCase())) {
        final tarifa = _rutasData[rutaName]['tarifa'];
        return '''
💰 **Información de Tarifas - $rutaName**

**Tarifa actual:** \$$tarifa

**Descuentos disponibles:**
• 👨‍🎓 Estudiantes: 50% (\$1,250)
• 👴 Adultos mayores: 50% (\$1,250)
• ♿ Personas con discapacidad: 50%
• 💳 Con tarjeta recargable: 10% (\$2,250)

**Pases especiales:**
• 📅 Pase diario: \$15,000 (viajes ilimitados)
• 📅 Pase semanal: \$70,000
• 📅 Pase mensual: \$180,000

**Transbordos:**
• ⏱️ Gratis dentro de 30 minutos (con tarjeta)
• 💵 Sin tarjeta: Tarifa completa

¿Necesitas información sobre descuentos o pases?
''';
      }
    }

    // Respuesta general sobre tarifas
    return '''
💰 **Sistema de Tarifas del Transporte Público**

**Tarifa general:** \$2,500 (todas las rutas)

**Descuentos especiales:**
• 👨‍🎓 Estudiantes: 50% con carnet vigente
• 👴 Adultos mayores (62+): 50%
• ♿ Personas con discapacidad: 50%
• 👶 Niños menores de 5 años: Gratis
• 💳 Pago con tarjeta: 10% descuento

**Opciones de ahorro:**
• 📅 Pase diario: \$15,000
• 📅 Pase semanal: \$70,000
• 📅 Pase mensual: \$180,000
• 📅 Pase estudiantil mensual: \$90,000

**¿Sabías que...?**
Con el pase mensual ahorras hasta 40% si viajas todos los días.

¿Qué tipo de tarifa te interesa?
''';
  }

  String _getHorarioResponse(String message) {
    // Buscar ruta específica
    for (String rutaName in _rutasData.keys) {
      if (message.contains(rutaName.toLowerCase())) {
        final horario = _rutasData[rutaName]['horario'];
        final frecuencia =
            _rutasData[rutaName]['frecuencia'] ?? 'Cada 15 minutos';
        return '''
🕐 **Horarios - $rutaName**

**Horario de servicio:** $horario
**Frecuencia:** $frecuencia

**Primer bus:** ${horario.split(' - ')[0]}
**Último bus:** ${horario.split(' - ')[1]}

**Horarios especiales:**
• 🌅 Hora pico AM: Cada 7 minutos
• 🌆 Hora pico PM: Cada 8 minutos
• 📅 Domingos: Frecuencia reducida 50%
• 🎄 Festivos: Consultar horario especial

💡 **Tip:** En horas pico, espera en paraderos principales para mayor frecuencia.
''';
      }
    }

    // Información general de horarios
    String horariosCompletos = '''
🕐 **Horarios del Sistema de Transporte**

**Horario general de servicio:**
• Lunes a Sábado: 5:00 AM - 10:30 PM
• Domingos y festivos: 6:00 AM - 9:00 PM

**Horarios por ruta:**
''';

    _rutasData.forEach((ruta, datos) {
      horariosCompletos += '\n🚌 **$ruta:**\n';
      horariosCompletos += '   • Horario: ${datos['horario']}\n';
      horariosCompletos +=
          '   • Frecuencia: ${datos['frecuencia'] ?? 'Cada 15 minutos'}\n';
    });

    horariosCompletos += '''

**Horas pico (mayor frecuencia):**
• 🌅 6:30 AM - 8:30 AM
• 🌆 5:00 PM - 7:30 PM

**Servicios especiales:**
• 🎄 Navidad/Año Nuevo: Hasta 2:00 AM
• ⚽ Eventos deportivos: Servicio extendido
• 🎭 Festivales: Rutas adicionales

¿Necesitas el horario de alguna ruta específica?
''';

    return horariosCompletos;
  }

  String _getParaderosResponse(String message) {
    // Buscar si menciona una ruta específica
    for (String rutaName in _rutasData.keys) {
      if (message.contains(rutaName.toLowerCase())) {
        final paraderos = _rutasData[rutaName]['paraderos'] as List;
        String respuesta = '🚏 **Paraderos de la $rutaName:**\n\n';

        for (int i = 0; i < paraderos.length; i++) {
          respuesta += '${i + 1}. 📍 ${paraderos[i]['nombre']}\n';
        }

        respuesta += '\n**Información adicional:**\n';
        respuesta += '• 🕐 Tiempo entre paraderos: 3-5 minutos\n';
        respuesta += '• ♿ Paraderos accesibles marcados con rampa\n';
        respuesta += '• 🚏 Algunos paraderos tienen techo y asientos\n';

        return respuesta;
      }
    }

    // Buscar si menciona un paradero específico
    Map<String, List<String>> paraderoRutas = {};
    _rutasData.forEach((ruta, datos) {
      final paraderos = datos['paraderos'] as List;
      for (var paradero in paraderos) {
        String nombre = paradero['nombre'];
        if (!paraderoRutas.containsKey(nombre)) {
          paraderoRutas[nombre] = [];
        }
        paraderoRutas[nombre]!.add(ruta);
      }
    });

    for (String paraderoNombre in paraderoRutas.keys) {
      if (message.contains(paraderoNombre.toLowerCase())) {
        String respuesta = '🚏 **Paradero: $paraderoNombre**\n\n';
        respuesta += '**Rutas que pasan por aquí:**\n';
        for (String ruta in paraderoRutas[paraderoNombre]!) {
          respuesta += '• 🚌 $ruta\n';
        }
        respuesta += '\n**Servicios en el paradero:**\n';
        respuesta += '• 🪑 Asientos disponibles\n';
        respuesta += '• ☂️ Techo para lluvia\n';
        respuesta += '• 💡 Iluminación nocturna\n';
        respuesta += '• 📱 Información digital (próximamente)\n';

        return respuesta;
      }
    }

    // Respuesta general
    return '''
🚏 **Sistema de Paraderos**

**Paraderos principales con todas las rutas:**
• 📍 Centro - Hub principal
• 📍 Terminal - Conexión intermunicipal
• 📍 Hospital - Zona médica
• 📍 Unillanos - Zona universitaria

**Tipos de paraderos:**
• 🏛️ **Tipo A:** Techado, asientos, información digital
• 🚏 **Tipo B:** Techado, señalización
• 📍 **Tipo C:** Señalización básica

**Mejoras en proceso:**
• 📱 Pantallas con tiempos de llegada
• ♿ 100% accesibilidad para 2025
• 🌳 Zonas verdes y sombra
• 📶 WiFi gratuito en paraderos principales

¿Buscas información de algún paradero específico?
''';
  }

  String _getRutaResponse(String message) {
    // Buscar ruta específica en el mensaje
    for (String rutaName in _rutasData.keys) {
      if (message.contains(rutaName.toLowerCase())) {
        final datos = _rutasData[rutaName];
        final paraderos =
            (datos['paraderos'] as List).map((p) => p['nombre']).join(' → ');

        return '''
🚌 **$rutaName**

📍 **Recorrido:** $paraderos

💰 **Tarifa:** \$${datos['tarifa']}

🕐 **Horario:** ${datos['horario']}

⏱️ **Frecuencia:** ${datos['frecuencia'] ?? 'Cada 15 minutos'}

💡 **Tips para esta ruta:**
• Menos concurrida entre 10am-12pm
• Mayor frecuencia en horas pico
• Buses con aire acondicionado disponibles

¿Necesitas más información sobre esta ruta?
''';
      }
    }

    // Mostrar todas las rutas disponibles
    if (_rutasData.isNotEmpty) {
      String rutasInfo = '🚌 **Rutas disponibles:**\n\n';
      _rutasData.forEach((ruta, datos) {
        rutasInfo += '• $ruta - \$${datos['tarifa']} - ${datos['horario']}\n';
      });
      rutasInfo += '\n¿Te interesa información específica de alguna ruta?';
      return rutasInfo;
    }

    return 'No tengo información de rutas cargada en este momento. 😔';
  }

  String _getIntelligentResponse(String message) {
    // Sistema de respuesta inteligente basado en contexto

    // Verificar si es una pregunta
    if (message.contains('?')) {
      // Analizar tipo de pregunta
      if (_containsAny(message, ['qué', 'que', 'cuál', 'cual'])) {
        return _handleWhatQuestion(message);
      } else if (_containsAny(message, ['cómo', 'como'])) {
        return _handleHowQuestion(message);
      } else if (_containsAny(message, ['dónde', 'donde'])) {
        return _handleWhereQuestion(message);
      } else if (_containsAny(message, ['cuándo', 'cuando'])) {
        return _handleWhenQuestion(message);
      } else if (_containsAny(message, ['por qué', 'porque'])) {
        return _handleWhyQuestion(message);
      }
    }

    // Si no es pregunta, analizar el sentimiento
    if (_containsAny(
        message, ['gracias', 'excelente', 'perfecto', 'genial', 'bueno'])) {
      return '''
😊 ¡Me alegra poder ayudarte!

Si necesitas algo más, aquí estoy para:
• 🗺️ Planificar tu ruta
• 🕐 Consultar horarios
• 💰 Información de tarifas
• 📍 Ubicar paraderos
• 🚌 Estado en tiempo real

¡Que tengas un excelente viaje! 🚌✨
''';
    }

    if (_containsAny(
        message, ['no entiendo', 'confundido', 'no sé', 'ayuda'])) {
      return _getHelpResponse();
    }

    // Respuesta general contextual
    return '''
🤔 Entiendo que necesitas información sobre "$message".

Puedo ayudarte mejor si me das más detalles. Por ejemplo:

**Si buscas una ruta:**
• "¿Cómo llego a [destino]?"
• "¿Qué ruta va a [lugar]?"

**Si necesitas horarios:**
• "¿A qué hora pasa la Ruta X?"
• "¿Hasta qué hora hay servicio?"

**Si es sobre tarifas:**
• "¿Cuánto cuesta el pasaje?"
• "¿Hay descuentos para estudiantes?"

**Otras consultas:**
• Estado del tráfico
• Objetos perdidos
• Quejas o sugerencias

¿Cómo puedo ayudarte específicamente?
''';
  }

  String _handleWhatQuestion(String message) {
    return '''
📋 Aquí está la información que buscas:

Basándome en tu pregunta, puedo ofrecerte:

• 📊 Datos específicos del sistema
• 🚌 Información de rutas
• 💰 Detalles de tarifas
• 🕐 Horarios actualizados
• 📍 Ubicaciones de paraderos

Por favor, sé más específico para darte la información exacta.
''';
  }

  String _handleHowQuestion(String message) {
    return '''
📖 Te explico el proceso:

Para realizar lo que preguntas:

1. Primero identifica tu ubicación actual
2. Selecciona tu destino
3. Elige la ruta más conveniente
4. Verifica horarios y tarifas
5. Dirígete al paradero más cercano

¿Necesitas ayuda con algún paso específico?
''';
  }

  String _handleWhereQuestion(String message) {
    return '''
📍 Información de ubicación:

Puedo ayudarte a encontrar:
• Paraderos cercanos
• Rutas específicas
• Puntos de recarga
• Oficinas de atención

Usa el mapa en la app para ver ubicaciones en tiempo real.

¿Qué ubicación específica necesitas?
''';
  }

  String _handleWhenQuestion(String message) {
    return '''
⏰ Información de tiempos:

Los horarios varían según:
• La ruta específica
• El día de la semana
• Si es festivo o no

Consulta los horarios detallados de cada ruta en la sección de horarios.

¿Qué horario específico necesitas?
''';
  }

  String _handleWhyQuestion(String message) {
    return '''
ℹ️ Explicación:

Las políticas y procedimientos del sistema de transporte buscan:
• Eficiencia en el servicio
• Seguridad de los pasajeros
• Sostenibilidad ambiental
• Accesibilidad universal

Si tienes dudas específicas sobre alguna política, puedes contactar a atención al cliente.
''';
  }

  String _getHelpResponse() {
    return '''
🤖 **¡Hola! Soy tu Asistente Inteligente de Transporte**

Puedo ayudarte con TODO sobre el transporte público:

**🚌 Información de Rutas**
• "¿Qué rutas hay disponibles?"
• "Información de la Ruta X"
• "¿Qué ruta va al Centro?"

**🗺️ Navegación**
• "¿Cómo llego a [destino]?"
• "Ruta más rápida a [lugar]"
• "¿Dónde está el paradero más cercano?"

**💰 Tarifas y Pagos**
• "¿Cuánto cuesta el pasaje?"
• "¿Hay descuentos?"
• "¿Cómo recargo mi tarjeta?"

**🕐 Horarios**
• "¿A qué hora pasa el bus?"
• "Horarios de la Ruta X"
• "¿Hasta qué hora hay servicio?"

**📍 Paraderos**
• "Paraderos de la Ruta X"
• "¿Qué rutas pasan por [paradero]?"
• "Paraderos con techo cerca"

**🕒 Tiempo Real**
• "¿Cuánto falta para que llegue?"
• "¿Dónde está el bus?"
• "Estado del tráfico"

**🆘 Emergencias y Seguridad**
• "Números de emergencia"
• "Reportar un incidente"
• "Hospitales cercanos"

**📝 Quejas y Sugerencias**
• "Quiero hacer una queja"
• "Tengo una sugerencia"
• "Cómo contactar servicio al cliente"

**♿ Accesibilidad**
• "Buses con rampa"
• "Paraderos accesibles"
• "Ayuda para discapacidad"

**📦 Objetos Perdidos**
• "Perdí algo en el bus"
• "Dónde reclamo objetos"

**🌤️ Clima y Transporte**
• "¿Cómo está el clima?"
• "Rutas afectadas por lluvia"

**🎭 Turismo**
• "Cómo llegar a sitios turísticos"
• "Rutas para turistas"

**📊 Estadísticas**
• "Datos del sistema"
• "Rutas más usadas"

¡Pregúntame lo que necesites! Estoy aquí 24/7 para ayudarte 🚌✨
''';
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }
}
