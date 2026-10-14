import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database, AsuntoEstado, AsuntoTipo, AsuntoDocumentoRole } from "@/lib/db/types";
import { ASUNTO_TRANSICIONES } from "@/lib/labels";

export class AsuntoError extends Error {}

export async function logActividad(
  supabase: SupabaseClient<Database>,
  userId: string,
  asuntoId: string,
  tipo: string,
  descripcion: string,
  metadata: Record<string, unknown> = {},
) {
  await supabase.from("asunto_actividad").insert({ asunto_id: asuntoId, user_id: userId, tipo, descripcion, metadata });
}

export async function createAsunto(
  supabase: SupabaseClient<Database>,
  userId: string,
  input: { titulo: string; tipo: AsuntoTipo; objetivo?: string | null; documentIds?: string[] },
) {
  const { data, error } = await supabase
    .from("asuntos")
    .insert({ user_id: userId, titulo: input.titulo, tipo: input.tipo, objetivo: input.objetivo ?? null })
    .select("id")
    .single();

  if (error || !data) throw new AsuntoError(error?.message ?? "No se ha podido crear el asunto.");

  await logActividad(supabase, userId, data.id, "creado", `Asunto creado: ${input.titulo}`);

  for (const documentId of input.documentIds ?? []) {
    await linkDocument(supabase, userId, data.id, documentId, "documento");
  }

  return data.id;
}

export async function linkDocument(
  supabase: SupabaseClient<Database>,
  userId: string,
  asuntoId: string,
  documentId: string,
  role: AsuntoDocumentoRole,
) {
  const { error } = await supabase.from("asunto_documentos").insert({ asunto_id: asuntoId, document_id: documentId, user_id: userId, role });
  if (error) throw new AsuntoError(error.message);

  const { data: doc } = await supabase.from("documents").select("original_filename").eq("id", documentId).single();
  await logActividad(
    supabase,
    userId,
    asuntoId,
    role === "evidencia" ? "evidencia_anadida" : "documento_anadido",
    `${role === "evidencia" ? "Evidencia añadida" : "Documento añadido"}: ${doc?.original_filename ?? documentId}`,
    { documentId },
  );
}

export async function changeEstado(
  supabase: SupabaseClient<Database>,
  userId: string,
  asuntoId: string,
  nuevoEstado: AsuntoEstado,
  opts: { criterioCierre?: string; bloqueoMotivo?: string } = {},
) {
  const { data: asunto, error: fetchError } = await supabase.from("asuntos").select("estado, criterio_cierre").eq("id", asuntoId).eq("user_id", userId).single();
  if (fetchError || !asunto) throw new AsuntoError("Asunto no encontrado.");

  const permitido = ASUNTO_TRANSICIONES[asunto.estado]?.includes(nuevoEstado);
  if (!permitido) {
    throw new AsuntoError(`No se puede pasar de "${asunto.estado}" a "${nuevoEstado}" directamente.`);
  }

  if ((nuevoEstado === "completado" || nuevoEstado === "cerrado") && !(opts.criterioCierre ?? asunto.criterio_cierre)) {
    throw new AsuntoError("Indica el criterio de cierre antes de completar o cerrar el asunto.");
  }

  const update: Record<string, unknown> = { estado: nuevoEstado };
  if (opts.criterioCierre) update.criterio_cierre = opts.criterioCierre;
  if (nuevoEstado === "bloqueado") update.bloqueo_motivo = opts.bloqueoMotivo ?? null;
  if (nuevoEstado === "cerrado") update.cerrado_en = new Date().toISOString();

  const { error } = await supabase.from("asuntos").update(update).eq("id", asuntoId).eq("user_id", userId);
  if (error) throw new AsuntoError(error.message);
  // El cambio de estado ya queda registrado en asunto_actividad por el
  // trigger de Postgres (check_asunto_cierre) — no se duplica aquí.
}
