// lib/models/mensaje.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FuenteMensaje {
  const FuenteMensaje({required this.documentoId, required this.nombreDocumento});
  final String documentoId;
  final String nombreDocumento;
}

class Mensaje {
  const Mensaje({
    required this.id,
    required this.rol,
    required this.contenido,
    this.esDemo = false,
    this.confiado,
    this.fuentes = const [],
    this.createdAt,
  });

  final String id;
  final String rol; // user | assistant
  final String contenido;
  final bool esDemo;
  final bool? confiado;
  final List<FuenteMensaje> fuentes;
  final DateTime? createdAt;

  factory Mensaje.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Mensaje(
      id: doc.id,
      rol: data['rol'] as String? ?? 'assistant',
      contenido: data['contenido'] as String? ?? '',
      esDemo: data['esDemo'] as bool? ?? false,
      confiado: data['confiado'] as bool?,
      fuentes: ((data['fuentes'] as List?) ?? [])
          .map((f) => FuenteMensaje(documentoId: f['documentoId'] as String, nombreDocumento: f['nombreDocumento'] as String? ?? 'Documento'))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
