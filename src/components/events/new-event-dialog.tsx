"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Plus, X } from "lucide-react";
import { EVENT_TYPE_LABEL, EVENT_PRIORITY_LABEL } from "@/lib/labels";
import type { EventPriority, EventType } from "@/lib/db/types";

const TYPES = Object.keys(EVENT_TYPE_LABEL) as EventType[];
const PRIORITIES = Object.keys(EVENT_PRIORITY_LABEL) as EventPriority[];

export function NewEventDialog({ asuntoId }: { asuntoId?: string } = {}) {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [title, setTitle] = useState("");
  const [date, setDate] = useState("");
  const [eventType, setEventType] = useState<EventType>("manual");
  const [priority, setPriority] = useState<EventPriority>("media");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function submit() {
    if (!title.trim() || !date) {
      setError("Título y fecha son obligatorios.");
      return;
    }
    setBusy(true);
    const res = await fetch("/api/events", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ title, date, eventType, priority, asuntoId }),
    });
    setBusy(false);
    if (!res.ok) {
      setError("No se ha podido crear la tarea.");
      return;
    }
    setOpen(false);
    setTitle("");
    setDate("");
    router.refresh();
  }

  return (
    <>
      <button onClick={() => setOpen(true)} className="flex items-center gap-1.5 rounded-xl bg-brand px-3.5 py-2 text-sm font-medium text-white hover:bg-brand-strong">
        <Plus className="h-4 w-4" /> Nueva tarea
      </button>

      {open && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 p-4" onClick={() => setOpen(false)}>
          <div className="w-full max-w-sm rounded-2xl bg-surface p-6" onClick={(e) => e.stopPropagation()}>
            <div className="mb-4 flex items-center justify-between">
              <h2 className="text-base font-semibold text-ink">Nueva tarea o recordatorio</h2>
              <button onClick={() => setOpen(false)}>
                <X className="h-5 w-5 text-ink-faint" />
              </button>
            </div>
            <div className="space-y-3">
              <input
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="Título"
                className="w-full rounded-xl border border-borde px-3.5 py-2.5 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand/20"
              />
              <input
                type="date"
                value={date}
                onChange={(e) => setDate(e.target.value)}
                className="w-full rounded-xl border border-borde px-3.5 py-2.5 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand/20"
              />
              <select value={eventType} onChange={(e) => setEventType(e.target.value as EventType)} className="w-full rounded-xl border border-borde px-3.5 py-2.5 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand/20">
                {TYPES.map((t) => (
                  <option key={t} value={t}>
                    {EVENT_TYPE_LABEL[t]}
                  </option>
                ))}
              </select>
              <select value={priority} onChange={(e) => setPriority(e.target.value as EventPriority)} className="w-full rounded-xl border border-borde px-3.5 py-2.5 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand/20">
                {PRIORITIES.map((p) => (
                  <option key={p} value={p}>
                    Prioridad {EVENT_PRIORITY_LABEL[p].toLowerCase()}
                  </option>
                ))}
              </select>
              {error && <p className="text-sm text-rojo-text">{error}</p>}
              <button onClick={submit} disabled={busy} className="w-full rounded-xl bg-brand px-4 py-2.5 text-sm font-medium text-white hover:bg-brand-strong disabled:opacity-60">
                {busy ? "Creando..." : "Crear"}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
