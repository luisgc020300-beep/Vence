import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { createAsunto, AsuntoError } from "@/lib/server/asuntos";
import type { AsuntoTipo } from "@/lib/db/types";

export async function POST(request: Request) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "No autenticado." }, { status: 401 });

  const body = (await request.json()) as { titulo: string; tipo: AsuntoTipo; objetivo?: string; documentIds?: string[] };
  if (!body.titulo?.trim()) return NextResponse.json({ error: "El título es obligatorio." }, { status: 400 });

  try {
    const id = await createAsunto(supabase, user.id, { titulo: body.titulo.trim(), tipo: body.tipo ?? "otro", objetivo: body.objetivo, documentIds: body.documentIds });
    return NextResponse.json({ id });
  } catch (err) {
    if (err instanceof AsuntoError) return NextResponse.json({ error: err.message }, { status: 400 });
    console.error(err);
    return NextResponse.json({ error: "Error inesperado." }, { status: 500 });
  }
}
