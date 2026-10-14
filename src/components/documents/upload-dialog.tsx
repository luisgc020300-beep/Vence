"use client";

import { useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { X, UploadCloud, PenLine, Plus, Trash2 } from "lucide-react";
import { CATEGORY_LABEL } from "@/lib/labels";
import type { DocumentCategory } from "@/lib/db/types";
import { cn } from "@/lib/utils";

const CATEGORIES = Object.keys(CATEGORY_LABEL) as DocumentCategory[];

interface UploadDocumentDialogProps {
  open: boolean;
  onClose: () => void;
  /** Cuando se abre desde el detalle de un Asunto: el documento se vincula automáticamente al cerrarse. */
  asuntoId?: string;
  asuntoRole?: "documento" | "evidencia";
}

export function UploadDocumentDialog({ open, onClose, asuntoId, asuntoRole = "documento" }: UploadDocumentDialogProps) {
  const router = useRouter();
  const [mode, setMode] = useState<"archivo" | "manual">("archivo");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [dragOver, setDragOver] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [title, setTitle] = useState("");
  const [category, setCategory] = useState<DocumentCategory>("otro");
  const [fields, setFields] = useState([{ label: "", value: "" }]);

  if (!open) return null;

  function reset() {
    setError(null);
    setBusy(false);
    setTitle("");
    setCategory("otro");
    setFields([{ label: "", value: "" }]);
    setMode("archivo");
  }

  function handleClose() {
    reset();
    onClose();
  }

  async function submitFile(file: File) {
    setBusy(true);
    setError(null);
    const fd = new FormData();
    fd.append("file", file);
    const res = await fetch("/api/documents", { method: "POST", body: fd });
    const json = await res.json();
    if (!res.ok) {
      setBusy(false);
      setError(json.error ?? "No se ha podido subir el documento.");
      return;
    }

    if (asuntoId) {
      await fetch(`/api/asuntos/${asuntoId}/documentos`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ documentId: json.documentId, role: asuntoRole }),
      });
    }

    setBusy(false);
    handleClose();
    router.push(asuntoId ? `/asuntos/${asuntoId}` : `/documentos/${json.documentId}`);
    router.refresh();
  }

  async function submitManual() {
    if (!title.trim()) {
      setError("Ponle un título al registro.");
      return;
    }
    setBusy(true);
    setError(null);
    const fd = new FormData();
    fd.append("title", title.trim());
    fd.append("category", category);
    fd.append("fields", JSON.stringify(fields.filter((f) => f.label.trim() && f.value.trim())));
    const res = await fetch("/api/documents", { method: "POST", body: fd });
    const json = await res.json();
    if (!res.ok) {
      setBusy(false);
      setError(json.error ?? "No se ha podido guardar el registro.");
      return;
    }

    if (asuntoId) {
      await fetch(`/api/asuntos/${asuntoId}/documentos`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ documentId: json.documentId, role: asuntoRole }),
      });
    }

    setBusy(false);
    handleClose();
    router.push(asuntoId ? `/asuntos/${asuntoId}` : `/documentos/${json.documentId}`);
    router.refresh();
  }

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-ink/40 p-0 md:items-center md:p-4" onClick={handleClose}>
      <div
        className="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-t-3xl bg-surface p-6 shadow-xl md:rounded-3xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="mb-5 flex items-center justify-between">
          <h2 className="text-lg font-semibold text-ink">Añadir documento</h2>
          <button onClick={handleClose} aria-label="Cerrar" className="rounded-full p-1.5 text-ink-faint hover:bg-surface-muted hover:text-ink">
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="mb-5 flex gap-2 rounded-xl bg-surface-muted p-1">
          <button
            onClick={() => setMode("archivo")}
            className={cn("flex-1 rounded-lg py-2 text-sm font-medium transition", mode === "archivo" ? "bg-surface text-ink shadow-sm" : "text-ink-muted")}
          >
            Subir archivo
          </button>
          <button
            onClick={() => setMode("manual")}
            className={cn("flex-1 rounded-lg py-2 text-sm font-medium transition", mode === "manual" ? "bg-surface text-ink shadow-sm" : "text-ink-muted")}
          >
            No tengo archivo
          </button>
        </div>

        {mode === "archivo" ? (
          <div
            onDragOver={(e) => {
              e.preventDefault();
              setDragOver(true);
            }}
            onDragLeave={() => setDragOver(false)}
            onDrop={(e) => {
              e.preventDefault();
              setDragOver(false);
              const f = e.dataTransfer.files?.[0];
              if (f) submitFile(f);
            }}
            onClick={() => fileInputRef.current?.click()}
            className={cn(
              "flex cursor-pointer flex-col items-center justify-center gap-3 rounded-2xl border-2 border-dashed px-6 py-12 text-center transition",
              dragOver ? "border-brand bg-brand/5" : "border-borde",
            )}
          >
            <UploadCloud className="h-8 w-8 text-brand" strokeWidth={1.75} />
            <div>
              <p className="text-sm font-medium text-ink">Arrastra un PDF o una foto aquí</p>
              <p className="mt-1 text-xs text-ink-muted">o haz clic para elegir un archivo (máx. 15 MB)</p>
            </div>
            <input
              ref={fileInputRef}
              type="file"
              accept="application/pdf,image/jpeg,image/png,image/webp"
              className="hidden"
              onChange={(e) => {
                const f = e.target.files?.[0];
                if (f) submitFile(f);
              }}
            />
          </div>
        ) : (
          <div className="space-y-4">
            <div>
              <label className="mb-1.5 block text-sm font-medium text-ink">Título</label>
              <input
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="p. ej. Garantía de la lavadora"
                className="w-full rounded-xl border border-borde px-3.5 py-2.5 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand/20"
              />
            </div>
            <div>
              <label className="mb-1.5 block text-sm font-medium text-ink">Categoría</label>
              <select
                value={category}
                onChange={(e) => setCategory(e.target.value as DocumentCategory)}
                className="w-full rounded-xl border border-borde px-3.5 py-2.5 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand/20"
              >
                {CATEGORIES.map((c) => (
                  <option key={c} value={c}>
                    {CATEGORY_LABEL[c]}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <div className="mb-1.5 flex items-center justify-between">
                <label className="text-sm font-medium text-ink">Datos (opcional)</label>
                <button
                  type="button"
                  onClick={() => setFields((f) => [...f, { label: "", value: "" }])}
                  className="flex items-center gap-1 text-xs font-medium text-brand"
                >
                  <Plus className="h-3.5 w-3.5" /> Añadir dato
                </button>
              </div>
              <div className="space-y-2">
                {fields.map((f, i) => (
                  <div key={i} className="flex gap-2">
                    <input
                      value={f.label}
                      onChange={(e) => setFields((prev) => prev.map((p, j) => (j === i ? { ...p, label: e.target.value } : p)))}
                      placeholder="Campo (p. ej. Importe)"
                      className="w-2/5 rounded-xl border border-borde px-3 py-2 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand/20"
                    />
                    <input
                      value={f.value}
                      onChange={(e) => setFields((prev) => prev.map((p, j) => (j === i ? { ...p, value: e.target.value } : p)))}
                      placeholder="Valor"
                      className="flex-1 rounded-xl border border-borde px-3 py-2 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand/20"
                    />
                    <button type="button" onClick={() => setFields((prev) => prev.filter((_, j) => j !== i))} className="px-1 text-ink-faint hover:text-rojo-text">
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>
                ))}
              </div>
            </div>

            <button
              onClick={submitManual}
              disabled={busy}
              className="flex w-full items-center justify-center gap-2 rounded-xl bg-brand px-4 py-2.5 text-sm font-medium text-white hover:bg-brand-strong disabled:opacity-60"
            >
              <PenLine className="h-4 w-4" />
              {busy ? "Guardando..." : "Guardar registro"}
            </button>
          </div>
        )}

        {error && <p className="mt-3 text-sm text-rojo-text">{error}</p>}
        {busy && mode === "archivo" && <p className="mt-3 text-center text-sm text-ink-muted">Subiendo y analizando el documento...</p>}
      </div>
    </div>
  );
}
