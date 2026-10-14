"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { ArrowLeft, Trash2, FileText, Sparkles, Copy, Plus } from "lucide-react";
import { PageHeader } from "@/components/ui/page-header";
import { Badge } from "@/components/ui/badge";
import { EventRow } from "@/components/events/event-row";
import { NewEventDialog } from "@/components/events/new-event-dialog";
import { UploadDocumentDialog } from "@/components/documents/upload-dialog";
import { ASUNTO_TIPO_LABEL, ASUNTO_ESTADO_LABEL, ASUNTO_TRANSICIONES, CATEGORY_LABEL } from "@/lib/labels";
import { formatDate, cn } from "@/lib/utils";
import type { AsuntoRow, EventRow as EventRowType, AsuntoActividadRow, AsuntoEstado, DocumentCategory } from "@/lib/db/types";

interface DocLink {
  id: string;
  original_filename: string;
  category: string;
  status: string;
  role: "documento" | "evidencia";
}

export function AsuntoDetail({
  asunto,
  documentos,
  events,
  actividad,
}: {
  asunto: AsuntoRow;
  documentos: DocLink[];
  events: EventRowType[];
  actividad: AsuntoActividadRow[];
}) {
  const router = useRouter();
  const [objetivo, setObjetivo] = useState(asunto.objetivo ?? "");
  const [criterioCierre, setCriterioCierre] = useState(asunto.criterio_cierre ?? "");
  const [bloqueoMotivo, setBloqueoMotivo] = useState(asunto.bloqueo_motivo ?? "");
  const [pendingEstado, setPendingEstado] = useState<AsuntoEstado | null>(null);
  const [nota, setNota] = useState("");
  const [uploadOpen, setUploadOpen] = useState<null | "documento" | "evidencia">(null);
  const [draft, setDraft] = useState<{ subject: string; body: string; mode: string } | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const necesitaCriterio = pendingEstado === "completado" || pendingEstado === "cerrado";

  async function patch(body: Record<string, unknown>) {
    setBusy(true);
    setError(null);
    const res = await fetch(`/api/asuntos/${asunto.id}`, { method: "PATCH", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) });
    const json = await res.json().catch(() => ({}));
    setBusy(false);
    if (!res.ok) {
      setError(json.error ?? "No se ha podido guardar.");
      return false;
    }
    router.refresh();
    return true;
  }

  async function confirmEstado() {
    if (!pendingEstado) return;
    const ok = await patch({
      estado: pendingEstado,
      criterioCierre: necesitaCriterio ? criterioCierre : undefined,
      bloqueoMotivo: pendingEstado === "bloqueado" ? bloqueoMotivo : undefined,
    });
    if (ok) setPendingEstado(null);
  }

  async function guardarObjetivo() {
    await patch({ objetivo });
  }

  async function addNota() {
    if (!nota.trim()) return;
    setBusy(true);
    await fetch(`/api/asuntos/${asunto.id}/actividad`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ descripcion: nota.trim() }) });
    setNota("");
    setBusy(false);
    router.refresh();
  }

  async function generarBorrador() {
    setBusy(true);
    setError(null);
    const res = await fetch(`/api/asuntos/${asunto.id}/borrador`, { method: "POST" });
    const json = await res.json();
    setBusy(false);
    if (!res.ok) {
      setError(json.error ?? "No se ha podido generar el borrador.");
      return;
    }
    setDraft(json.draft);
    router.refresh();
  }

  async function eliminar() {
    if (!confirm("¿Eliminar este asunto? Los documentos no se eliminan, solo se desvinculan.")) return;
    await fetch(`/api/asuntos/${asunto.id}`, { method: "DELETE" });
    router.push("/asuntos");
    router.refresh();
  }

  const transiciones = ASUNTO_TRANSICIONES[asunto.estado] ?? [];

  return (
    <div>
      <PageHeader
        eyebrow={ASUNTO_TIPO_LABEL[asunto.tipo]}
        title={asunto.titulo}
        action={
          <button onClick={eliminar} className="flex items-center gap-1.5 rounded-xl border border-borde px-3 py-2 text-xs font-medium text-rojo-text hover:border-rojo/50">
            <Trash2 className="h-3.5 w-3.5" /> Eliminar
          </button>
        }
      />

      <div className="mx-auto max-w-2xl space-y-6 px-5 py-6 md:px-8">
        <Link href="/asuntos" className="inline-flex items-center gap-1.5 text-sm text-ink-muted hover:text-ink">
          <ArrowLeft className="h-4 w-4" /> Volver a asuntos
        </Link>

        <div className="flex flex-wrap items-center gap-2">
          <Badge tone="brand">{ASUNTO_ESTADO_LABEL[asunto.estado]}</Badge>
          {asunto.estado === "bloqueado" && asunto.bloqueo_motivo && <Badge tone="rojo">Bloqueado: {asunto.bloqueo_motivo}</Badge>}
        </div>

        {/* Cambiar de estado */}
        {transiciones.length > 0 && (
          <section className="rounded-2xl border border-borde bg-surface p-4">
            <h2 className="mb-2 text-sm font-semibold text-ink">Avanzar este asunto</h2>
            <div className="flex flex-wrap gap-2">
              {transiciones.map((t) => (
                <button
                  key={t}
                  onClick={() => setPendingEstado(t)}
                  className={cn("rounded-full border px-3 py-1.5 text-xs font-medium", pendingEstado === t ? "border-brand bg-brand/10 text-brand" : "border-borde text-ink-muted hover:border-brand/40")}
                >
                  {ASUNTO_ESTADO_LABEL[t]}
                </button>
              ))}
            </div>

            {pendingEstado && (
              <div className="mt-3 space-y-2 border-t border-borde pt-3">
                {pendingEstado === "bloqueado" && (
                  <input
                    value={bloqueoMotivo}
                    onChange={(e) => setBloqueoMotivo(e.target.value)}
                    placeholder="¿Qué lo está bloqueando?"
                    className="w-full rounded-xl border border-borde px-3.5 py-2.5 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand/20"
                  />
                )}
                {necesitaCriterio && (
                  <div>
                    <p className="mb-1 text-xs text-ink-muted">No se puede {pendingEstado === "cerrado" ? "cerrar" : "completar"} sin indicar qué lo confirma:</p>
                    <input
                      value={criterioCierre}
                      onChange={(e) => setCriterioCierre(e.target.value)}
                      placeholder="p. ej. Reembolso recibido en la cuenta, confirmación por email..."
                      className="w-full rounded-xl border border-borde px-3.5 py-2.5 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand/20"
                    />
                  </div>
                )}
                <div className="flex gap-2">
                  <button onClick={confirmEstado} disabled={busy || (necesitaCriterio && !criterioCierre.trim())} className="rounded-xl bg-brand px-4 py-2 text-sm font-medium text-white hover:bg-brand-strong disabled:opacity-50">
                    Confirmar
                  </button>
                  <button onClick={() => setPendingEstado(null)} className="rounded-xl border border-borde px-4 py-2 text-sm text-ink-muted">
                    Cancelar
                  </button>
                </div>
              </div>
            )}
          </section>
        )}

        {/* Objetivo */}
        <section>
          <h2 className="mb-2 text-sm font-semibold text-ink">Objetivo</h2>
          <textarea
            value={objetivo}
            onChange={(e) => setObjetivo(e.target.value)}
            onBlur={guardarObjetivo}
            placeholder="¿Qué resultado buscas con este asunto?"
            rows={2}
            className="w-full rounded-xl border border-borde bg-surface px-3.5 py-2.5 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand/20"
          />
        </section>

        {/* Documentos */}
        <section>
          <div className="mb-2 flex items-center justify-between">
            <h2 className="text-sm font-semibold text-ink">Documentos y evidencias</h2>
            <div className="flex gap-2">
              <button onClick={() => setUploadOpen("documento")} className="flex items-center gap-1 text-xs font-medium text-brand">
                <Plus className="h-3.5 w-3.5" /> Documento
              </button>
              <button onClick={() => setUploadOpen("evidencia")} className="flex items-center gap-1 text-xs font-medium text-verde">
                <Plus className="h-3.5 w-3.5" /> Evidencia
              </button>
            </div>
          </div>
          {documentos.length === 0 ? (
            <p className="text-sm text-ink-muted">Todavía no hay documentos vinculados a este asunto.</p>
          ) : (
            <div className="space-y-2">
              {documentos.map((d) => (
                <Link key={d.id} href={`/documentos/${d.id}`} className="flex items-center justify-between rounded-2xl border border-borde bg-surface px-4 py-3 hover:border-brand/40">
                  <div className="flex min-w-0 items-center gap-2">
                    <FileText className="h-4 w-4 shrink-0 text-ink-faint" />
                    <span className="truncate text-sm text-ink">{d.original_filename}</span>
                  </div>
                  <div className="flex shrink-0 items-center gap-2">
                    {d.role === "evidencia" && <Badge tone="verde">Evidencia</Badge>}
                    <Badge>{CATEGORY_LABEL[d.category as DocumentCategory]}</Badge>
                  </div>
                </Link>
              ))}
            </div>
          )}
        </section>

        {/* Tareas */}
        <section>
          <div className="mb-2 flex items-center justify-between">
            <h2 className="text-sm font-semibold text-ink">Próximos pasos</h2>
            <NewEventDialog asuntoId={asunto.id} />
          </div>
          {events.length === 0 ? (
            <p className="text-sm text-ink-muted">No hay tareas vinculadas a este asunto todavía.</p>
          ) : (
            <div className="space-y-2">
              {events.map((e) => (
                <EventRow key={e.id} event={e} />
              ))}
            </div>
          )}
        </section>

        {/* Borrador de comunicación */}
        <section>
          <h2 className="mb-2 text-sm font-semibold text-ink">Preparar una comunicación</h2>
          <button onClick={generarBorrador} disabled={busy} className="flex items-center gap-2 rounded-xl border border-borde bg-surface px-4 py-2.5 text-sm font-medium text-ink hover:border-brand/40 disabled:opacity-60">
            <Sparkles className="h-4 w-4 text-brand" /> Generar borrador con IA
          </button>
          {draft && (
            <div className="mt-3 space-y-2 rounded-2xl border border-borde bg-surface p-4">
              {draft.mode === "demo" && <Badge tone="lavanda">Borrador de ejemplo (demo)</Badge>}
              <p className="text-sm font-medium text-ink">{draft.subject}</p>
              <p className="whitespace-pre-wrap text-sm text-ink-muted">{draft.body}</p>
              <button
                onClick={() => navigator.clipboard.writeText(`${draft.subject}\n\n${draft.body}`)}
                className="flex items-center gap-1.5 text-xs font-medium text-brand"
              >
                <Copy className="h-3.5 w-3.5" /> Copiar texto
              </button>
              <p className="text-xs text-ink-faint">Este borrador no se envía solo — revísalo y envíalo tú mismo por tu canal habitual.</p>
            </div>
          )}
        </section>

        {/* Cronología */}
        <section>
          <h2 className="mb-2 text-sm font-semibold text-ink">Cronología</h2>
          <div className="mb-3 flex gap-2">
            <input
              value={nota}
              onChange={(e) => setNota(e.target.value)}
              placeholder="Añadir una nota (p. ej. qué te han respondido)"
              className="flex-1 rounded-xl border border-borde px-3.5 py-2 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand/20"
            />
            <button onClick={addNota} disabled={busy} className="rounded-xl bg-brand px-3.5 py-2 text-sm font-medium text-white hover:bg-brand-strong disabled:opacity-60">
              Añadir
            </button>
          </div>
          <div className="space-y-3 border-l-2 border-borde pl-4">
            {actividad.map((a) => (
              <div key={a.id}>
                <p className="text-sm text-ink">{a.descripcion}</p>
                <p className="text-xs text-ink-faint">{formatDate(a.created_at, { day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" })}</p>
              </div>
            ))}
          </div>
        </section>

        {error && <p className="text-sm text-rojo-text">{error}</p>}
      </div>

      <UploadDocumentDialog open={uploadOpen !== null} onClose={() => setUploadOpen(null)} asuntoId={asunto.id} asuntoRole={uploadOpen ?? "documento"} />
    </div>
  );
}
