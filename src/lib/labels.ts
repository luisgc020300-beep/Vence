import type { DocumentCategory, DocumentStatus, EventType, EventPriority, EventStatus, FieldStatus, DateKind, AsuntoTipo, AsuntoEstado, AsuntoPrioridad } from "@/lib/db/types";

export const ASUNTO_TIPO_LABEL: Record<AsuntoTipo, string> = {
  compra: "Compra",
  devolucion: "Devolución",
  incidencia: "Incidencia",
  poliza: "Póliza",
  contrato: "Contrato",
  documento_personal: "Documento personal",
  gestion: "Gestión",
  otro: "Otro",
};

export const ASUNTO_ESTADO_LABEL: Record<AsuntoEstado, string> = {
  nuevo: "Nuevo",
  necesita_revision: "Necesita revisión",
  en_curso: "En curso",
  pendiente_usuario: "Pendiente de ti",
  pendiente_tercero: "Pendiente de un tercero",
  bloqueado: "Bloqueado",
  listo_para_accion: "Listo para actuar",
  completado: "Completado",
  cerrado: "Cerrado",
  reabierto: "Reabierto",
};

export const ASUNTO_PRIORIDAD_LABEL: Record<AsuntoPrioridad, string> = {
  alta: "Alta",
  media: "Media",
  baja: "Baja",
};

// Transiciones permitidas — evita que la UI ofrezca saltos incoherentes
// (p. ej. de "nuevo" directamente a "cerrado" sin pasar por completado).
export const ASUNTO_TRANSICIONES: Record<AsuntoEstado, AsuntoEstado[]> = {
  nuevo: ["necesita_revision", "en_curso", "bloqueado"],
  necesita_revision: ["en_curso", "bloqueado"],
  en_curso: ["pendiente_usuario", "pendiente_tercero", "bloqueado", "listo_para_accion"],
  pendiente_usuario: ["en_curso", "bloqueado"],
  pendiente_tercero: ["en_curso", "bloqueado"],
  bloqueado: ["en_curso", "pendiente_usuario", "pendiente_tercero"],
  listo_para_accion: ["en_curso", "completado"],
  completado: ["cerrado", "reabierto"],
  cerrado: ["reabierto"],
  reabierto: ["en_curso", "bloqueado"],
};

export const CATEGORY_LABEL: Record<DocumentCategory, string> = {
  factura: "Factura",
  garantia: "Garantía",
  contrato: "Contrato",
  seguro: "Seguro",
  suscripcion: "Suscripción",
  justificante: "Justificante",
  manual_producto: "Manual de producto",
  otro: "Otro",
};

export const DOCUMENT_STATUS_LABEL: Record<DocumentStatus, string> = {
  pendiente_analisis: "Pendiente de analizar",
  analizando: "Analizando",
  en_revision: "Para revisar",
  organizado: "Organizado",
  archivado: "Archivado",
};

export const EVENT_TYPE_LABEL: Record<EventType, string> = {
  vencimiento: "Vencimiento",
  renovacion: "Renovación",
  devolucion: "Devolución",
  garantia: "Garantía",
  revision: "Revisión",
  pago: "Pago",
  manual: "Tarea",
};

export const EVENT_PRIORITY_LABEL: Record<EventPriority, string> = {
  alta: "Alta",
  media: "Media",
  baja: "Baja",
};

export const EVENT_STATUS_LABEL: Record<EventStatus, string> = {
  pendiente: "Pendiente",
  completada: "Completada",
  pospuesta: "Pospuesta",
  cancelada: "Cancelada",
};

export const FIELD_STATUS_LABEL: Record<FieldStatus, string> = {
  detectado: "Detectado por IA",
  confirmado: "Confirmado",
  corregido: "Corregido",
};

export const DATE_KIND_LABEL: Record<DateKind, string> = {
  explicita: "Fecha exacta del documento",
  calculada: "Calculada a partir del documento",
  sugerida: "Sugerencia sin confirmar",
};
