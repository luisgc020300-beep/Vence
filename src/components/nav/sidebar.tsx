"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Plus } from "lucide-react";
import { NAV_ITEMS } from "./nav-items";
import { cn } from "@/lib/utils";

export function Sidebar({ onAddDocument }: { onAddDocument?: () => void }) {
  const pathname = usePathname();

  return (
    <aside className="hidden w-60 shrink-0 flex-col border-r border-borde bg-surface px-4 py-6 md:flex">
      <div className="mb-8 flex items-center gap-2 px-2">
        <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-brand text-sm font-semibold text-white">V</div>
        <span className="text-lg font-semibold text-ink">Vence</span>
      </div>

      <nav className="flex flex-1 flex-col gap-1">
        {NAV_ITEMS.map((item) => {
          const active = pathname.startsWith(item.href);
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition",
                active ? "bg-brand/10 text-brand" : "text-ink-muted hover:bg-surface-muted hover:text-ink",
              )}
            >
              <item.icon className="h-[18px] w-[18px]" strokeWidth={2} />
              {item.label}
            </Link>
          );
        })}
      </nav>

      <button
        type="button"
        onClick={onAddDocument}
        className="mt-4 flex items-center justify-center gap-2 rounded-xl bg-brand px-3 py-2.5 text-sm font-medium text-white transition hover:bg-brand-strong"
      >
        <Plus className="h-4 w-4" strokeWidth={2.5} />
        Añadir documento
      </button>
    </aside>
  );
}
