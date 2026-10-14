import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import type { EventStatus } from "@/lib/db/types";

export async function PATCH(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "No autenticado." }, { status: 401 });

  const body = (await request.json()) as { status?: EventStatus; event_date?: string; title?: string; notes?: string };

  const { error } = await supabase.from("events").update(body).eq("id", id).eq("user_id", user.id);
  if (error) return NextResponse.json({ error: error.message }, { status: 400 });

  if (body.status) {
    await supabase.from("audit_log").insert({
      user_id: user.id,
      action: `event_marked_${body.status}`,
      target_table: "events",
      target_id: id,
      metadata: {},
    });
  }

  return NextResponse.json({ ok: true });
}

export async function DELETE(_request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "No autenticado." }, { status: 401 });

  const { error } = await supabase.from("events").delete().eq("id", id).eq("user_id", user.id);
  if (error) return NextResponse.json({ error: error.message }, { status: 400 });
  return NextResponse.json({ ok: true });
}
