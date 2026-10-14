// lib/services/asunto_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/asunto.dart';
import 'stream_error_logging.dart';

class AsuntoException implements Exception {
  AsuntoException(this.mensaje);
  final String mensaje;
  @override
  String toString() => mensaje;
}

class BorradorComunicacion {
  const BorradorComunicacion({required this.modo, required this.asunto, required this.cuerpo});
  final String modo;
  final String asunto;
  final String cuerpo;
}

class AsuntoService {
  static final _db = FirebaseFirestore.instance;
  static const _region = 'europe-west1';
  static String get _uid => FirebaseAuth.instance.currentUser!.uid;
  static CollectionReference<Map<String, dynamic>> get _col => _db.collection('users').doc(_uid).collection('asuntos');

  static Stream<List<Asunto>> streamAsuntos({bool soloAbiertos = false}) {
    Query<Map<String, dynamic>> q = _col.orderBy('updatedAt', descending: true);
    final stream = q.snapshots().map((s) => s.docs.map(Asunto.fromDoc).toList());
    if (!soloAbiertos) return stream.conRegistroDeErrores();
    return stream.map((lista) => lista.where((a) => a.estado != EstadoAsunto.cerrado).toList()).conRegistroDeErrores();
  }

  static Future<List<Asunto>> obtenerPorIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final docs = await Future.wait(ids.map((id) => _col.doc(id).get()));
    return docs.where((d) => d.exists).map(Asunto.fromDoc).toList();
  }

  static Stream<Asunto?> streamAsunto(String id) {
    return _col.doc(id).snapshots().map((d) => d.exists ? Asunto.fromDoc(d) : null).conRegistroDeErrores();
  }

  static Stream<List<ActividadAsunto>> streamActividad(String asuntoId) {
    return _col
        .doc(asuntoId)
        .collection('actividad')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ActividadAsunto.fromDoc).toList())
        .conRegistroDeErrores();
  }

  static Stream<List<DocumentoVinculado>> streamDocumentosVinculados(String asuntoId) {
    return _col.doc(asuntoId).collection('documentos').snapshots().map(
          (s) => s.docs
              .map((d) => DocumentoVinculado(documentoId: d.id, rol: (d.data())['rol'] as String? ?? 'documento', nombreArchivo: (d.data())['nombreArchivo'] as String?))
              .toList(),
        );
  }

  static Future<void> _log(String asuntoId, String tipo, String descripcion, [Map<String, dynamic>? metadata]) {
    return _col.doc(asuntoId).collection('actividad').add({
      'tipo': tipo,
      'descripcion': descripcion,
      'metadata': metadata ?? {},
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<String> crear({required String titulo, required TipoAsunto tipo, String? objetivo, String? documentoId, String? nombreArchivoDocumento}) async {
    final ref = await _col.add({
      ...Asunto(id: '', titulo: titulo, tipo: tipo, objetivo: objetivo).toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _log(ref.id, 'creado', 'Asunto creado: $titulo');
    if (documentoId != null) {
      await vincularDocumento(ref.id, documentoId, 'documento', nombreArchivo: nombreArchivoDocumento);
    }
    return ref.id;
  }

  static Future<void> vincularDocumento(String asuntoId, String documentoId, String rol, {String? nombreArchivo}) async {
    await _col.doc(asuntoId).collection('documentos').doc(documentoId).set({'rol': rol, 'nombreArchivo': ?nombreArchivo});
    // Índice inverso en el propio documento (en vez de una collection-group
    // query) para poder mostrar "este documento pertenece a X" sin conocer
    // de antemano a qué asunto buscar.
    await _db.collection('users').doc(_uid).collection('documentos').doc(documentoId).update({
      'asuntoIds': FieldValue.arrayUnion([asuntoId]),
    });
    await _log(asuntoId, rol == 'evidencia' ? 'evidencia_anadida' : 'documento_anadido', '${rol == 'evidencia' ? 'Evidencia añadida' : 'Documento añadido'}${nombreArchivo != null ? ': $nombreArchivo' : ''}');
  }

  static Future<void> anadirNota(String asuntoId, String descripcion) => _log(asuntoId, 'nota', descripcion);

  static Future<void> cambiarEstado(String asuntoId, EstadoAsunto actual, EstadoAsunto nuevo, {String? criterioCierre, String? bloqueoMotivo}) async {
    if (!actual.transicionesPermitidas.contains(nuevo)) {
      throw AsuntoException('No se puede pasar de "${actual.etiqueta}" a "${nuevo.etiqueta}" directamente.');
    }
    if ((nuevo == EstadoAsunto.completado || nuevo == EstadoAsunto.cerrado) && (criterioCierre == null || criterioCierre.trim().isEmpty)) {
      throw AsuntoException('Indica el criterio de cierre antes de completar o cerrar el asunto.');
    }

    final data = <String, dynamic>{'estado': nuevo.valor, 'updatedAt': FieldValue.serverTimestamp()};
    if (criterioCierre != null) data['criterioCierre'] = criterioCierre;
    if (nuevo == EstadoAsunto.bloqueado) data['bloqueoMotivo'] = bloqueoMotivo;
    if (nuevo == EstadoAsunto.cerrado) data['cerradoEn'] = FieldValue.serverTimestamp();

    await _col.doc(asuntoId).update(data);
    await _log(asuntoId, 'cambio_estado', 'Estado cambiado de "${actual.etiqueta}" a "${nuevo.etiqueta}"');
  }

  static Future<void> actualizarObjetivo(String asuntoId, String objetivo) {
    return _col.doc(asuntoId).update({'objetivo': objetivo, 'updatedAt': FieldValue.serverTimestamp()});
  }

  static Future<void> eliminar(String asuntoId) => _col.doc(asuntoId).delete();

  static Future<BorradorComunicacion> generarBorrador(Asunto asunto, List<Map<String, dynamic>> documentos) async {
    final callable = FirebaseFunctions.instanceFor(region: _region).httpsCallable('generarBorrador');
    final result = await callable.call({
      'asuntoTitulo': asunto.titulo,
      'asuntoObjetivo': asunto.objetivo,
      'asuntoTipo': asunto.tipo.valor,
      'documents': documentos,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    await _log(asunto.id, 'borrador_generado', 'Borrador preparado: "${data['subject']}"', {'subject': data['subject'], 'mode': data['mode']});
    return BorradorComunicacion(modo: data['mode'] as String, asunto: data['subject'] as String, cuerpo: data['body'] as String);
  }
}
