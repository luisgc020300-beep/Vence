"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Plus } from "lucide-react";
import { NAV_ITEMS } from "./nav-items";
import { cn } from "@/lib/utils";

export function BottomNav({ onAddDocument }: { onAddDocument?: () => void }) {
  const pathname = usePathname();
  const left = NAV_ITEMS.slice(0, 2);
  const right = NAV_ITEMS.slice(2);

  return (
    <nav className="fixed inset-x-0 bottom-0 z-20 border-t border-borde bg-surface/95 backdrop-blur md:hidden">
      <div className="mx-auto flex max-w-md items-center justify-between px-2 py-2">
        {left.map((item) => (
          <TabLink key={item.href} item={item} active={pathname.startsWith(item.href)} />
        ))}

        <button
          type="button"
          onClick={onAddDocument}
          aria-label="Añadir documento"
          className="flex h-12 w-12 -translate-y-3 items-center justify-center rounded-full bg-brand text-white shadow-lg shadow-brand/30"
        >
          <Plus className="h-6 w-6" strokeWidth={2.5} />
        </button>

        {right.map((item) => (
          <TabLink key={item.href} item={item} active={pathname.startsWith(item.href)} />
        ))}
      </div>
    </nav>
  );
}

function TabLink({ item, active }: { item: (typeof NAV_ITEMS)[number]; active: boolean }) {
  return (
    <Link
      href={item.href}
      className={cn("flex flex-col items-center gap-0.5 rounded-lg px-3 py-1.5 text-[11px] font-medium", active ? "text-brand" : "text-ink-faint")}
    >
      <item.icon className="h-5 w-5" strokeWidth={2} />
      {item.label}
    </Link>
  );
}
