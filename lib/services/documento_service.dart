// lib/services/documento_service.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/documento.dart';
import 'stream_error_logging.dart';

class DocumentoUploadException implements Exception {
  DocumentoUploadException(this.mensaje);
  final String mensaje;
  @override
  String toString() => mensaje;
}

class DocumentoService {
  static final _db = FirebaseFirestore.instance;
  static const _region = 'europe-west1';
  static const _maxBytes = 15 * 1024 * 1024;
  static const _mimePermitidos = {'application/pdf', 'image/jpeg', 'image/png', 'image/webp'};

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  static CollectionReference<Map<String, dynamic>> get _col => _db.collection('users').doc(_uid).collection('documentos');

  static Stream<List<Documento>> streamDocumentos({EstadoDocumento? estado}) {
    Query<Map<String, dynamic>> q = _col.orderBy('createdAt', descending: true);
    if (estado != null) q = q.where('estado', isEqualTo: estado.valor);
    return q.snapshots().map((s) => s.docs.map(Documento.fromDoc).toList()).conRegistroDeErrores();
  }

  static Stream<Documento?> streamDocumento(String id) {
    return _col.doc(id).snapshots().map((d) => d.exists ? Documento.fromDoc(d) : null).conRegistroDeErrores();
  }

  static Stream<List<CampoExtraido>> streamCampos(String documentoId) {
    return _col
        .doc(documentoId)
        .collection('campos')
        .orderBy('clave')
        .snapshots()
        .map((s) => s.docs.map(CampoExtraido.fromDoc).toList())
        .conRegistroDeErrores();
  }

  /// Sube el archivo, crea el documento y lanza el análisis (real si hay
  /// clave de Anthropic en el servidor, demo determinista si no la hay --
  /// la decisión es siempre de la Cloud Function, nunca del cliente).
  static Future<String> subirYAnalizar(File file, String filename, String mimeType, int sizeBytes) async {
    if (sizeBytes > _maxBytes) throw DocumentoUploadException('El archivo supera el tamaño máximo de 15 MB.');
    if (!_mimePermitidos.contains(mimeType)) {
      throw DocumentoUploadException('Formato no admitido. Sube un PDF o una imagen (JPG, PNG, WEBP).');
    }

    final storagePath = 'users/$_uid/documentos/${DateTime.now().millisecondsSinceEpoch}-$filename';
    final ref = FirebaseStorage.instance.ref(storagePath);
    await ref.putFile(file, SettableMetadata(contentType: mimeType));

    final docRef = await _col.add(
      Documento(id: '', nombreOriginal: filename, storagePath: storagePath, mimeType: mimeType, sizeBytes: sizeBytes, estado: EstadoDocumento.analizando)
          .toMap()
        ..addAll({'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()}),
    );

    try {
      final callable = FirebaseFunctions.instanceFor(region: _region).httpsCallable('analizarDocumento');
      final result = await callable.call({'storagePath': storagePath, 'filename': filename, 'mimeType': mimeType});
      final data = Map<String, dynamic>.from(result.data as Map);

      final fields = (data['fields'] as List? ?? []);
      for (final f in fields) {
        final m = Map<String, dynamic>.from(f as Map);
        await docRef.collection('campos').add({
          'clave': m['key'],
          'etiqueta': m['label'],
          'valor': m['value'],
          'confianza': m['confidence'],
          'estado': 'detectado',
          'origen': 'ia',
        });
      }

      await docRef.update({
        'categoria': data['category'],
        'resumen': data['summary'],
        'estado': EstadoDocumento.enRevision.valor,
        'modoAnalisis': data['mode'],
        'eventosPropuestos': (data['suggestedEvents'] as List? ?? [])
            .map((e) => {
                  'titulo': e['title'],
                  'tipoEvento': e['eventType'],
                  'fecha': e['date'],
                  'tipoFecha': e['dateKind'],
                  'prioridad': e['priority'],
                  'motivo': e['reason'],
                })
            .toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      await docRef.update({
        'estado': EstadoDocumento.enRevision.valor,
        'resumen': 'No se ha podido completar el análisis automático. Añade los datos manualmente.',
      });
    }

    return docRef.id;
  }

  static Future<String> crearManual({required String titulo, required CategoriaDocumento categoria, required Map<String, String> campos}) async {
    final docRef = await _col.add({
      ...Documento(id: '', nombreOriginal: titulo, categoria: categoria, estado: EstadoDocumento.organizado, modoAnalisis: ModoAnalisis.manual, resumen: 'Registrado manualmente: $titulo.')
          .toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    for (final entry in campos.entries) {
      if (entry.value.trim().isEmpty) continue;
      await docRef.collection('campos').add({
        'clave': entry.key.toLowerCase().replaceAll(RegExp(r'\s+'), '_'),
        'etiqueta': entry.key,
        'valor': entry.value,
        'confianza': 1.0,
        'estado': 'confirmado',
        'origen': 'manual',
      });
    }

    return docRef.id;
  }

  static Future<void> confirmarCampo(String documentoId, String campoId, String valor, String estado) {
    return _col.doc(documentoId).collection('campos').doc(campoId).update({'valor': valor, 'estado': estado});
  }

  static Future<void> aprobarEventosYOrganizar(String documentoId, List<int> indicesAprobados, List<EventoPropuesto> propuestos) async {
    final batch = _db.batch();
    final eventosCol = _db.collection('users').doc(_uid).collection('eventos');

    for (final i in indicesAprobados) {
      final e = propuestos[i];
      final ref = eventosCol.doc();
      batch.set(ref, {
        'titulo': e.titulo,
        'tipoEvento': e.tipoEvento,
        'fecha': Timestamp.fromDate(DateTime.parse(e.fecha)),
        'tipoFecha': e.tipoFecha,
        'prioridad': e.prioridad,
        'notas': e.motivo,
        'estado': 'pendiente',
        'documentoId': documentoId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    batch.update(_col.doc(documentoId), {'estado': EstadoDocumento.organizado.valor, 'eventosPropuestos': [], 'updatedAt': FieldValue.serverTimestamp()});
    await batch.commit();
  }

  static Future<void> eliminar(String documentoId, String? storagePath) async {
    if (storagePath != null) {
      try {
        await FirebaseStorage.instance.ref(storagePath).delete();
      } catch (_) {}
    }
    await _col.doc(documentoId).delete();
  }
}
