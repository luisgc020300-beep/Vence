import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { PageHeader } from "@/components/ui/page-header";
import { EmptyState } from "@/components/ui/empty-state";
import { Badge } from "@/components/ui/badge";
import { ASUNTO_TIPO_LABEL, ASUNTO_ESTADO_LABEL } from "@/lib/labels";
import { NewAsuntoDialog } from "@/components/asuntos/new-asunto-dialog";
import { formatDate } from "@/lib/utils";
import { Briefcase } from "lucide-react";
import type { AsuntoEstado } from "@/lib/db/types";

const ESTADO_TONE: Record<AsuntoEstado, "brand" | "ambar" | "rojo" | "verde" | "neutral" | "lavanda"> = {
  nuevo: "brand",
  necesita_revision: "ambar",
  en_curso: "brand",
  pendiente_usuario: "ambar",
  pendiente_tercero: "lavanda",
  bloqueado: "rojo",
  listo_para_accion: "verde",
  completado: "verde",
  cerrado: "neutral",
  reabierto: "ambar",
};

export default async function AsuntosPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;

  const { data: asuntos } = await supabase.from("asuntos").select("*").eq("user_id", user.id).order("updated_at", { ascending: false });

  const abiertos = (asuntos ?? []).filter((a) => a.estado !== "cerrado");
  const cerrados = (asuntos ?? []).filter((a) => a.estado === "cerrado");

  return (
    <div>
      <PageHeader eyebrow="VENCE" title="Asuntos" action={<NewAsuntoDialog />} />

      <div className="px-5 py-6 md:px-8">
        {abiertos.length === 0 ? (
          <EmptyState icon={Briefcase} title="No tienes asuntos abiertos" description="Un asunto agrupa documentos, tareas y evidencias de una misma gestión: una compra, una incidencia, una renovación..." />
        ) : (
          <div className="space-y-2">
            {abiertos.map((a) => (
              <Link key={a.id} href={`/asuntos/${a.id}`} className="flex items-center justify-between rounded-2xl border border-borde bg-surface px-4 py-3.5 hover:border-brand/40">
                <div className="min-w-0">
                  <p className="truncate text-sm font-medium text-ink">{a.titulo}</p>
                  <p className="mt-0.5 text-xs text-ink-muted">
                    {ASUNTO_TIPO_LABEL[a.tipo]} · actualizado {formatDate(a.updated_at)}
                  </p>
                </div>
                <Badge tone={ESTADO_TONE[a.estado]}>{ASUNTO_ESTADO_LABEL[a.estado]}</Badge>
              </Link>
            ))}
          </div>
        )}

        {cerrados.length > 0 && (
          <section className="mt-8">
            <h2 className="mb-2 text-sm font-semibold text-ink-muted">Cerrados</h2>
            <div className="space-y-2">
              {cerrados.map((a) => (
                <Link key={a.id} href={`/asuntos/${a.id}`} className="flex items-center justify-between rounded-2xl border border-borde bg-surface px-4 py-3.5 opacity-70 hover:border-brand/40">
                  <p className="truncate text-sm font-medium text-ink">{a.titulo}</p>
                  <Badge>{ASUNTO_TIPO_LABEL[a.tipo]}</Badge>
                </Link>
              ))}
            </div>
          </section>
        )}
      </div>
    </div>
  );
}
