import { cn } from "@/lib/utils";

const TONES = {
  brand: "bg-brand/10 text-brand",
  lavanda: "bg-lavanda/20 text-ink",
  verde: "bg-verde/10 text-verde",
  ambar: "bg-ambar/15 text-ambar-text",
  rojo: "bg-rojo/15 text-rojo-text",
  neutral: "bg-surface-muted text-ink-muted",
} as const;

export function Badge({ children, tone = "neutral" }: { children: React.ReactNode; tone?: keyof typeof TONES }) {
  return <span className={cn("inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-medium", TONES[tone])}>{children}</span>;
}

export function ConfidenceBadge({ confidence, isDemo }: { confidence: number | null; isDemo: boolean }) {
  if (isDemo) return <Badge tone="lavanda">Dato de ejemplo (demo)</Badge>;
  if (confidence === null) return <Badge tone="neutral">Manual</Badge>;
  if (confidence >= 0.75) return <Badge tone="verde">Alta confianza</Badge>;
  if (confidence >= 0.5) return <Badge tone="ambar">Confianza media</Badge>;
  return <Badge tone="rojo">Revisar</Badge>;
}
