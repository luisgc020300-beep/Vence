import { notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { AsuntoDetail } from "@/components/asuntos/asunto-detail";

export default async function AsuntoDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;

  const { data: asunto } = await supabase.from("asuntos").select("*").eq("id", id).eq("user_id", user.id).single();
  if (!asunto) notFound();

  const [{ data: rawLinks }, { data: events }, { data: actividad }] = await Promise.all([
    supabase.from("asunto_documentos").select("role, documents(id, original_filename, category, status)").eq("asunto_id", id),
    supabase.from("events").select("*").eq("asunto_id", id).order("event_date", { ascending: true }),
    supabase.from("asunto_actividad").select("*").eq("asunto_id", id).order("created_at", { ascending: false }),
  ]);

  // Sin metadatos de relaciones generados, se castea el join anidado a la
  // forma real que devuelve la consulta (ver nota en asistente/page.tsx).
  const links = (rawLinks ?? []) as unknown as {
    role: "documento" | "evidencia";
    documents: { id: string; original_filename: string; category: string; status: string } | null;
  }[];

  const documentos = links
    .map((l) => ({ ...l.documents, role: l.role }))
    .filter((d): d is { id: string; original_filename: string; category: string; status: string; role: "documento" | "evidencia" } => !!d?.id);

  return <AsuntoDetail asunto={asunto} documentos={documentos} events={events ?? []} actividad={actividad ?? []} />;
}
