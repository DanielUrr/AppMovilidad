import 'dart:convert';
import 'package:flutter/services.dart';

class ChatbotService {
  Map<String, dynamic> _rutasData = {};
  bool _isLoaded = false;

  Future<void> _loadRutasData() async {
    if (!_isLoaded) {
      try {
        final String jsonString = await rootBundle.loadString('assets/data/rutas.json');
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
    
    final message = userMessage.toLowerCase().trim();
    
    // Respuestas de saludo
    if (_containsAny(message, ['hola', 'buenos días', 'buenas tardes', 'buenas noches', 'hey', 'hi'])) {
      return '¡Hola! 👋 Soy tu asistente de transporte. Puedo ayudarte con información sobre rutas, tarifas y horarios. ¿En qué puedo ayudarte?';
    }
    
    // Respuestas de despedida
    if (_containsAny(message, ['adiós', 'chao', 'bye', 'hasta luego', 'nos vemos'])) {
      return '¡Hasta luego! 👋 Que tengas un buen viaje. Recuerda que siempre puedes volver a preguntarme sobre las rutas.';
    }
    
    // Respuestas sobre tarifas
    if (_containsAny(message, ['tarifa', 'precio', 'cuesta', 'valor', 'pagar'])) {
      return _getTarifaResponse(message);
    }
    
    // Respuestas sobre horarios
    if (_containsAny(message, ['horario', 'hora', 'abre', 'cierra', 'funciona', 'cuando'])) {
      return _getHorarioResponse(message);
    }
    
    // Respuestas sobre paraderos
    if (_containsAny(message, ['paradero', 'parada', 'estación', 'donde', 'dónde', 'pasa'])) {
      return _getParaderosResponse(message);
    }
    
    // Respuestas sobre rutas específicas
    if (_containsAny(message, ['ruta', 'línea', 'bus'])) {
      return _getRutaResponse(message);
    }
    
    // Respuestas de ayuda
    if (_containsAny(message, ['ayuda', 'help', 'qué puedes hacer', 'opciones'])) {
      return _getHelpResponse();
    }
    
    // Respuesta por defecto
    return _getDefaultResponse();
  }

  String _getTarifaResponse(String message) {
    // Buscar ruta específica en el mensaje
    for (String rutaName in _rutasData.keys) {
      if (message.contains(rutaName.toLowerCase())) {
        final tarifa = _rutasData[rutaName]['tarifa'];
        return 'La tarifa de la $rutaName es \$$tarifa pesos. 🚌💰';
      }
    }
    
    // Respuesta general sobre tarifas
    if (_rutasData.isNotEmpty) {
      final tarifaEjemplo = _rutasData.values.first['tarifa'];
      return 'La tarifa general del transporte público es \$$tarifaEjemplo pesos para todas las rutas. 🚌\n\n¿Te gustaría saber sobre alguna ruta en particular?';
    }
    
    return 'La tarifa del transporte público es \$2.500 pesos. 🚌💰';
  }

  String _getHorarioResponse(String message) {
    // Buscar ruta específica en el mensaje
    for (String rutaName in _rutasData.keys) {
      if (message.contains(rutaName.toLowerCase())) {
        final horario = _rutasData[rutaName]['horario'];
        return 'La $rutaName funciona en el horario: $horario 🕐';
      }
    }
    
    // Respuesta general sobre horarios
    if (_rutasData.isNotEmpty) {
      String horarios = 'Los horarios de las rutas son:\n\n';
      _rutasData.forEach((ruta, datos) {
        horarios += '🚌 $ruta: ${datos['horario']}\n';
      });
      return horarios;
    }
    
    return 'Los horarios de servicio son generalmente de 5:00 AM a 10:00 PM. ¿Te interesa alguna ruta en particular? 🕐';
  }

  String _getParaderosResponse(String message) {
    // Buscar ruta específica en el mensaje
    for (String rutaName in _rutasData.keys) {
      if (message.contains(rutaName.toLowerCase())) {
        final paraderos = _rutasData[rutaName]['paraderos'] as List;
        return 'La $rutaName pasa por los siguientes paraderos:\n\n${paraderos.map((p) => '🚏 $p').join('\n')}';
      }
    }
    
    // Buscar paradero específico
    String paraderoBuscado = '';
    for (String rutaName in _rutasData.keys) {
      final paraderos = _rutasData[rutaName]['paraderos'] as List;
      for (String paradero in paraderos) {
        if (message.contains(paradero.toLowerCase())) {
          paraderoBuscado = paradero;
          break;
        }
      }
    }
    
    if (paraderoBuscado.isNotEmpty) {
      List<String> rutasQuePasan = [];
      _rutasData.forEach((ruta, datos) {
        final paraderos = datos['paraderos'] as List;
        if (paraderos.any((p) => p.toLowerCase().contains(paraderoBuscado.toLowerCase()))) {
          rutasQuePasan.add(ruta);
        }
      });
      
      if (rutasQuePasan.isNotEmpty) {
        return 'Por el paradero "$paraderoBuscado" pasan las siguientes rutas:\n\n${rutasQuePasan.map((r) => '🚌 $r').join('\n')}';
      }
    }
    
    // Respuesta general
    return 'Puedo ayudarte con información sobre paraderos. ¿Me podrías decir qué ruta te interesa o qué paradero buscas? 🚏';
  }

  String _getRutaResponse(String message) {
    // Buscar ruta específica en el mensaje
    for (String rutaName in _rutasData.keys) {
      if (message.contains(rutaName.toLowerCase())) {
        final datos = _rutasData[rutaName];
        final paraderos = (datos['paraderos'] as List).join(' → ');
        return '''
🚌 **$rutaName**

📍 **Recorrido:** $paraderos

💰 **Tarifa:** \$${datos['tarifa']}

🕐 **Horario:** ${datos['horario']}
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

  String _getHelpResponse() {
    return '''
¡Hola! Soy tu asistente de transporte. Puedo ayudarte con:

🚌 **Información de rutas**
- "¿Qué rutas hay disponibles?"
- "Información de la Ruta 1"

💰 **Tarifas**
- "¿Cuál es la tarifa de la Ruta 2?"
- "¿Cuánto cuesta el pasaje?"

🕐 **Horarios**
- "¿A qué hora funciona la Ruta 1?"
- "Horarios de servicio"

🚏 **Paraderos**
- "¿Por dónde pasa la Ruta 2?"
- "¿Qué rutas pasan por Centro?"

¡Solo pregúntame lo que necesites saber! 😊
    ''';
  }

  String _getDefaultResponse() {
    final responses = [
      'No estoy seguro de cómo ayudarte con eso. ¿Podrías preguntarme sobre rutas, tarifas u horarios? 🤔',
      'Perdón, no entendí bien tu pregunta. Puedo ayudarte con información sobre transporte público. ¿Qué necesitas saber? 🚌',
      'Hmm, no tengo información sobre eso. ¿Te gustaría saber sobre rutas, paraderos o tarifas? 😊',
      'No comprendo exactamente qué buscas. Escribe "ayuda" para ver qué puedo hacer por ti. 💡',
    ];
    
    return responses[(DateTime.now().millisecondsSinceEpoch % responses.length)];
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }
}