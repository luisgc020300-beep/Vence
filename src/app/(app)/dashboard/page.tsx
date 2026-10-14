import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { PageHeader } from "@/components/ui/page-header";
import { EmptyState } from "@/components/ui/empty-state";
import { Badge } from "@/components/ui/badge";
import { CATEGORY_LABEL, EVENT_TYPE_LABEL, ASUNTO_TIPO_LABEL, ASUNTO_ESTADO_LABEL } from "@/lib/labels";
import { daysUntil, formatDate } from "@/lib/utils";
import { Inbox, CalendarClock, FileText, Sparkles, Briefcase } from "lucide-react";

export default async function DashboardPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;

  const [{ data: profile }, { data: asuntos }, { data: inbox }, { data: upcoming }, { data: recent }] = await Promise.all([
    supabase.from("profiles").select("display_name").eq("id", user.id).single(),
    supabase
      .from("asuntos")
      .select("id, titulo, tipo, estado, prioridad")
      .eq("user_id", user.id)
      .neq("estado", "cerrado")
      .order("updated_at", { ascending: false })
      .limit(5),
    supabase
      .from("documents")
      .select("id, original_filename, category, summary, created_at")
      .eq("user_id", user.id)
      .eq("status", "en_revision")
      .order("created_at", { ascending: false }),
    supabase
      .from("events")
      .select("id, title, event_date, event_type, priority")
      .eq("user_id", user.id)
      .eq("status", "pendiente")
      .order("event_date", { ascending: true })
      .limit(6),
    supabase
      .from("documents")
      .select("id, original_filename, category, status, created_at")
      .eq("user_id", user.id)
      .order("created_at", { ascending: false })
      .limit(5),
  ]);

  const bloqueados = (asuntos ?? []).filter((a) => a.estado === "bloqueado").length;

  const name = profile?.display_name?.split("@")[0] ?? "";

  return (
    <div>
      <PageHeader eyebrow="VENCE" title={name ? `Hola, ${name}` : "Hola"} />

      <div className="grid gap-6 px-5 py-6 md:grid-cols-2 md:px-8">
        <section className="md:col-span-2">
          <div className="mb-3 flex items-center justify-between">
            <SectionTitle
              icon={Briefcase}
              title="Asuntos abiertos"
              subtitle={bloqueados > 0 ? `${bloqueados} bloqueado${bloqueados > 1 ? "s" : ""}` : "lo que necesita avanzar"}
            />
            <Link href="/asuntos" className="text-xs font-medium text-brand">
              Ver todos
            </Link>
          </div>
          {!asuntos || asuntos.length === 0 ? (
            <EmptyState
              icon={Briefcase}
              title="No tienes asuntos abiertos"
              description="Un asunto agrupa documentos, tareas y evidencias de una gestión real: una compra, una incidencia, una renovación."
            />
          ) : (
            <div className="space-y-2">
              {asuntos.map((a) => (
                <Link key={a.id} href={`/asuntos/${a.id}`} className="flex items-center justify-between rounded-2xl border border-borde bg-surface px-4 py-3.5 hover:border-brand/40">
                  <div className="min-w-0">
                    <p className="truncate text-sm font-medium text-ink">{a.titulo}</p>
                    <p className="mt-0.5 text-xs text-ink-muted">{ASUNTO_TIPO_LABEL[a.tipo]}</p>
                  </div>
                  <Badge tone={a.estado === "bloqueado" ? "rojo" : a.prioridad === "alta" ? "ambar" : "neutral"}>{ASUNTO_ESTADO_LABEL[a.estado]}</Badge>
                </Link>
              ))}
            </div>
          )}
        </section>

        <section className="md:col-span-2">
          <SectionTitle icon={Inbox} title="Bandeja de entrada" subtitle="Documentos recién añadidos que necesitan tu revisión" />
          {!inbox || inbox.length === 0 ? (
            <EmptyState
              icon={Inbox}
              title="Nada pendiente de revisar"
              description="Cuando añadas un documento, aparecerá aquí para que confirmes los datos detectados."
            />
          ) : (
            <div className="space-y-2">
              {inbox.map((d) => (
                <Link
                  key={d.id}
                  href={`/documentos/${d.id}`}
                  className="flex items-center justify-between rounded-2xl border border-borde bg-surface px-4 py-3.5 transition hover:border-brand/40"
                >
                  <div className="min-w-0">
                    <p className="truncate text-sm font-medium text-ink">{d.original_filename}</p>
                    <p className="mt-0.5 truncate text-xs text-ink-muted">{d.summary ?? "Sin resumen"}</p>
                  </div>
                  <Badge tone="ambar">{CATEGORY_LABEL[d.category]}</Badge>
                </Link>
              ))}
            </div>
          )}
        </section>

        <section>
          <SectionTitle icon={CalendarClock} title="Próximos vencimientos" subtitle="Lo más urgente primero" />
          {!upcoming || upcoming.length === 0 ? (
            <EmptyState icon={CalendarClock} title="Sin vencimientos próximos" description="Los que detectemos en tus documentos, o que crees a mano, aparecerán aquí." />
          ) : (
            <div className="space-y-2">
              {upcoming.map((e) => {
                const days = daysUntil(e.event_date);
                return (
                  <div key={e.id} className="flex items-center justify-between rounded-2xl border border-borde bg-surface px-4 py-3.5">
                    <div className="min-w-0">
                      <p className="truncate text-sm font-medium text-ink">{e.title}</p>
                      <p className="mt-0.5 text-xs text-ink-muted">
                        {EVENT_TYPE_LABEL[e.event_type]} · {formatDate(e.event_date)}
                      </p>
                    </div>
                    <Badge tone={days < 0 ? "rojo" : days <= 7 ? "ambar" : "neutral"}>
                      {days < 0 ? "Atrasado" : days === 0 ? "Hoy" : `${days} días`}
                    </Badge>
                  </div>
                );
              })}
            </div>
          )}
        </section>

        <section>
          <SectionTitle icon={FileText} title="Actividad reciente" subtitle="Últimos documentos añadidos" />
          {!recent || recent.length === 0 ? (
            <EmptyState
              icon={FileText}
              title="Todavía no has añadido nada"
              description="Usa el botón «Añadir documento» para subir tu primera factura, garantía o contrato."
            />
          ) : (
            <div className="space-y-2">
              {recent.map((d) => (
                <Link key={d.id} href={`/documentos/${d.id}`} className="flex items-center justify-between rounded-2xl border border-borde bg-surface px-4 py-3.5 hover:border-brand/40">
                  <p className="truncate text-sm font-medium text-ink">{d.original_filename}</p>
                  <Badge>{CATEGORY_LABEL[d.category]}</Badge>
                </Link>
              ))}
            </div>
          )}
        </section>
      </div>

      <Link
        href="/asistente"
        className="fixed bottom-24 right-5 z-10 flex items-center gap-2 rounded-full bg-ink px-4 py-3 text-sm font-medium text-white shadow-lg md:bottom-6 md:right-8"
      >
        <Sparkles className="h-4 w-4 text-lavanda" />
        Preguntar al asistente
      </Link>
    </div>
  );
}

function SectionTitle({ icon: Icon, title, subtitle }: { icon: typeof Inbox; title: string; subtitle: string }) {
  return (
    <div className="mb-3 flex items-center gap-2">
      <Icon className="h-4 w-4 text-brand" strokeWidth={2} />
      <h2 className="text-sm font-semibold text-ink">{title}</h2>
      <span className="text-xs text-ink-faint">· {subtitle}</span>
    </div>
  );
}
