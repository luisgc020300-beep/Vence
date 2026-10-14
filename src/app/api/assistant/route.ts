import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { getAssistant } from "@/lib/ai";
import type { AssistantDocumentContext, AssistantEventContext } from "@/lib/ai/types";

export async function POST(request: Request) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "No autenticado." }, { status: 401 });

  const body = (await request.json()) as { question: string; conversationId?: string };
  const question = body.question?.trim();
  if (!question) return NextResponse.json({ error: "Escribe una pregunta." }, { status: 400 });

  let conversationId = body.conversationId;
  if (!conversationId) {
    const { data: conv } = await supabase
      .from("conversations")
      .insert({ user_id: user.id, title: question.slice(0, 60) })
      .select("id")
      .single();
    conversationId = conv?.id;
  }
  if (!conversationId) return NextResponse.json({ error: "No se ha podido crear la conversación." }, { status: 500 });

  await supabase.from("messages").insert({ conversation_id: conversationId, user_id: user.id, role: "user", content: question });

  // Contexto acotado: últimos documentos y eventos del usuario. Sin
  // embeddings todavía — para un archivo grande habría que sustituir esto
  // por una búsqueda semántica real (ver limitaciones en el README).
  const [{ data: rawDocuments }, { data: events }] = await Promise.all([
    supabase
      .from("documents")
      .select("id, original_filename, category, summary, extracted_fields(field_label, field_value)")
      .eq("user_id", user.id)
      .neq("status", "archivado")
      .order("created_at", { ascending: false })
      .limit(40),
    supabase
      .from("events")
      .select("id, title, event_date, event_type, status")
      .eq("user_id", user.id)
      .order("event_date", { ascending: true })
      .limit(60),
  ]);

  // Sin metadatos de relaciones generados, se castea el join anidado a la
  // forma real que devuelve la consulta (ver nota en asistente/page.tsx).
  const documents = (rawDocuments ?? []) as unknown as {
    id: string;
    original_filename: string;
    category: string;
    summary: string | null;
    extracted_fields: { field_label: string; field_value: string | null }[];
  }[];

  const documentContext: AssistantDocumentContext[] = documents.map((d) => ({
    id: d.id,
    filename: d.original_filename,
    category: d.category,
    summary: d.summary,
    fields: (d.extracted_fields ?? []).map((f) => ({ label: f.field_label, value: f.field_value })),
  }));

  const eventContext: AssistantEventContext[] = (events ?? []).map((e) => ({
    id: e.id,
    title: e.title,
    date: e.event_date,
    type: e.event_type,
    status: e.status,
  }));

  const assistant = getAssistant();
  const answer = await assistant.ask(question, { documents: documentContext, events: eventContext });

  const { data: assistantMessage } = await supabase
    .from("messages")
    .insert({ conversation_id: conversationId, user_id: user.id, role: "assistant", content: answer.content, is_demo: answer.mode === "demo" })
    .select("id")
    .single();

  if (assistantMessage && answer.sources.length > 0) {
    await supabase.from("message_sources").insert(
      answer.sources.map((s) => ({
        message_id: assistantMessage.id,
        document_id: s.documentId,
        snippet: s.snippet,
        user_id: user.id,
      })),
    );
  }

  return NextResponse.json({ conversationId, answer });
}
