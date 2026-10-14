"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Plus, X } from "lucide-react";
import { ASUNTO_TIPO_LABEL } from "@/lib/labels";
import type { AsuntoTipo } from "@/lib/db/types";

const TIPOS = Object.keys(ASUNTO_TIPO_LABEL) as AsuntoTipo[];

export function NewAsuntoDialog({ documentId, label = "Nuevo asunto" }: { documentId?: string; label?: string }) {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [titulo, setTitulo] = useState("");
  const [tipo, setTipo] = useState<AsuntoTipo>("otro");
  const [objetivo, setObjetivo] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function submit() {
    if (!titulo.trim()) {
      setError("Ponle un título al asunto.");
      return;
    }
    setBusy(true);
    setError(null);
    const res = await fetch("/api/asuntos", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ titulo, tipo, objetivo: objetivo || undefined, documentIds: documentId ? [documentId] : [] }),
    });
    const json = await res.json();
    setBusy(false);
    if (!res.ok) {
      setError(json.error ?? "No se ha podido crear el asunto.");
      return;
    }
    setOpen(false);
    router.push(`/asuntos/${json.id}`);
    router.refresh();
  }

  return (
    <>
      <button onClick={() => setOpen(true)} className="flex items-center gap-1.5 rounded-xl bg-brand px-3.5 py-2 text-sm font-medium text-white hover:bg-brand-strong">
        <Plus className="h-4 w-4" /> {label}
      </button>

      {open && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 p-4" onClick={() => setOpen(false)}>
          <div className="w-full max-w-sm rounded-2xl bg-surface p-6" onClick={(e) => e.stopPropagation()}>
            <div className="mb-4 flex items-center justify-between">
              <h2 className="text-base font-semibold text-ink">Nuevo asunto</h2>
              <button onClick={() => setOpen(false)}>
                <X className="h-5 w-5 text-ink-faint" />
              </button>
            </div>
            <div className="space-y-3">
              <input
                value={titulo}
                onChange={(e) => setTitulo(e.target.value)}
                placeholder="p. ej. Lavadora rota, devolución del pedido..."
                className="w-full rounded-xl border border-borde px-3.5 py-2.5 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand/20"
              />
              <select value={tipo} onChange={(e) => setTipo(e.target.value as AsuntoTipo)} className="w-full rounded-xl border border-borde px-3.5 py-2.5 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand/20">
                {TIPOS.map((t) => (
                  <option key={t} value={t}>
                    {ASUNTO_TIPO_LABEL[t]}
                  </option>
                ))}
              </select>
              <textarea
                value={objetivo}
                onChange={(e) => setObjetivo(e.target.value)}
                placeholder="Objetivo (opcional): ¿qué resultado buscas?"
                rows={2}
                className="w-full rounded-xl border border-borde px-3.5 py-2.5 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand/20"
              />
              {error && <p className="text-sm text-rojo-text">{error}</p>}
              <button onClick={submit} disabled={busy} className="w-full rounded-xl bg-brand px-4 py-2.5 text-sm font-medium text-white hover:bg-brand-strong disabled:opacity-60">
                {busy ? "Creando..." : "Crear asunto"}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
