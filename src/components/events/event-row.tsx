"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import Link from "next/link";
import { Check, Clock3, X } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { EVENT_TYPE_LABEL, EVENT_PRIORITY_LABEL } from "@/lib/labels";
import { formatDate, daysUntil, cn } from "@/lib/utils";
import type { EventRow as EventRowType } from "@/lib/db/types";

export function EventRow({ event, documentId }: { event: EventRowType; documentId?: string }) {
  const router = useRouter();
  const [busy, setBusy] = useState(false);
  const days = daysUntil(event.event_date);

  async function updateStatus(status: "completada" | "pospuesta" | "cancelada") {
    setBusy(true);
    const patch: Record<string, unknown> = { status };
    if (status === "pospuesta") {
      const d = new Date(event.event_date);
      d.setDate(d.getDate() + 7);
      patch.event_date = d.toISOString().slice(0, 10);
      patch.status = "pendiente";
    }
    await fetch(`/api/events/${event.id}`, { method: "PATCH", headers: { "Content-Type": "application/json" }, body: JSON.stringify(patch) });
    setBusy(false);
    router.refresh();
  }

  const isDone = event.status !== "pendiente";

  return (
    <div className={cn("flex items-center justify-between gap-3 rounded-2xl border border-borde bg-surface px-4 py-3.5", isDone && "opacity-60")}>
      <div className="min-w-0">
        <div className="flex items-center gap-2">
          <p className="truncate text-sm font-medium text-ink">{event.title}</p>
          <Badge tone={event.priority === "alta" ? "rojo" : event.priority === "media" ? "ambar" : "neutral"}>{EVENT_PRIORITY_LABEL[event.priority]}</Badge>
        </div>
        <p className="mt-0.5 text-xs text-ink-muted">
          {EVENT_TYPE_LABEL[event.event_type]} · {formatDate(event.event_date)}
          {event.status === "pendiente" && ` · ${days < 0 ? "Atrasado" : days === 0 ? "Hoy" : `en ${days} días`}`}
        </p>
        {documentId && (
          <Link href={`/documentos/${documentId}`} className="mt-0.5 inline-block text-xs text-brand underline">
            Ver documento de origen
          </Link>
        )}
      </div>
      {!isDone && (
        <div className="flex shrink-0 items-center gap-1">
          <button disabled={busy} onClick={() => updateStatus("completada")} aria-label="Completar" className="rounded-full p-2 text-verde hover:bg-verde/10">
            <Check className="h-4 w-4" />
          </button>
          <button disabled={busy} onClick={() => updateStatus("pospuesta")} aria-label="Posponer" className="rounded-full p-2 text-ambar-text hover:bg-ambar/10">
            <Clock3 className="h-4 w-4" />
          </button>
          <button disabled={busy} onClick={() => updateStatus("cancelada")} aria-label="Cancelar" className="rounded-full p-2 text-rojo-text hover:bg-rojo/10">
            <X className="h-4 w-4" />
          </button>
        </div>
      )}
    </div>
  );
}
