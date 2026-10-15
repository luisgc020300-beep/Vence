// lib/services/analytics_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';

/// Envoltorio fino sobre Firebase Analytics -- taxonomía mínima para saber
/// si la gente llega a usar de verdad el motor de Asuntos y el asistente,
/// o se queda en subir documentos sueltos. Sin texto libre del usuario ni
/// PII como parámetro.
class AnalyticsService {
  AnalyticsService._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> documentoSubido({required String categoria}) {
    return _analytics.logEvent(name: 'documento_subido', parameters: {'categoria': categoria});
  }

  static Future<void> asuntoCreado({required String tipo}) {
    return _analytics.logEvent(name: 'asunto_creado', parameters: {'tipo': tipo});
  }

  static Future<void> asuntoCerrado() {
    return _analytics.logEvent(name: 'asunto_cerrado');
  }

  static Future<void> preguntaAsistente() {
    return _analytics.logEvent(name: 'pregunta_asistente');
  }

  static Future<void> borradorGenerado() {
    return _analytics.logEvent(name: 'borrador_generado');
  }
}
