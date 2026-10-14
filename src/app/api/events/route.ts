import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { logActividad } from "@/lib/server/asuntos";
import type { EventPriority, EventType } from "@/lib/db/types";

export async function POST(request: Request) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "No autenticado." }, { status: 401 });

  const body = (await request.json()) as {
    title: string;
    eventType: EventType;
    date: string;
    priority: EventPriority;
    notes?: string;
    asuntoId?: string;
  };

  if (!body.title?.trim() || !body.date) {
    return NextResponse.json({ error: "Título y fecha son obligatorios." }, { status: 400 });
  }

  const { data, error } = await supabase
    .from("events")
    .insert({
      user_id: user.id,
      title: body.title.trim(),
      event_type: body.eventType ?? "manual",
      event_date: body.date,
      date_kind: "explicita",
      priority: body.priority ?? "media",
      notes: body.notes ?? null,
      status: "pendiente",
      asunto_id: body.asuntoId ?? null,
    })
    .select("id")
    .single();

  if (error) return NextResponse.json({ error: error.message }, { status: 400 });

  await supabase.from("audit_log").insert({
    user_id: user.id,
    action: "event_created_manually",
    target_table: "events",
    target_id: data.id,
    metadata: { title: body.title },
  });

  if (body.asuntoId) {
    await logActividad(supabase, user.id, body.asuntoId, "tarea_creada", `Tarea creada: ${body.title.trim()}`, { eventId: data.id });
  }

  return NextResponse.json({ id: data.id });
}
