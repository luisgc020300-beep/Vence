import { createClient } from "@/lib/supabase/server";
import { PageHeader } from "@/components/ui/page-header";
import { EmptyState } from "@/components/ui/empty-state";
import { EventRow } from "@/components/events/event-row";
import { NewEventDialog } from "@/components/events/new-event-dialog";
import { CalendarDays } from "lucide-react";

export default async function CalendarioPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;

  const { data: events } = await supabase
    .from("events")
    .select("*")
    .eq("user_id", user.id)
    .order("event_date", { ascending: true });

  const pending = (events ?? []).filter((e) => e.status === "pendiente");
  const resolved = (events ?? []).filter((e) => e.status !== "pendiente").slice(0, 10);

  const groups = groupByMonth(pending);

  return (
    <div>
      <PageHeader eyebrow="VENCE" title="Calendario" action={<NewEventDialog />} />

      <div className="px-5 py-6 md:px-8">
        {pending.length === 0 ? (
          <EmptyState icon={CalendarDays} title="No tienes vencimientos pendientes" description="Los que detectemos en tus documentos, o que crees a mano, aparecerán agrupados por mes." />
        ) : (
          <div className="space-y-6">
            {groups.map(([month, items]) => (
              <section key={month}>
                <h2 className="mb-2 text-sm font-semibold capitalize text-ink">{month}</h2>
                <div className="space-y-2">
                  {items.map((e) => (
                    <EventRow key={e.id} event={e} documentId={e.document_id ?? undefined} />
                  ))}
                </div>
              </section>
            ))}
          </div>
        )}

        {resolved.length > 0 && (
          <section className="mt-8">
            <h2 className="mb-2 text-sm font-semibold text-ink-muted">Resueltas recientemente</h2>
            <div className="space-y-2">
              {resolved.map((e) => (
                <EventRow key={e.id} event={e} documentId={e.document_id ?? undefined} />
              ))}
            </div>
          </section>
        )}
      </div>
    </div>
  );
}

function groupByMonth<T extends { event_date: string }>(items: T[]): [string, T[]][] {
  const map = new Map<string, T[]>();
  for (const item of items) {
    const key = new Intl.DateTimeFormat("es-ES", { month: "long", year: "numeric" }).format(new Date(item.event_date));
    map.set(key, [...(map.get(key) ?? []), item]);
  }
  return Array.from(map.entries());
}
