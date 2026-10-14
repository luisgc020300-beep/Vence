import type { Assistant, AssistantAnswer } from "./types";

// Asistente de demostración: responde con reglas simples sobre el
// contexto real del usuario (sí usa sus documentos/eventos de verdad),
// pero sin ningún modelo de lenguaje detrás. Se usa cuando no hay clave
// de Anthropic configurada, y siempre se marca `mode: "demo"`.
export class DemoAssistant implements Assistant {
  readonly mode = "demo" as const;

  async ask(question: string, context: Parameters<Assistant["ask"]>[1]): Promise<AssistantAnswer> {
    const q = question.toLowerCase();

    if (/vence|venc|pendiente|esta semana|este mes/.test(q)) {
      const upcoming = context.events
        .filter((e) => e.status === "pendiente")
        .sort((a, b) => a.date.localeCompare(b.date))
        .slice(0, 5);

      if (upcoming.length === 0) {
        return { mode: "demo", content: "No tienes ningún vencimiento pendiente registrado todavía.", sources: [], confident: true };
      }

      const lines = upcoming.map((e) => `- ${e.title} (${e.type}) — ${e.date}`).join("\n");
      return {
        mode: "demo",
        content: `Esto es lo próximo que tienes pendiente, según tus recordatorios:\n${lines}\n\n(Respuesta en modo demostración: regla simple sobre tus datos reales, sin modelo de IA.)`,
        sources: [],
        confident: true,
      };
    }

    if (/documentos? me faltan|qu[eé] me falta/.test(q)) {
      return {
        mode: "demo",
        content: "En modo demostración no puedo inferir qué documentos te faltan — esta función necesita el modelo de IA real conectado para razonar sobre huecos en tu archivo.",
        sources: [],
        confident: false,
      };
    }

    const match = context.documents.find((d) => q.includes(d.filename.toLowerCase().split(".")[0]));
    if (match) {
      return {
        mode: "demo",
        content: `Esto es lo que tengo registrado de "${match.filename}": ${match.summary ?? "sin resumen todavía"}.\n\n(Respuesta en modo demostración, basada solo en el resumen guardado, no en un análisis del lenguaje de tu pregunta.)`,
        sources: [{ documentId: match.id, documentName: match.filename, snippet: match.summary ?? "" }],
        confident: false,
      };
    }

    return {
      mode: "demo",
      content: "No tengo una respuesta fiable para esto en modo demostración. Conecta una clave de Anthropic para que el asistente razone de verdad sobre tus documentos.",
      sources: [],
      confident: false,
    };
  }
}
