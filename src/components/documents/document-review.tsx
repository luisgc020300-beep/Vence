"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import Link from "next/link";
import { ArrowLeft, Trash2, ExternalLink, CheckCircle2, Briefcase } from "lucide-react";
import { PageHeader } from "@/components/ui/page-header";
import { Badge, ConfidenceBadge } from "@/components/ui/badge";
import { CATEGORY_LABEL, EVENT_TYPE_LABEL, DATE_KIND_LABEL, DOCUMENT_STATUS_LABEL, ASUNTO_ESTADO_LABEL } from "@/lib/labels";
import { NewAsuntoDialog } from "@/components/asuntos/new-asunto-dialog";
import { formatDate } from "@/lib/utils";
import type { DocumentRow, ExtractedFieldRow, AsuntoEstado } from "@/lib/db/types";

export function DocumentReview({
  document,
  fields,
  fileUrl,
  duplicateOf,
  asuntos,
}: {
  document: DocumentRow;
  fields: ExtractedFieldRow[];
  fileUrl: string | null;
  duplicateOf: { id: string; original_filename: string } | null;
  asuntos: { id: string; titulo: string; estado: string }[];
}) {
  const router = useRouter();
  const [values, setValues] = useState<Record<string, string>>(Object.fromEntries(fields.map((f) => [f.id, f.field_value ?? ""])));
  const [approvedEvents, setApprovedEvents] = useState<Set<number>>(new Set(document.pending_events.map((_, i) => i)));
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const isDemo = document.analysis_mode === "demo";
  const needsReview = document.status === "en_revision";

  async function handleDelete() {
    if (!confirm("¿Eliminar este documento? Esta acción no se puede deshacer.")) return;
    await fetch(`/api/documents/${document.id}`, { method: "DELETE" });
    router.push("/documentos");
    router.refresh();
  }

  async function handleConfirm() {
    setSaving(true);
    setError(null);
    const payload = {
      fields: fields.map((f) => ({
        id: f.id,
        value: values[f.id] ?? "",
        status: (values[f.id] ?? "") !== (f.field_value ?? "") ? ("corregido" as const) : ("confirmado" as const),
      })),
      approvedEventIndexes: Array.from(approvedEvents),
    };
    const res = await fetch(`/api/documents/${document.id}/confirm`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    setSaving(false);
    if (!res.ok) {
      const json = await res.json().catch(() => ({}));
      setError(json.error ?? "No se ha podido guardar.");
      return;
    }
    router.refresh();
  }

  return (
    <div>
      <PageHeader
        eyebrow="DOCUMENTO"
        title={document.original_filename}
        action={
          <div className="flex items-center gap-2">
            {fileUrl && (
              <a href={fileUrl} target="_blank" rel="noreferrer" className="flex items-center gap-1.5 rounded-xl border border-borde px-3 py-2 text-xs font-medium text-ink-muted hover:border-brand/40 hover:text-ink">
                <ExternalLink className="h-3.5 w-3.5" /> Ver original
              </a>
            )}
            <button onClick={handleDelete} className="flex items-center gap-1.5 rounded-xl border border-borde px-3 py-2 text-xs font-medium text-rojo-text hover:border-rojo/50">
              <Trash2 className="h-3.5 w-3.5" /> Eliminar
            </button>
          </div>
        }
      />

      <div className="mx-auto max-w-2xl space-y-6 px-5 py-6 md:px-8">
        <Link href="/documentos" className="inline-flex items-center gap-1.5 text-sm text-ink-muted hover:text-ink">
          <ArrowLeft className="h-4 w-4" /> Volver a documentos
        </Link>

        <div className="flex flex-wrap items-center gap-2">
          <Badge tone="brand">{CATEGORY_LABEL[document.category]}</Badge>
          <Badge>{DOCUMENT_STATUS_LABEL[document.status]}</Badge>
          {isDemo && <Badge tone="lavanda">Analizado en modo demostración</Badge>}
        </div>

        {duplicateOf && (
          <div className="rounded-xl border border-ambar/40 bg-ambar/10 px-4 py-3 text-sm text-ambar-text">
            Podría ser un duplicado de{" "}
            <Link href={`/documentos/${duplicateOf.id}`} className="font-medium underline">
              {duplicateOf.original_filename}
            </Link>
            . Revísalo antes de confirmar.
          </div>
        )}

        {document.summary && <p className="text-sm text-ink-muted">{document.summary}</p>}

        <section>
          <div className="mb-2 flex items-center justify-between">
            <h2 className="flex items-center gap-1.5 text-sm font-semibold text-ink">
              <Briefcase className="h-4 w-4 text-brand" /> Asunto
            </h2>
            {asuntos.length === 0 && <NewAsuntoDialog documentId={document.id} label="Crear asunto" />}
          </div>
          {asuntos.length === 0 ? (
            <p className="text-sm text-ink-muted">Este documento no pertenece a ningún asunto todavía.</p>
          ) : (
            <div className="space-y-2">
              {asuntos.map((a) => (
                <Link key={a.id} href={`/asuntos/${a.id}`} className="flex items-center justify-between rounded-2xl border border-borde bg-surface px-4 py-3 hover:border-brand/40">
                  <span className="text-sm text-ink">{a.titulo}</span>
                  <Badge tone="brand">{ASUNTO_ESTADO_LABEL[a.estado as AsuntoEstado]}</Badge>
                </Link>
              ))}
            </div>
          )}
        </section>

        {isDemo && (
          <div className="rounded-xl border border-lavanda/40 bg-lavanda/10 px-4 py-3 text-xs text-ink">
            Este análisis se ha generado en <span className="font-semibold">modo demostración</span> (sin clave de Anthropic configurada): los datos son de ejemplo, no una lectura real del archivo.
          </div>
        )}

        {fields.length > 0 && (
          <section>
            <h2 className="mb-3 text-sm font-semibold text-ink">Datos detectados</h2>
            <div className="space-y-3">
              {fields.map((f) => (
                <div key={f.id} className="rounded-2xl border border-borde bg-surface p-4">
                  <div className="mb-2 flex items-center justify-between">
                    <label className="text-xs font-medium text-ink-muted">{f.field_label}</label>
                    <ConfidenceBadge confidence={f.confidence} isDemo={isDemo} />
                  </div>
                  <input
                    value={values[f.id] ?? ""}
                    onChange={(e) => setValues((v) => ({ ...v, [f.id]: e.target.value }))}
                    className="w-full rounded-lg border border-borde px-3 py-2 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand/20"
                  />
                </div>
              ))}
            </div>
          </section>
        )}

        {document.pending_events.length > 0 && (
          <section>
            <h2 className="mb-3 text-sm font-semibold text-ink">Recordatorios propuestos</h2>
            <div className="space-y-2">
              {document.pending_events.map((e, i) => (
                <label key={i} className="flex cursor-pointer items-start gap-3 rounded-2xl border border-borde bg-surface p-4">
                  <input
                    type="checkbox"
                    checked={approvedEvents.has(i)}
                    onChange={(ev) =>
                      setApprovedEvents((prev) => {
                        const next = new Set(prev);
                        if (ev.target.checked) next.add(i);
                        else next.delete(i);
                        return next;
                      })
                    }
                    className="mt-1 h-4 w-4 accent-brand"
                  />
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center justify-between gap-2">
                      <p className="text-sm font-medium text-ink">{e.title}</p>
                      <Badge tone="brand">{EVENT_TYPE_LABEL[e.eventType]}</Badge>
                    </div>
                    <p className="mt-0.5 text-xs text-ink-muted">
                      {formatDate(e.date)} · {DATE_KIND_LABEL[e.dateKind]}
                    </p>
                    <p className="mt-1 text-xs text-ink-faint">{e.reason}</p>
                  </div>
                </label>
              ))}
            </div>
          </section>
        )}

        {error && <p className="text-sm text-rojo-text">{error}</p>}

        {(needsReview || fields.length > 0 || document.pending_events.length > 0) && (
          <button
            onClick={handleConfirm}
            disabled={saving}
            className="flex w-full items-center justify-center gap-2 rounded-xl bg-brand px-4 py-3 text-sm font-medium text-white hover:bg-brand-strong disabled:opacity-60"
          >
            <CheckCircle2 className="h-4 w-4" />
            {saving ? "Guardando..." : needsReview ? "Confirmar y organizar" : "Guardar cambios"}
          </button>
        )}
      </div>
    </div>
  );
}
