import { createClient } from "@/lib/supabase/server";
import { PageHeader } from "@/components/ui/page-header";
import { AssistantChat } from "@/components/assistant/chat";

export default async function AsistentePage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;

  const { data: lastConversation } = await supabase
    .from("conversations")
    .select("id")
    .eq("user_id", user.id)
    .order("updated_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  let initialMessages: { id: string; role: "user" | "assistant"; content: string; isDemo: boolean; sources: { documentId: string; documentName: string }[] }[] = [];

  if (lastConversation) {
    const { data: rawMessages } = await supabase
      .from("messages")
      .select("id, role, content, is_demo, message_sources(document_id, documents(original_filename))")
      .eq("conversation_id", lastConversation.id)
      .order("created_at", { ascending: true });

    // Sin metadatos de relaciones generados (no hay proyecto Supabase
    // enlazado todavía), postgrest-js no puede tipar el join anidado —
    // se castea a la forma real que devuelve la consulta.
    const messages = (rawMessages ?? []) as unknown as {
      id: string;
      role: "user" | "assistant";
      content: string;
      is_demo: boolean;
      message_sources: { document_id: string; documents: { original_filename: string } | null }[];
    }[];

    initialMessages = messages.map((m) => ({
      id: m.id,
      role: m.role,
      content: m.content,
      isDemo: m.is_demo,
      sources: (m.message_sources ?? []).map((s) => ({
        documentId: s.document_id,
        documentName: (s.documents as unknown as { original_filename: string } | null)?.original_filename ?? "Documento",
      })),
    }));
  }

  return (
    <div className="flex h-screen flex-col">
      <PageHeader eyebrow="VENCE" title="Asistente" />
      <AssistantChat conversationId={lastConversation?.id ?? null} initialMessages={initialMessages} />
    </div>
  );
}
