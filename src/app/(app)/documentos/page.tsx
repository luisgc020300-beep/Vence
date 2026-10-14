import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { PageHeader } from "@/components/ui/page-header";
import { EmptyState } from "@/components/ui/empty-state";
import { Badge } from "@/components/ui/badge";
import { CATEGORY_LABEL, DOCUMENT_STATUS_LABEL } from "@/lib/labels";
import { formatDate } from "@/lib/utils";
import { FileText } from "lucide-react";
import type { DocumentCategory } from "@/lib/db/types";
import { DocumentFilters } from "./filters";

export default async function DocumentosPage({ searchParams }: { searchParams: Promise<{ q?: string; categoria?: string }> }) {
  const { q, categoria } = await searchParams;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;

  let query = supabase.from("documents").select("id, original_filename, category, status, summary, created_at").eq("user_id", user.id).order("created_at", { ascending: false });

  if (categoria) query = query.eq("category", categoria as DocumentCategory);
  if (q) query = query.ilike("original_filename", `%${q}%`);

  const { data: documents } = await query;

  return (
    <div>
      <PageHeader eyebrow="VENCE" title="Documentos" />

      <div className="px-5 py-6 md:px-8">
        <DocumentFilters initialQuery={q ?? ""} initialCategory={categoria ?? ""} />

        {!documents || documents.length === 0 ? (
          <EmptyState icon={FileText} title="No hay documentos" description="Prueba a cambiar los filtros o añade tu primer documento con el botón de abajo." />
        ) : (
          <div className="mt-4 space-y-2">
            {documents.map((d) => (
              <Link key={d.id} href={`/documentos/${d.id}`} className="flex items-center justify-between rounded-2xl border border-borde bg-surface px-4 py-3.5 transition hover:border-brand/40">
                <div className="min-w-0">
                  <p className="truncate text-sm font-medium text-ink">{d.original_filename}</p>
                  <p className="mt-0.5 truncate text-xs text-ink-muted">{d.summary ?? DOCUMENT_STATUS_LABEL[d.status]} · {formatDate(d.created_at)}</p>
                </div>
                <Badge>{CATEGORY_LABEL[d.category]}</Badge>
              </Link>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
