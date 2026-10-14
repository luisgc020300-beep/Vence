// lib/models/documento.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum CategoriaDocumento {
  factura,
  garantia,
  contrato,
  seguro,
  suscripcion,
  justificante,
  manualProducto,
  otro;

  String get valor => switch (this) {
        CategoriaDocumento.manualProducto => 'manual_producto',
        _ => name,
      };

  static CategoriaDocumento parse(String? v) => CategoriaDocumento.values.firstWhere(
        (e) => e.valor == v,
        orElse: () => CategoriaDocumento.otro,
      );

  String get etiqueta => switch (this) {
        CategoriaDocumento.factura => 'Factura',
        CategoriaDocumento.garantia => 'Garantía',
        CategoriaDocumento.contrato => 'Contrato',
        CategoriaDocumento.seguro => 'Seguro',
        CategoriaDocumento.suscripcion => 'Suscripción',
        CategoriaDocumento.justificante => 'Justificante',
        CategoriaDocumento.manualProducto => 'Manual de producto',
        CategoriaDocumento.otro => 'Otro',
      };
}

enum EstadoDocumento {
  pendienteAnalisis,
  analizando,
  enRevision,
  organizado,
  archivado;

  String get valor => switch (this) {
        EstadoDocumento.pendienteAnalisis => 'pendiente_analisis',
        EstadoDocumento.analizando => 'analizando',
        EstadoDocumento.enRevision => 'en_revision',
        EstadoDocumento.organizado => 'organizado',
        EstadoDocumento.archivado => 'archivado',
      };

  static EstadoDocumento parse(String? v) => EstadoDocumento.values.firstWhere(
        (e) => e.valor == v,
        orElse: () => EstadoDocumento.pendienteAnalisis,
      );

  String get etiqueta => switch (this) {
        EstadoDocumento.pendienteAnalisis => 'Pendiente de analizar',
        EstadoDocumento.analizando => 'Analizando',
        EstadoDocumento.enRevision => 'Para revisar',
        EstadoDocumento.organizado => 'Organizado',
        EstadoDocumento.archivado => 'Archivado',
      };
}

enum ModoAnalisis {
  demo,
  real,
  manual;

  static ModoAnalisis parse(String? v) => ModoAnalisis.values.firstWhere((e) => e.name == v, orElse: () => ModoAnalisis.manual);
}

/// Recordatorio propuesto por el analizador, pendiente de que el usuario lo
/// apruebe o descarte -- se queda como mapa dentro del documento hasta que
/// se confirma, momento en que se vuelca a un Evento real.
class EventoPropuesto {
  const EventoPropuesto({
    required this.titulo,
    required this.tipoEvento,
    required this.fecha,
    required this.tipoFecha,
    required this.prioridad,
    required this.motivo,
  });

  final String titulo;
  final String tipoEvento;
  final String fecha; // ISO yyyy-mm-dd
  final String tipoFecha; // explicita | calculada | sugerida
  final String prioridad;
  final String motivo;

  factory EventoPropuesto.fromMap(Map<String, dynamic> m) => EventoPropuesto(
        titulo: m['titulo'] as String? ?? '',
        tipoEvento: m['tipoEvento'] as String? ?? 'manual',
        fecha: m['fecha'] as String? ?? '',
        tipoFecha: m['tipoFecha'] as String? ?? 'sugerida',
        prioridad: m['prioridad'] as String? ?? 'media',
        motivo: m['motivo'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'titulo': titulo,
        'tipoEvento': tipoEvento,
        'fecha': fecha,
        'tipoFecha': tipoFecha,
        'prioridad': prioridad,
        'motivo': motivo,
      };
}

class Documento {
  const Documento({
    required this.id,
    required this.nombreOriginal,
    this.storagePath,
    this.mimeType,
    this.sizeBytes,
    this.categoria = CategoriaDocumento.otro,
    this.estado = EstadoDocumento.pendienteAnalisis,
    this.modoAnalisis = ModoAnalisis.manual,
    this.resumen,
    this.duplicadoDeId,
    this.eventosPropuestos = const [],
    this.asuntoIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String nombreOriginal;
  final String? storagePath;
  final String? mimeType;
  final int? sizeBytes;
  final CategoriaDocumento categoria;
  final EstadoDocumento estado;
  final ModoAnalisis modoAnalisis;
  final String? resumen;
  final String? duplicadoDeId;
  final List<EventoPropuesto> eventosPropuestos;
  final List<String> asuntoIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Documento.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Documento(
      id: doc.id,
      nombreOriginal: data['nombreOriginal'] as String? ?? '',
      storagePath: data['storagePath'] as String?,
      mimeType: data['mimeType'] as String?,
      sizeBytes: (data['sizeBytes'] as num?)?.toInt(),
      categoria: CategoriaDocumento.parse(data['categoria'] as String?),
      estado: EstadoDocumento.parse(data['estado'] as String?),
      modoAnalisis: ModoAnalisis.parse(data['modoAnalisis'] as String?),
      resumen: data['resumen'] as String?,
      duplicadoDeId: data['duplicadoDeId'] as String?,
      eventosPropuestos: ((data['eventosPropuestos'] as List?) ?? [])
          .map((e) => EventoPropuesto.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      asuntoIds: ((data['asuntoIds'] as List?) ?? []).map((e) => e as String).toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'nombreOriginal': nombreOriginal,
        if (storagePath != null) 'storagePath': storagePath,
        if (mimeType != null) 'mimeType': mimeType,
        if (sizeBytes != null) 'sizeBytes': sizeBytes,
        'categoria': categoria.valor,
        'estado': estado.valor,
        'modoAnalisis': modoAnalisis.name,
        if (resumen != null) 'resumen': resumen,
        if (duplicadoDeId != null) 'duplicadoDeId': duplicadoDeId,
        'eventosPropuestos': eventosPropuestos.map((e) => e.toMap()).toList(),
      };
}

class CampoExtraido {
  const CampoExtraido({
    required this.id,
    required this.clave,
    required this.etiqueta,
    required this.valor,
    this.confianza,
    this.estado = 'detectado',
    this.origen = 'ia',
  });

  final String id;
  final String clave;
  final String etiqueta;
  final String valor;
  final double? confianza;
  final String estado; // detectado | confirmado | corregido
  final String origen; // ia | manual

  factory CampoExtraido.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CampoExtraido(
      id: doc.id,
      clave: data['clave'] as String? ?? '',
      etiqueta: data['etiqueta'] as String? ?? '',
      valor: data['valor'] as String? ?? '',
      confianza: (data['confianza'] as num?)?.toDouble(),
      estado: data['estado'] as String? ?? 'detectado',
      origen: data['origen'] as String? ?? 'ia',
    );
  }

  Map<String, dynamic> toMap() => {
        'clave': clave,
        'etiqueta': etiqueta,
        'valor': valor,
        if (confianza != null) 'confianza': confianza,
        'estado': estado,
        'origen': origen,
      };
}
