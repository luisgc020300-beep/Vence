// Tipos de la base de datos, escritos a mano a partir de
// supabase/migrations/0001_init.sql. Si en el futuro hay un proyecto
// Supabase enlazado, se pueden regenerar con:
//   npx supabase gen types typescript --project-id <id> > src/lib/db/types.ts
// y sustituir este fichero sin tocar el resto del código (el resto de la
// app importa los alias de dominio de este mismo fichero, no los tipos
// Row/Insert/Update en crudo).

export type DocumentStatus = "pendiente_analisis" | "analizando" | "en_revision" | "organizado" | "archivado";
export type DocumentCategory = "factura" | "garantia" | "contrato" | "seguro" | "suscripcion" | "justificante" | "manual_producto" | "otro";
export type AnalysisMode = "demo" | "real" | "manual";
export type FieldStatus = "detectado" | "confirmado" | "corregido";
export type FieldSource = "ia" | "manual";
export type EventType = "vencimiento" | "renovacion" | "devolucion" | "garantia" | "revision" | "pago" | "manual";
export type DateKind = "explicita" | "calculada" | "sugerida";
export type EventPriority = "alta" | "media" | "baja";
export type EventStatus = "pendiente" | "completada" | "pospuesta" | "cancelada";
export type EntityType = "producto" | "proveedor" | "vivienda" | "servicio";
export type MessageRole = "user" | "assistant";

export type AsuntoTipo = "compra" | "devolucion" | "incidencia" | "poliza" | "contrato" | "documento_personal" | "gestion" | "otro";
export type AsuntoEstado =
  | "nuevo"
  | "necesita_revision"
  | "en_curso"
  | "pendiente_usuario"
  | "pendiente_tercero"
  | "bloqueado"
  | "listo_para_accion"
  | "completado"
  | "cerrado"
  | "reabierto";
export type AsuntoPrioridad = "alta" | "media" | "baja";
export type AsuntoDocumentoRole = "documento" | "evidencia";

export interface ProfileRow {
  id: string;
  display_name: string | null;
  locale: string;
  timezone: string;
  notif_email: boolean;
  notif_days_before: number;
  created_at: string;
  updated_at: string;
}

export interface DocumentRow {
  id: string;
  user_id: string;
  original_filename: string;
  storage_path: string | null;
  mime_type: string | null;
  size_bytes: number | null;
  category: DocumentCategory;
  status: DocumentStatus;
  analysis_mode: AnalysisMode;
  summary: string | null;
  raw_text: string | null;
  is_duplicate_of: string | null;
  pending_events: PendingEventDraft[];
  created_at: string;
  updated_at: string;
}

export interface PendingEventDraft {
  title: string;
  eventType: EventType;
  date: string;
  dateKind: DateKind;
  priority: EventPriority;
  reason: string;
}

export interface ExtractedFieldRow {
  id: string;
  document_id: string;
  user_id: string;
  field_key: string;
  field_label: string;
  field_value: string | null;
  confidence: number | null;
  status: FieldStatus;
  source: FieldSource;
  created_at: string;
  updated_at: string;
}

export interface AsuntoRow {
  id: string;
  user_id: string;
  tipo: AsuntoTipo;
  titulo: string;
  objetivo: string | null;
  estado: AsuntoEstado;
  prioridad: AsuntoPrioridad;
  bloqueo_motivo: string | null;
  criterio_cierre: string | null;
  cerrado_en: string | null;
  created_at: string;
  updated_at: string;
}

export interface AsuntoDocumentoRow {
  asunto_id: string;
  document_id: string;
  user_id: string;
  role: AsuntoDocumentoRole;
  created_at: string;
}

export interface AsuntoActividadRow {
  id: string;
  asunto_id: string;
  user_id: string;
  tipo: string;
  descripcion: string;
  metadata: Record<string, unknown>;
  created_at: string;
}

export interface EventRow {
  id: string;
  user_id: string;
  document_id: string | null;
  asunto_id: string | null;
  title: string;
  notes: string | null;
  event_type: EventType;
  event_date: string;
  date_kind: DateKind;
  priority: EventPriority;
  status: EventStatus;
  remind_days_before: number | null;
  created_at: string;
  updated_at: string;
}

export interface EntityRow {
  id: string;
  user_id: string;
  name: string;
  entity_type: EntityType;
  metadata: Record<string, unknown>;
  created_at: string;
}

export interface DocumentRelationRow {
  id: string;
  user_id: string;
  document_id: string;
  related_document_id: string;
  relation_label: string;
  created_at: string;
}

export interface ConversationRow {
  id: string;
  user_id: string;
  title: string;
  created_at: string;
  updated_at: string;
}

export interface MessageRow {
  id: string;
  conversation_id: string;
  user_id: string;
  role: MessageRole;
  content: string;
  is_demo: boolean;
  created_at: string;
}

export interface MessageSourceRow {
  id: string;
  message_id: string;
  document_id: string;
  snippet: string | null;
  user_id: string;
}

export interface AuditLogRow {
  id: string;
  user_id: string;
  action: string;
  target_table: string | null;
  target_id: string | null;
  metadata: Record<string, unknown>;
  created_at: string;
}

// La intersección con Record<string, unknown> es necesaria: postgrest-js
// exige que Row/Insert/Update tengan estructuralmente una firma de índice,
// y una interfaz con campos nombrados no la tiene por sí sola.
type TableDef<Row> = {
  Row: Row & Record<string, unknown>;
  Insert: Partial<Row> & Record<string, unknown>;
  Update: Partial<Row> & Record<string, unknown>;
  Relationships: [];
};

export interface Database {
  public: {
    Tables: {
      profiles: TableDef<ProfileRow>;
      documents: TableDef<DocumentRow>;
      extracted_fields: TableDef<ExtractedFieldRow>;
      events: TableDef<EventRow>;
      entities: TableDef<EntityRow>;
      document_entities: TableDef<{ document_id: string; entity_id: string }>;
      document_relations: TableDef<DocumentRelationRow>;
      conversations: TableDef<ConversationRow>;
      messages: TableDef<MessageRow>;
      message_sources: TableDef<MessageSourceRow>;
      audit_log: TableDef<AuditLogRow>;
      asuntos: TableDef<AsuntoRow>;
      asunto_documentos: TableDef<AsuntoDocumentoRow>;
      asunto_actividad: TableDef<AsuntoActividadRow>;
    };
    Views: Record<string, never>;
    Functions: Record<string, never>;
    Enums: Record<string, never>;
    CompositeTypes: Record<string, never>;
  };
}
