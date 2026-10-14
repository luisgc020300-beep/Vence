import type { LucideIcon } from "lucide-react";
import { LayoutDashboard, FileText, CalendarDays, MessageCircleQuestion, UserRound } from "lucide-react";

export interface NavItem {
  href: string;
  label: string;
  icon: LucideIcon;
}

export const NAV_ITEMS: NavItem[] = [
  { href: "/dashboard", label: "Inicio", icon: LayoutDashboard },
  { href: "/documentos", label: "Documentos", icon: FileText },
  { href: "/calendario", label: "Calendario", icon: CalendarDays },
  { href: "/asistente", label: "Asistente", icon: MessageCircleQuestion },
  { href: "/perfil", label: "Perfil", icon: UserRound },
];
