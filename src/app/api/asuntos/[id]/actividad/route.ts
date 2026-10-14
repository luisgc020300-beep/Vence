import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { logActividad } from "@/lib/server/asuntos";

export async function POST(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "No autenticado." }, { status: 401 });

  const body = (await request.json()) as { descripcion: string };
  if (!body.descripcion?.trim()) return NextResponse.json({ error: "Escribe una nota." }, { status: 400 });

  const { data: asunto } = await supabase.from("asuntos").select("id").eq("id", id).eq("user_id", user.id).single();
  if (!asunto) return NextResponse.json({ error: "Asunto no encontrado." }, { status: 404 });

  await logActividad(supabase, user.id, id, "nota", body.descripcion.trim());
  return NextResponse.json({ ok: true });
}
