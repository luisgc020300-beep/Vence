// lib/services/asistente_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/mensaje.dart';
import 'stream_error_logging.dart';

class AsistenteService {
  static final _db = FirebaseFirestore.instance;
  static const _region = 'europe-west1';
  static String get _uid => FirebaseAuth.instance.currentUser!.uid;
  static CollectionReference<Map<String, dynamic>> get _conversaciones => _db.collection('users').doc(_uid).collection('conversaciones');

  static Future<String?> ultimaConversacionId() async {
    final snap = await _conversaciones.orderBy('updatedAt', descending: true).limit(1).get();
    return snap.docs.isEmpty ? null : snap.docs.first.id;
  }

  static Stream<List<Mensaje>> streamMensajes(String conversacionId) {
    return _conversaciones
        .doc(conversacionId)
        .collection('mensajes')
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs.map(Mensaje.fromDoc).toList())
        .conRegistroDeErrores();
  }

  /// Contexto acotado: últimos documentos/eventos del usuario (sin
  /// embeddings todavía -- ver limitaciones en el README).
  static Future<Map<String, dynamic>> _contexto() async {
    final docsSnap = await _db
        .collection('users')
        .doc(_uid)
        .collection('documentos')
        .where('estado', isNotEqualTo: 'archivado')
        .orderBy('estado')
        .orderBy('createdAt', descending: true)
        .limit(40)
        .get();

    final documentos = <Map<String, dynamic>>[];
    for (final d in docsSnap.docs) {
      final camposSnap = await d.reference.collection('campos').get();
      documentos.add({
        'id': d.id,
        'filename': d.data()['nombreOriginal'],
        'category': d.data()['categoria'],
        'summary': d.data()['resumen'],
        'fields': camposSnap.docs.map((c) => {'label': c.data()['etiqueta'], 'value': c.data()['valor']}).toList(),
      });
    }

    final eventosSnap = await _db.collection('users').doc(_uid).collection('eventos').orderBy('fecha').limit(60).get();
    final eventos = eventosSnap.docs
        .map((e) => {
              'id': e.id,
              'title': e.data()['titulo'],
              'date': (e.data()['fecha'] as Timestamp).toDate().toIso8601String().substring(0, 10),
              'type': e.data()['tipoEvento'],
              'status': e.data()['estado'],
            })
        .toList();

    return {'documents': documentos, 'events': eventos};
  }

  static Future<String> preguntar(String pregunta, String? conversacionId) async {
    String convId = conversacionId ?? (await _conversaciones.add({'titulo': pregunta.substring(0, pregunta.length > 60 ? 60 : pregunta.length), 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()})).id;

    final mensajesCol = _conversaciones.doc(convId).collection('mensajes');
    await mensajesCol.add({'rol': 'user', 'contenido': pregunta, 'createdAt': FieldValue.serverTimestamp()});

    final contexto = await _contexto();
    final callable = FirebaseFunctions.instanceFor(region: _region).httpsCallable('pedirAsistente');
    final result = await callable.call({'question': pregunta, 'documents': contexto['documents'], 'events': contexto['events']});
    final data = Map<String, dynamic>.from(result.data as Map);

    await mensajesCol.add({
      'rol': 'assistant',
      'contenido': data['content'],
      'esDemo': data['mode'] == 'demo',
      'confiado': data['confident'],
      'fuentes': (data['sources'] as List? ?? [])
          .map((s) => {'documentoId': s['documentId'], 'nombreDocumento': s['documentName']})
          .toList(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _conversaciones.doc(convId).update({'updatedAt': FieldValue.serverTimestamp()});
    return convId;
  }
}
