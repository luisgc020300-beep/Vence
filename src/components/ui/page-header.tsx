export function PageHeader({ eyebrow, title, action }: { eyebrow: string; title: string; action?: React.ReactNode }) {
  return (
    <div className="flex items-center justify-between border-b border-borde bg-surface px-5 py-5 md:px-8">
      <div>
        <p className="text-[11px] font-semibold uppercase tracking-wide text-ink-faint">{eyebrow}</p>
        <h1 className="text-xl font-semibold text-ink md:text-2xl">{title}</h1>
      </div>
      {action}
    </div>
  );
}
