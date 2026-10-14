import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import type { FieldStatus } from "@/lib/db/types";

interface ConfirmBody {
  fields: { id: string; value: string; status: Extract<FieldStatus, "confirmado" | "corregido"> }[];
  approvedEventIndexes: number[];
}

export async function POST(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id: documentId } = await params;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "No autenticado." }, { status: 401 });

  const body = (await request.json()) as ConfirmBody;

  const { data: doc, error: docError } = await supabase
    .from("documents")
    .select("id, pending_events, user_id")
    .eq("id", documentId)
    .single();

  if (docError || !doc || doc.user_id !== user.id) {
    return NextResponse.json({ error: "Documento no encontrado." }, { status: 404 });
  }

  for (const f of body.fields) {
    await supabase
      .from("extracted_fields")
      .update({ field_value: f.value, status: f.status, updated_at: new Date().toISOString() })
      .eq("id", f.id)
      .eq("document_id", documentId);
  }

  const pending = doc.pending_events ?? [];
  const approved = body.approvedEventIndexes.map((i) => pending[i]).filter(Boolean);

  if (approved.length > 0) {
    await supabase.from("events").insert(
      approved.map((e) => ({
        user_id: user.id,
        document_id: documentId,
        title: e.title,
        event_type: e.eventType,
        event_date: e.date,
        date_kind: e.dateKind,
        priority: e.priority,
        notes: e.reason,
        status: "pendiente" as const,
      })),
    );
  }

  await supabase.from("documents").update({ status: "organizado", pending_events: [] }).eq("id", documentId);

  await supabase.from("audit_log").insert({
    user_id: user.id,
    action: "document_confirmed",
    target_table: "documents",
    target_id: documentId,
    metadata: { confirmedFields: body.fields.length, approvedEvents: approved.length },
  });

  return NextResponse.json({ ok: true });
}
