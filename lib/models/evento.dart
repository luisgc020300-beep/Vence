// lib/models/evento.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum TipoEvento {
  vencimiento,
  renovacion,
  devolucion,
  garantia,
  revision,
  pago,
  manual;

  static TipoEvento parse(String? v) => TipoEvento.values.firstWhere((e) => e.name == v, orElse: () => TipoEvento.manual);

  String get etiqueta => switch (this) {
        TipoEvento.vencimiento => 'Vencimiento',
        TipoEvento.renovacion => 'Renovación',
        TipoEvento.devolucion => 'Devolución',
        TipoEvento.garantia => 'Garantía',
        TipoEvento.revision => 'Revisión',
        TipoEvento.pago => 'Pago',
        TipoEvento.manual => 'Tarea',
      };
}

enum TipoFecha {
  explicita,
  calculada,
  sugerida;

  static TipoFecha parse(String? v) => TipoFecha.values.firstWhere((e) => e.name == v, orElse: () => TipoFecha.sugerida);
}

enum PrioridadEvento {
  alta,
  media,
  baja;

  static PrioridadEvento parse(String? v) => PrioridadEvento.values.firstWhere((e) => e.name == v, orElse: () => PrioridadEvento.media);

  String get etiqueta => switch (this) {
        PrioridadEvento.alta => 'Alta',
        PrioridadEvento.media => 'Media',
        PrioridadEvento.baja => 'Baja',
      };
}

enum EstadoEvento {
  pendiente,
  completada,
  pospuesta,
  cancelada;

  static EstadoEvento parse(String? v) => EstadoEvento.values.firstWhere((e) => e.name == v, orElse: () => EstadoEvento.pendiente);
}

class Evento {
  const Evento({
    required this.id,
    required this.titulo,
    this.documentoId,
    this.asuntoId,
    this.notas,
    this.tipoEvento = TipoEvento.manual,
    required this.fecha,
    this.tipoFecha = TipoFecha.explicita,
    this.prioridad = PrioridadEvento.media,
    this.estado = EstadoEvento.pendiente,
    this.createdAt,
  });

  final String id;
  final String titulo;
  final String? documentoId;
  final String? asuntoId;
  final String? notas;
  final TipoEvento tipoEvento;
  final DateTime fecha;
  final TipoFecha tipoFecha;
  final PrioridadEvento prioridad;
  final EstadoEvento estado;
  final DateTime? createdAt;

  int get diasRestantes {
    final hoy = DateTime.now();
    final h = DateTime(hoy.year, hoy.month, hoy.day);
    final f = DateTime(fecha.year, fecha.month, fecha.day);
    return f.difference(h).inDays;
  }

  factory Evento.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Evento(
      id: doc.id,
      titulo: data['titulo'] as String? ?? '',
      documentoId: data['documentoId'] as String?,
      asuntoId: data['asuntoId'] as String?,
      notas: data['notas'] as String?,
      tipoEvento: TipoEvento.parse(data['tipoEvento'] as String?),
      fecha: (data['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tipoFecha: TipoFecha.parse(data['tipoFecha'] as String?),
      prioridad: PrioridadEvento.parse(data['prioridad'] as String?),
      estado: EstadoEvento.parse(data['estado'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'titulo': titulo,
        if (documentoId != null) 'documentoId': documentoId,
        if (asuntoId != null) 'asuntoId': asuntoId,
        if (notas != null) 'notas': notas,
        'tipoEvento': tipoEvento.name,
        'fecha': Timestamp.fromDate(fecha),
        'tipoFecha': tipoFecha.name,
        'prioridad': prioridad.name,
        'estado': estado.name,
      };
}
