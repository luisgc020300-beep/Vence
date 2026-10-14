"use client";

import { useRouter, usePathname, useSearchParams } from "next/navigation";
import { Search } from "lucide-react";
import { CATEGORY_LABEL } from "@/lib/labels";

const CATEGORIES = Object.keys(CATEGORY_LABEL) as (keyof typeof CATEGORY_LABEL)[];

export function DocumentFilters({ initialQuery, initialCategory }: { initialQuery: string; initialCategory: string }) {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();

  function update(key: string, value: string) {
    const params = new URLSearchParams(searchParams.toString());
    if (value) params.set(key, value);
    else params.delete(key);
    router.push(`${pathname}?${params.toString()}`);
  }

  return (
    <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
      <div className="relative flex-1">
        <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-ink-faint" />
        <input
          defaultValue={initialQuery}
          onChange={(e) => update("q", e.target.value)}
          placeholder="Buscar por nombre de archivo..."
          className="w-full rounded-xl border border-borde bg-surface py-2.5 pl-9 pr-3.5 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand/20"
        />
      </div>
      <select
        defaultValue={initialCategory}
        onChange={(e) => update("categoria", e.target.value)}
        className="rounded-xl border border-borde bg-surface px-3.5 py-2.5 text-sm outline-none focus:border-brand focus:ring-2 focus:ring-brand/20"
      >
        <option value="">Todas las categorías</option>
        {CATEGORIES.map((c) => (
          <option key={c} value={c}>
            {CATEGORY_LABEL[c]}
          </option>
        ))}
      </select>
    </div>
  );
}
