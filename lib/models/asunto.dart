// lib/models/asunto.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum TipoAsunto {
  compra,
  devolucion,
  incidencia,
  poliza,
  contrato,
  documentoPersonal,
  gestion,
  otro;

  String get valor => switch (this) {
        TipoAsunto.documentoPersonal => 'documento_personal',
        _ => name,
      };

  static TipoAsunto parse(String? v) => TipoAsunto.values.firstWhere((e) => e.valor == v, orElse: () => TipoAsunto.otro);

  String get etiqueta => switch (this) {
        TipoAsunto.compra => 'Compra',
        TipoAsunto.devolucion => 'Devolución',
        TipoAsunto.incidencia => 'Incidencia',
        TipoAsunto.poliza => 'Póliza',
        TipoAsunto.contrato => 'Contrato',
        TipoAsunto.documentoPersonal => 'Documento personal',
        TipoAsunto.gestion => 'Gestión',
        TipoAsunto.otro => 'Otro',
      };
}

enum EstadoAsunto {
  nuevo,
  necesitaRevision,
  enCurso,
  pendienteUsuario,
  pendienteTercero,
  bloqueado,
  listoParaAccion,
  completado,
  cerrado,
  reabierto;

  String get valor => switch (this) {
        EstadoAsunto.necesitaRevision => 'necesita_revision',
        EstadoAsunto.enCurso => 'en_curso',
        EstadoAsunto.pendienteUsuario => 'pendiente_usuario',
        EstadoAsunto.pendienteTercero => 'pendiente_tercero',
        EstadoAsunto.listoParaAccion => 'listo_para_accion',
        _ => name,
      };

  static EstadoAsunto parse(String? v) => EstadoAsunto.values.firstWhere((e) => e.valor == v, orElse: () => EstadoAsunto.nuevo);

  String get etiqueta => switch (this) {
        EstadoAsunto.nuevo => 'Nuevo',
        EstadoAsunto.necesitaRevision => 'Necesita revisión',
        EstadoAsunto.enCurso => 'En curso',
        EstadoAsunto.pendienteUsuario => 'Pendiente de ti',
        EstadoAsunto.pendienteTercero => 'Pendiente de un tercero',
        EstadoAsunto.bloqueado => 'Bloqueado',
        EstadoAsunto.listoParaAccion => 'Listo para actuar',
        EstadoAsunto.completado => 'Completado',
        EstadoAsunto.cerrado => 'Cerrado',
        EstadoAsunto.reabierto => 'Reabierto',
      };

  /// Transiciones permitidas -- evita que la UI ofrezca saltos incoherentes.
  List<EstadoAsunto> get transicionesPermitidas => switch (this) {
        EstadoAsunto.nuevo => [EstadoAsunto.necesitaRevision, EstadoAsunto.enCurso, EstadoAsunto.bloqueado],
        EstadoAsunto.necesitaRevision => [EstadoAsunto.enCurso, EstadoAsunto.bloqueado],
        EstadoAsunto.enCurso => [EstadoAsunto.pendienteUsuario, EstadoAsunto.pendienteTercero, EstadoAsunto.bloqueado, EstadoAsunto.listoParaAccion],
        EstadoAsunto.pendienteUsuario => [EstadoAsunto.enCurso, EstadoAsunto.bloqueado],
        EstadoAsunto.pendienteTercero => [EstadoAsunto.enCurso, EstadoAsunto.bloqueado],
        EstadoAsunto.bloqueado => [EstadoAsunto.enCurso, EstadoAsunto.pendienteUsuario, EstadoAsunto.pendienteTercero],
        EstadoAsunto.listoParaAccion => [EstadoAsunto.enCurso, EstadoAsunto.completado],
        EstadoAsunto.completado => [EstadoAsunto.cerrado, EstadoAsunto.reabierto],
        EstadoAsunto.cerrado => [EstadoAsunto.reabierto],
        EstadoAsunto.reabierto => [EstadoAsunto.enCurso, EstadoAsunto.bloqueado],
      };
}

enum PrioridadAsunto {
  alta,
  media,
  baja;

  static PrioridadAsunto parse(String? v) => PrioridadAsunto.values.firstWhere((e) => e.name == v, orElse: () => PrioridadAsunto.media);

  String get etiqueta => switch (this) {
        PrioridadAsunto.alta => 'Alta',
        PrioridadAsunto.media => 'Media',
        PrioridadAsunto.baja => 'Baja',
      };
}

class Asunto {
  const Asunto({
    required this.id,
    required this.titulo,
    this.tipo = TipoAsunto.otro,
    this.objetivo,
    this.estado = EstadoAsunto.nuevo,
    this.prioridad = PrioridadAsunto.media,
    this.bloqueoMotivo,
    this.criterioCierre,
    this.cerradoEn,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String titulo;
  final TipoAsunto tipo;
  final String? objetivo;
  final EstadoAsunto estado;
  final PrioridadAsunto prioridad;
  final String? bloqueoMotivo;
  final String? criterioCierre;
  final DateTime? cerradoEn;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Asunto.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Asunto(
      id: doc.id,
      titulo: data['titulo'] as String? ?? '',
      tipo: TipoAsunto.parse(data['tipo'] as String?),
      objetivo: data['objetivo'] as String?,
      estado: EstadoAsunto.parse(data['estado'] as String?),
      prioridad: PrioridadAsunto.parse(data['prioridad'] as String?),
      bloqueoMotivo: data['bloqueoMotivo'] as String?,
      criterioCierre: data['criterioCierre'] as String?,
      cerradoEn: (data['cerradoEn'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'titulo': titulo,
        'tipo': tipo.valor,
        if (objetivo != null) 'objetivo': objetivo,
        'estado': estado.valor,
        'prioridad': prioridad.name,
        if (bloqueoMotivo != null) 'bloqueoMotivo': bloqueoMotivo,
        if (criterioCierre != null) 'criterioCierre': criterioCierre,
        if (cerradoEn != null) 'cerradoEn': Timestamp.fromDate(cerradoEn!),
      };
}

class DocumentoVinculado {
  const DocumentoVinculado({required this.documentoId, required this.rol, this.nombreArchivo});
  final String documentoId;
  final String rol; // documento | evidencia
  final String? nombreArchivo;
}

class ActividadAsunto {
  const ActividadAsunto({
    required this.id,
    required this.tipo,
    required this.descripcion,
    this.createdAt,
  });

  final String id;
  final String tipo;
  final String descripcion;
  final DateTime? createdAt;

  factory ActividadAsunto.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ActividadAsunto(
      id: doc.id,
      tipo: data['tipo'] as String? ?? '',
      descripcion: data['descripcion'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
