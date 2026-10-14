import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { getDraftWriter } from "@/lib/ai";
import { logActividad } from "@/lib/server/asuntos";
import type { AssistantDocumentContext } from "@/lib/ai/types";

// Genera un borrador de comunicación (reclamación, solicitud...). Nunca se
// envía desde aquí: queda registrado en la cronología del asunto como
// "borrador", pendiente de que el usuario decida enviarlo por su cuenta.
export async function POST(_request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "No autenticado." }, { status: 401 });

  const { data: asunto } = await supabase.from("asuntos").select("*").eq("id", id).eq("user_id", user.id).single();
  if (!asunto) return NextResponse.json({ error: "Asunto no encontrado." }, { status: 404 });

  const { data: links } = await supabase.from("asunto_documentos").select("document_id").eq("asunto_id", id);
  const documentIds = (links ?? []).map((l) => l.document_id);

  let documents: AssistantDocumentContext[] = [];
  if (documentIds.length > 0) {
    const { data: rawDocs } = await supabase
      .from("documents")
      .select("id, original_filename, category, summary, extracted_fields(field_label, field_value)")
      .in("id", documentIds);
    // Sin metadatos de relaciones generados, se castea el join anidado
    // (ver nota en asistente/page.tsx).
    const docs = (rawDocs ?? []) as unknown as {
      id: string;
      original_filename: string;
      category: string;
      summary: string | null;
      extracted_fields: { field_label: string; field_value: string | null }[];
    }[];
    documents = docs.map((d) => ({
      id: d.id,
      filename: d.original_filename,
      category: d.category,
      summary: d.summary,
      fields: (d.extracted_fields ?? []).map((f) => ({ label: f.field_label, value: f.field_value })),
    }));
  }

  const writer = getDraftWriter();
  const result = await writer.draft({ asuntoTitulo: asunto.titulo, asuntoObjetivo: asunto.objetivo, asuntoTipo: asunto.tipo, documents });

  await logActividad(supabase, user.id, id, "borrador_generado", `Borrador preparado: "${result.subject}"`, { subject: result.subject, body: result.body, mode: result.mode });

  return NextResponse.json({ draft: result });
}
