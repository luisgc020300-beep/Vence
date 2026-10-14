// lib/services/evento_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/evento.dart';
import 'stream_error_logging.dart';

class EventoService {
  static final _db = FirebaseFirestore.instance;
  static String get _uid => FirebaseAuth.instance.currentUser!.uid;
  static CollectionReference<Map<String, dynamic>> get _col => _db.collection('users').doc(_uid).collection('eventos');

  static Stream<List<Evento>> streamEventos({String? asuntoId, EstadoEvento? estado}) {
    Query<Map<String, dynamic>> q = _col.orderBy('fecha');
    if (estado != null) q = q.where('estado', isEqualTo: estado.name);
    if (asuntoId != null) q = q.where('asuntoId', isEqualTo: asuntoId);
    return q.snapshots().map((s) => s.docs.map(Evento.fromDoc).toList()).conRegistroDeErrores();
  }

  static Future<String> crear(Evento evento) async {
    final ref = await _col.add({...evento.toMap(), 'createdAt': FieldValue.serverTimestamp()});
    return ref.id;
  }

  static Future<void> actualizarEstado(String id, EstadoEvento estado, {DateTime? nuevaFecha}) {
    final data = <String, dynamic>{'estado': estado.name};
    if (nuevaFecha != null) data['fecha'] = Timestamp.fromDate(nuevaFecha);
    return _col.doc(id).update(data);
  }

  static Future<void> posponerUnaSemana(Evento evento) {
    return _col.doc(evento.id).update({'fecha': Timestamp.fromDate(evento.fecha.add(const Duration(days: 7)))});
  }

  static Future<void> eliminar(String id) => _col.doc(id).delete();
}
