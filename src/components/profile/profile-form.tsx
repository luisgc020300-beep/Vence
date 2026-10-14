"use client";

import { useState } from "react";
import type { ProfileRow } from "@/lib/db/types";

export function ProfileForm({ email, profile }: { email: string; profile: ProfileRow | null }) {
  const [displayName, setDisplayName] = useState(profile?.display_name ?? "");
  const [notifEmail, setNotifEmail] = useState(profile?.notif_email ?? true);
  const [daysBefore, setDaysBefore] = useState(profile?.notif_days_before ?? 7);
  const [saved, setSaved] = useState(false);
  const [saving, setSaving] = useState(false);

  async function save() {
    setSaving(true);
    setSaved(false);
    await fetch("/api/account", {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ display_name: displayName, notif_email: notifEmail, notif_days_before: daysBefore }),
    });
    setSaving(false);
    setSaved(true);
  }

  return (
    <div className="space-y-4 rounded-2xl border border-borde bg-surface p-5">
      <div>
        <label className="mb-1.5 block text-sm font-medium text-ink">Email</label>
        <input disabled value={email} className="w-full rounded-xl border border-borde bg-surface-muted px-3.5 py-2.5 text-sm text-ink-muted" />
      </div>
      <div>
        <label className="mb-1.5 block text-sm font-medium text-ink">Nombre</label>
        <input
          value={displayName}
          onChange={(e) => setDisplayName(e.target.value)}
          className="w-full rounded-xl border border-borde px-3.5 py-2.5 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand/20"
        />
      </div>
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm font-medium text-ink">Avisos por email</p>
          <p className="text-xs text-ink-muted">Recibe un correo antes de cada vencimiento importante</p>
        </div>
        <input type="checkbox" checked={notifEmail} onChange={(e) => setNotifEmail(e.target.checked)} className="h-5 w-5 accent-brand" />
      </div>
      <div>
        <label className="mb-1.5 block text-sm font-medium text-ink">Avisar con cuántos días de antelación</label>
        <input
          type="number"
          min={1}
          max={60}
          value={daysBefore}
          onChange={(e) => setDaysBefore(Number(e.target.value))}
          className="w-24 rounded-xl border border-borde px-3.5 py-2.5 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand/20"
        />
      </div>
      <button onClick={save} disabled={saving} className="rounded-xl bg-brand px-4 py-2.5 text-sm font-medium text-white hover:bg-brand-strong disabled:opacity-60">
        {saving ? "Guardando..." : saved ? "Guardado" : "Guardar cambios"}
      </button>
    </div>
  );
}
