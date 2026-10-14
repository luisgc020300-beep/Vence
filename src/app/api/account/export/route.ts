import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function GET() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "No autenticado." }, { status: 401 });

  const [profile, documents, fields, events, entities, conversations, messages] = await Promise.all([
    supabase.from("profiles").select("*").eq("id", user.id).single(),
    supabase.from("documents").select("*").eq("user_id", user.id),
    supabase.from("extracted_fields").select("*").eq("user_id", user.id),
    supabase.from("events").select("*").eq("user_id", user.id),
    supabase.from("entities").select("*").eq("user_id", user.id),
    supabase.from("conversations").select("*").eq("user_id", user.id),
    supabase.from("messages").select("*").eq("user_id", user.id),
  ]);

  const payload = {
    exportado_en: new Date().toISOString(),
    perfil: profile.data,
    documentos: documents.data,
    datos_extraidos: fields.data,
    eventos: events.data,
    entidades: entities.data,
    conversaciones: conversations.data,
    mensajes: messages.data,
  };

  return new NextResponse(JSON.stringify(payload, null, 2), {
    headers: {
      "Content-Type": "application/json",
      "Content-Disposition": `attachment; filename="vence-datos-${user.id}.json"`,
    },
  });
}
