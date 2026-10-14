"use client";

import { useState, useRef, useEffect } from "react";
import Link from "next/link";
import { Send, Sparkles, AlertTriangle } from "lucide-react";
import { cn } from "@/lib/utils";

interface Source {
  documentId: string;
  documentName: string;
}

interface Message {
  id: string;
  role: "user" | "assistant";
  content: string;
  isDemo?: boolean;
  confident?: boolean;
  sources: Source[];
}

const SUGGESTIONS = ["¿Qué vence este mes?", "¿Qué tengo pendiente esta semana?", "Resume mis documentos recientes"];

export function AssistantChat({ conversationId: initialConversationId, initialMessages }: { conversationId: string | null; initialMessages: Message[] }) {
  const [conversationId, setConversationId] = useState(initialConversationId);
  const [messages, setMessages] = useState<Message[]>(initialMessages);
  const [input, setInput] = useState("");
  const [sending, setSending] = useState(false);
  const bottomRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  async function send(question: string) {
    if (!question.trim() || sending) return;
    setSending(true);
    setInput("");
    setMessages((m) => [...m, { id: `tmp-${Date.now()}`, role: "user", content: question, sources: [] }]);

    const res = await fetch("/api/assistant", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ question, conversationId }),
    });
    const json = await res.json();
    setSending(false);

    if (!res.ok) {
      setMessages((m) => [...m, { id: `err-${Date.now()}`, role: "assistant", content: json.error ?? "No se ha podido responder.", sources: [] }]);
      return;
    }

    setConversationId(json.conversationId);
    setMessages((m) => [
      ...m,
      {
        id: `a-${Date.now()}`,
        role: "assistant",
        content: json.answer.content,
        isDemo: json.answer.mode === "demo",
        confident: json.answer.confident,
        sources: json.answer.sources.map((s: { documentId: string; documentName: string }) => ({ documentId: s.documentId, documentName: s.documentName })),
      },
    ]);
  }

  return (
    <div className="flex flex-1 flex-col overflow-hidden">
      <div className="flex-1 overflow-y-auto px-5 py-6 md:px-8">
        {messages.length === 0 && (
          <div className="mx-auto max-w-md pt-10 text-center">
            <div className="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-lavanda/20">
              <Sparkles className="h-6 w-6 text-brand" />
            </div>
            <p className="text-sm font-medium text-ink">Pregúntame sobre tus documentos</p>
            <p className="mt-1 text-sm text-ink-muted">Respondo solo con datos reales de lo que tienes guardado, citando la fuente.</p>
            <div className="mt-4 flex flex-wrap justify-center gap-2">
              {SUGGESTIONS.map((s) => (
                <button key={s} onClick={() => send(s)} className="rounded-full border border-borde px-3 py-1.5 text-xs text-ink-muted hover:border-brand/40 hover:text-ink">
                  {s}
                </button>
              ))}
            </div>
          </div>
        )}

        <div className="mx-auto max-w-2xl space-y-4">
          {messages.map((m) => (
            <div key={m.id} className={cn("flex", m.role === "user" ? "justify-end" : "justify-start")}>
              <div className={cn("max-w-[85%] rounded-2xl px-4 py-3 text-sm", m.role === "user" ? "bg-brand text-white" : "border border-borde bg-surface text-ink")}>
                <p className="whitespace-pre-wrap">{m.content}</p>
                {m.role === "assistant" && m.confident === false && (
                  <p className="mt-2 flex items-center gap-1.5 text-xs text-ambar-text">
                    <AlertTriangle className="h-3.5 w-3.5" /> Información insuficiente para estar seguro
                  </p>
                )}
                {m.role === "assistant" && m.isDemo && <p className="mt-2 text-xs text-lavanda">Respuesta en modo demostración (sin IA real configurada)</p>}
                {m.sources.length > 0 && (
                  <div className="mt-2 flex flex-wrap gap-1.5">
                    {m.sources.map((s) => (
                      <Link key={s.documentId} href={`/documentos/${s.documentId}`} className="rounded-full bg-surface-muted px-2.5 py-1 text-xs text-ink-muted hover:text-brand">
                        📄 {s.documentName}
                      </Link>
                    ))}
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
        <div ref={bottomRef} />
      </div>

      <div className="border-t border-borde bg-surface px-5 py-4 md:px-8">
        <form
          onSubmit={(e) => {
            e.preventDefault();
            send(input);
          }}
          className="mx-auto flex max-w-2xl items-center gap-2"
        >
          <input
            value={input}
            onChange={(e) => setInput(e.target.value)}
            placeholder="Escribe tu pregunta..."
            className="flex-1 rounded-xl border border-borde px-3.5 py-2.5 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand/20"
          />
          <button type="submit" disabled={sending} className="flex h-10 w-10 items-center justify-center rounded-xl bg-brand text-white hover:bg-brand-strong disabled:opacity-60">
            <Send className="h-4 w-4" />
          </button>
        </form>
      </div>
    </div>
  );
}
