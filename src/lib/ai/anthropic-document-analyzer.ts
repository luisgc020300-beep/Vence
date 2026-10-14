import Anthropic from "@anthropic-ai/sdk";
import type { DocumentAnalyzer, DocumentAnalyzerInput, DocumentAnalysisResult } from "./types";
import type { DocumentCategory } from "@/lib/db/types";

const CATEGORIES: DocumentCategory[] = [
  "factura",
  "garantia",
  "contrato",
  "seguro",
  "suscripcion",
  "justificante",
  "manual_producto",
  "otro",
];

const EXTRACT_TOOL = {
  name: "extraer_documento",
  description: "Registra la extracción estructurada de un documento administrativo (factura, garantía, contrato, seguro, suscripción, justificante o manual).",
  input_schema: {
    type: "object" as const,
    properties: {
      category: { type: "string", enum: CATEGORIES },
      summary: { type: "string", description: "Resumen en lenguaje sencillo, 1-2 frases, en español." },
      possible_duplicate_hint: { type: "string", description: "Si el documento parece un duplicado de otro tipo común, descríbelo; si no, omite el campo." },
      fields: {
        type: "array",
        items: {
          type: "object",
          properties: {
            key: { type: "string" },
            label: { type: "string" },
            value: { type: "string" },
            confidence: { type: "number", minimum: 0, maximum: 1 },
          },
          required: ["key", "label", "value", "confidence"],
        },
      },
      suggested_events: {
        type: "array",
        items: {
          type: "object",
          properties: {
            title: { type: "string" },
            event_type: { type: "string", enum: ["vencimiento", "renovacion", "devolucion", "garantia", "revision", "pago", "manual"] },
            date: { type: "string", description: "Fecha ISO yyyy-mm-dd. Solo inclúyela si el documento la indica o permite calcularla con certeza." },
            date_kind: { type: "string", enum: ["explicita", "calculada", "sugerida"] },
            priority: { type: "string", enum: ["alta", "media", "baja"] },
            reason: { type: "string", description: "Por qué se propone esta fecha/tarea, citando la parte del documento en que se basa." },
          },
          required: ["title", "event_type", "date", "date_kind", "priority", "reason"],
        },
      },
    },
    required: ["category", "summary", "fields", "suggested_events"],
  },
};

const SYSTEM_PROMPT = `Eres el motor de extracción documental de Vence, una app de gestión administrativa personal.
Analizas un único documento (factura, garantía, contrato, seguro, suscripción, justificante o manual) y devuelves
únicamente los datos que el documento contiene o permite calcular con certeza razonable.
Reglas estrictas:
- No inventes fechas, importes, nombres ni condiciones. Si un dato no aparece, no lo incluyas.
- Toda fecha propuesta debe marcarse como "explicita" (aparece literal en el documento), "calculada" (se deduce de una regla explícita del propio documento, p. ej. "24 meses desde la compra") o "sugerida" (una suposición razonable sin base firme en el texto, p. ej. plazos legales genéricos no confirmados).
- Asigna confidence bajo (<0.5) a cualquier dato ambiguo o parcialmente legible.
- El resumen debe ser honesto: si el documento es ilegible o ambiguo, dilo en el resumen en vez de forzar una categoría.
Responde solo llamando a la herramienta extraer_documento.`;

export class AnthropicDocumentAnalyzer implements DocumentAnalyzer {
  readonly mode = "real" as const;
  private client: Anthropic;

  constructor(apiKey: string) {
    this.client = new Anthropic({ apiKey });
  }

  async analyze(input: DocumentAnalyzerInput): Promise<DocumentAnalysisResult> {
    const isPdf = input.mimeType === "application/pdf";
    const isImage = input.mimeType.startsWith("image/");

    if (!isPdf && !isImage) {
      return {
        mode: "real",
        category: "otro",
        summary: `Formato "${input.mimeType}" no soportado para análisis automático todavía. Añade los datos manualmente.`,
        fields: [],
        suggestedEvents: [],
        possibleDuplicateHint: null,
      };
    }

    const base64 = input.bytes.toString("base64");
    const documentBlock = isPdf
      ? { type: "document" as const, source: { type: "base64" as const, media_type: "application/pdf" as const, data: base64 } }
      : { type: "image" as const, source: { type: "base64" as const, media_type: input.mimeType as "image/jpeg" | "image/png" | "image/webp", data: base64 } };

    const response = await this.client.messages.create({
      model: "claude-sonnet-5-5",
      max_tokens: 2048,
      system: SYSTEM_PROMPT,
      tools: [EXTRACT_TOOL],
      tool_choice: { type: "tool", name: "extraer_documento" },
      messages: [
        {
          role: "user",
          content: [documentBlock, { type: "text", text: `Archivo original: "${input.filename}". Analiza el documento adjunto.` }],
        },
      ],
    });

    const toolUse = response.content.find((b) => b.type === "tool_use");
    if (!toolUse || toolUse.type !== "tool_use") {
      throw new Error("El modelo no devolvió una extracción estructurada.");
    }

    const raw = toolUse.input as {
      category: DocumentCategory;
      summary: string;
      possible_duplicate_hint?: string;
      fields: { key: string; label: string; value: string; confidence: number }[];
      suggested_events: { title: string; event_type: string; date: string; date_kind: string; priority: string; reason: string }[];
    };

    return {
      mode: "real",
      category: raw.category,
      summary: raw.summary,
      possibleDuplicateHint: raw.possible_duplicate_hint ?? null,
      fields: raw.fields.map((f) => ({ key: f.key, label: f.label, value: f.value, confidence: f.confidence })),
      suggestedEvents: raw.suggested_events.map((e) => ({
        title: e.title,
        eventType: e.event_type as DocumentAnalysisResult["suggestedEvents"][number]["eventType"],
        date: e.date,
        dateKind: e.date_kind as DocumentAnalysisResult["suggestedEvents"][number]["dateKind"],
        priority: e.priority as DocumentAnalysisResult["suggestedEvents"][number]["priority"],
        reason: e.reason,
      })),
    };
  }
}
