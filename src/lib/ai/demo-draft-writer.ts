import type { DraftWriter, DraftRequestContext, DraftResult } from "./types";

// Nunca se envía nada automáticamente (sección 9 del brief: enviar
// comunicaciones es Nivel 3, requiere autorización explícita del usuario
// fuera de este generador). Esto solo prepara un texto de partida.
export class DemoDraftWriter implements DraftWriter {
  readonly mode = "demo" as const;

  async draft(context: DraftRequestContext): Promise<DraftResult> {
    return {
      mode: "demo",
      subject: `[Borrador de ejemplo] ${context.asuntoTitulo}`,
      body: `Este es un borrador de ejemplo en modo demostración (sin clave de Anthropic configurada).\n\nAsunto: ${context.asuntoTitulo}\nObjetivo: ${context.asuntoObjetivo ?? "sin especificar"}\n\nUn borrador real citaría datos concretos de tus documentos (números de pedido, fechas, importes). Conecta una clave de Anthropic para generarlo de verdad.\n\n— Redactado por Vence, pendiente de tu revisión antes de enviarlo.`,
    };
  }
}
