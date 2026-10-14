"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Download, LogOut, Trash2 } from "lucide-react";
import { createClient } from "@/lib/supabase/client";

export function AccountActions() {
  const router = useRouter();
  const [deleting, setDeleting] = useState(false);

  async function signOut() {
    const supabase = createClient();
    await supabase.auth.signOut();
    router.push("/login");
    router.refresh();
  }

  async function deleteAccount() {
    if (!confirm("Esto eliminará tu cuenta y todos tus documentos de forma permanente. ¿Continuar?")) return;
    setDeleting(true);
    const res = await fetch("/api/account", { method: "DELETE" });
    setDeleting(false);
    if (res.ok) {
      router.push("/login");
      router.refresh();
    }
  }

  return (
    <div className="space-y-2">
      <a
        href="/api/account/export"
        className="flex w-full items-center gap-3 rounded-2xl border border-borde bg-surface px-4 py-3.5 text-sm font-medium text-ink hover:border-brand/40"
      >
        <Download className="h-4 w-4 text-brand" /> Exportar todos mis datos
      </a>
      <button onClick={signOut} className="flex w-full items-center gap-3 rounded-2xl border border-borde bg-surface px-4 py-3.5 text-sm font-medium text-ink hover:border-brand/40">
        <LogOut className="h-4 w-4 text-ink-muted" /> Cerrar sesión
      </button>
      <button
        onClick={deleteAccount}
        disabled={deleting}
        className="flex w-full items-center gap-3 rounded-2xl border border-rojo/40 bg-surface px-4 py-3.5 text-sm font-medium text-rojo-text hover:bg-rojo/5 disabled:opacity-60"
      >
        <Trash2 className="h-4 w-4" /> {deleting ? "Eliminando cuenta..." : "Eliminar cuenta y todos los datos"}
      </button>
    </div>
  );
}
