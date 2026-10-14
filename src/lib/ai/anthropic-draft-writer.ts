import Anthropic from "@anthropic-ai/sdk";
import type { DraftWriter, DraftRequestContext, DraftResult } from "./types";

const DRAFT_TOOL = {
  name: "redactar_borrador",
  description: "Registra un borrador de comunicación (p. ej. reclamación, solicitud de devolución) listo para que el usuario lo revise antes de enviarlo.",
  input_schema: {
    type: "object" as const,
    properties: {
      subject: { type: "string" },
      body: { type: "string", description: "Cuerpo del mensaje en español, cortés, concreto, citando solo datos presentes en el contexto." },
    },
    required: ["subject", "body"],
  },
};

const SYSTEM_PROMPT = `Eres el redactor de borradores de Vence. Preparas un ÚNICO borrador de comunicación (reclamación, solicitud de
devolución, consulta a un proveedor...) a partir de un asunto y sus documentos.
Reglas estrictas:
- Usa solo datos presentes en el contexto proporcionado (números de pedido, fechas, importes, nombres). No inventes ninguno.
- Si falta un dato importante para que la comunicación sea creíble (p. ej. el número de pedido), dilo explícitamente en el cuerpo entre corchetes, p. ej. "[número de pedido]", en vez de inventarlo.
- Tono cortés y profesional, en español de España.
- Este borrador NUNCA se envía automáticamente — termina siempre indicando que queda pendiente de revisión del usuario.
Responde solo llamando a la herramienta redactar_borrador.`;

export class AnthropicDraftWriter implements DraftWriter {
  readonly mode = "real" as const;
  private client: Anthropic;

  constructor(apiKey: string) {
    this.client = new Anthropic({ apiKey });
  }

  async draft(context: DraftRequestContext): Promise<DraftResult> {
    const response = await this.client.messages.create({
      model: "claude-sonnet-5-5",
      max_tokens: 1024,
      system: SYSTEM_PROMPT,
      tools: [DRAFT_TOOL],
      tool_choice: { type: "tool", name: "redactar_borrador" },
      messages: [
        {
          role: "user",
          content: JSON.stringify(
            {
              asunto: { titulo: context.asuntoTitulo, objetivo: context.asuntoObjetivo, tipo: context.asuntoTipo },
              documentos: context.documents,
            },
            null,
            2,
          ),
        },
      ],
    });

    const toolUse = response.content.find((b) => b.type === "tool_use");
    if (!toolUse || toolUse.type !== "tool_use") {
      return { mode: "real", subject: context.asuntoTitulo, body: "No se ha podido generar un borrador en este momento." };
    }
    const raw = toolUse.input as { subject: string; body: string };
    return { mode: "real", subject: raw.subject, body: raw.body };
  }
}
