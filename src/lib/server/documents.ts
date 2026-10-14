import { randomUUID } from "crypto";
import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database, DocumentCategory, PendingEventDraft } from "@/lib/db/types";
import { getDocumentAnalyzer } from "@/lib/ai";

const MAX_BYTES = 15 * 1024 * 1024;
const ALLOWED_MIME = new Set(["application/pdf", "image/jpeg", "image/png", "image/webp"]);

export class DocumentUploadError extends Error {}

export async function uploadAndAnalyzeDocument(
  supabase: SupabaseClient<Database>,
  userId: string,
  file: File,
): Promise<{ documentId: string }> {
  if (file.size > MAX_BYTES) {
    throw new DocumentUploadError("El archivo supera el tamaño máximo de 15 MB.");
  }
  if (!ALLOWED_MIME.has(file.type)) {
    throw new DocumentUploadError("Formato no admitido. Sube un PDF o una imagen (JPG, PNG, WEBP).");
  }

  const bytes = Buffer.from(await file.arrayBuffer());
  const storagePath = `${userId}/${randomUUID()}-${sanitizeFilename(file.name)}`;

  const { error: uploadError } = await supabase.storage.from("documents").upload(storagePath, bytes, {
    contentType: file.type,
    upsert: false,
  });
  if (uploadError) {
    throw new DocumentUploadError(`No se ha podido guardar el archivo: ${uploadError.message}`);
  }

  const analyzer = getDocumentAnalyzer();

  const { data: inserted, error: insertError } = await supabase
    .from("documents")
    .insert({
      user_id: userId,
      original_filename: file.name,
      storage_path: storagePath,
      mime_type: file.type,
      size_bytes: file.size,
      status: "analizando",
      analysis_mode: analyzer.mode,
    })
    .select("id")
    .single();

  if (insertError || !inserted) {
    await supabase.storage.from("documents").remove([storagePath]);
    throw new DocumentUploadError(`No se ha podido registrar el documento: ${insertError?.message}`);
  }

  const documentId = inserted.id;

  try {
    const result = await analyzer.analyze({ filename: file.name, mimeType: file.type, bytes });

    const duplicateId = await findPossibleDuplicate(supabase, userId, documentId, file.name, result.category);

    if (result.fields.length > 0) {
      await supabase.from("extracted_fields").insert(
        result.fields.map((f) => ({
          document_id: documentId,
          user_id: userId,
          field_key: f.key,
          field_label: f.label,
          field_value: f.value,
          confidence: f.confidence,
          status: "detectado" as const,
          source: "ia" as const,
        })),
      );
    }

    await supabase
      .from("documents")
      .update({
        category: result.category,
        summary: result.summary,
        status: "en_revision",
        pending_events: result.suggestedEvents satisfies PendingEventDraft[],
        is_duplicate_of: duplicateId,
      })
      .eq("id", documentId);

    await supabase.from("audit_log").insert({
      user_id: userId,
      action: "document_uploaded",
      target_table: "documents",
      target_id: documentId,
      metadata: { filename: file.name, mode: analyzer.mode },
    });
  } catch (err) {
    await supabase
      .from("documents")
      .update({ status: "en_revision", summary: "No se ha podido completar el análisis automático. Añade los datos manualmente." })
      .eq("id", documentId);
    console.error("Error analizando documento", documentId, err);
  }

  return { documentId };
}

export async function createManualDocument(
  supabase: SupabaseClient<Database>,
  userId: string,
  input: { title: string; category: DocumentCategory; fields: { label: string; value: string }[] },
): Promise<{ documentId: string }> {
  const { data: inserted, error } = await supabase
    .from("documents")
    .insert({
      user_id: userId,
      original_filename: input.title,
      category: input.category,
      status: "organizado",
      analysis_mode: "manual",
      summary: `Registrado manualmente: ${input.title}.`,
    })
    .select("id")
    .single();

  if (error || !inserted) {
    throw new DocumentUploadError(`No se ha podido guardar el registro: ${error?.message}`);
  }

  if (input.fields.length > 0) {
    await supabase.from("extracted_fields").insert(
      input.fields
        .filter((f) => f.value.trim().length > 0)
        .map((f) => ({
          document_id: inserted.id,
          user_id: userId,
          field_key: f.label.toLowerCase().replace(/\s+/g, "_"),
          field_label: f.label,
          field_value: f.value,
          status: "confirmado" as const,
          source: "manual" as const,
          confidence: 1,
        })),
    );
  }

  await supabase.from("audit_log").insert({
    user_id: userId,
    action: "document_created_manually",
    target_table: "documents",
    target_id: inserted.id,
    metadata: { title: input.title },
  });

  return { documentId: inserted.id };
}

function sanitizeFilename(name: string) {
  return name.replace(/[^a-zA-Z0-9._-]/g, "_").slice(-120);
}

async function findPossibleDuplicate(
  supabase: SupabaseClient<Database>,
  userId: string,
  excludeId: string,
  filename: string,
  category: DocumentCategory,
) {
  const { data } = await supabase
    .from("documents")
    .select("id")
    .eq("user_id", userId)
    .eq("category", category)
    .eq("original_filename", filename)
    .neq("id", excludeId)
    .limit(1)
    .maybeSingle();

  return data?.id ?? null;
}
