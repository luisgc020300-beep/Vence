import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { changeEstado, AsuntoError } from "@/lib/server/asuntos";
import type { AsuntoEstado } from "@/lib/db/types";

export async function PATCH(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "No autenticado." }, { status: 401 });

  const body = (await request.json()) as {
    estado?: AsuntoEstado;
    criterioCierre?: string;
    bloqueoMotivo?: string;
    titulo?: string;
    objetivo?: string;
  };

  try {
    if (body.estado) {
      await changeEstado(supabase, user.id, id, body.estado, { criterioCierre: body.criterioCierre, bloqueoMotivo: body.bloqueoMotivo });
    }
    if (body.titulo !== undefined || body.objetivo !== undefined || body.criterioCierre !== undefined) {
      const update: Record<string, unknown> = {};
      if (body.titulo !== undefined) update.titulo = body.titulo;
      if (body.objetivo !== undefined) update.objetivo = body.objetivo;
      if (!body.estado && body.criterioCierre !== undefined) update.criterio_cierre = body.criterioCierre;
      if (Object.keys(update).length > 0) {
        await supabase.from("asuntos").update(update).eq("id", id).eq("user_id", user.id);
      }
    }
    return NextResponse.json({ ok: true });
  } catch (err) {
    if (err instanceof AsuntoError) return NextResponse.json({ error: err.message }, { status: 400 });
    console.error(err);
    return NextResponse.json({ error: "Error inesperado." }, { status: 500 });
  }
}

export async function DELETE(_request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "No autenticado." }, { status: 401 });

  const { error } = await supabase.from("asuntos").delete().eq("id", id).eq("user_id", user.id);
  if (error) return NextResponse.json({ error: error.message }, { status: 400 });
  return NextResponse.json({ ok: true });
}
