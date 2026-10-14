import type { DocumentAnalyzer, DocumentAnalyzerInput, DocumentAnalysisResult } from "./types";
import type { DocumentCategory } from "@/lib/db/types";

// Analizador de demostración: no llama a ningún modelo. Genera una
// extracción plausible a partir del nombre de archivo para poder recorrer
// el flujo completo (subir -> revisar -> confirmar -> recordatorio) sin
// clave de Anthropic configurada. Todo lo que produce se marca `mode:
// "demo"` y la UI debe mostrarlo con una etiqueta visible de demostración
// — nunca se presenta como si un modelo real hubiera analizado el archivo.
export class DemoDocumentAnalyzer implements DocumentAnalyzer {
  readonly mode = "demo" as const;

  async analyze(input: DocumentAnalyzerInput): Promise<DocumentAnalysisResult> {
    const name = input.filename.toLowerCase();
    const category = guessCategory(name);
    const today = new Date();
    const inDays = (d: number) => {
      const date = new Date(today);
      date.setDate(date.getDate() + d);
      return date.toISOString().slice(0, 10);
    };

    const byCategory: Record<DocumentCategory, Omit<DocumentAnalysisResult, "mode" | "possibleDuplicateHint">> = {
      factura: {
        category: "factura",
        summary: "Factura de compra detectada (datos de ejemplo, modo demostración).",
        fields: [
          { key: "entidad", label: "Comercio / entidad", value: "Comercio de ejemplo S.L.", confidence: 0.4 },
          { key: "importe", label: "Importe total", value: "129,00 €", confidence: 0.4 },
          { key: "fecha_compra", label: "Fecha de compra", value: today.toISOString().slice(0, 10), confidence: 0.4 },
        ],
        suggestedEvents: [
          {
            title: "Revisar periodo de devolución",
            eventType: "devolucion",
            date: inDays(14),
            dateKind: "sugerida",
            priority: "media",
            reason: "Las facturas suelen tener un plazo de devolución de referencia de 14 días (sin confirmar en este documento de demostración).",
          },
        ],
      },
      garantia: {
        category: "garantia",
        summary: "Documento de garantía detectado (datos de ejemplo, modo demostración).",
        fields: [
          { key: "producto", label: "Producto", value: "Producto de ejemplo", confidence: 0.4 },
          { key: "duracion", label: "Duración de la garantía", value: "24 meses", confidence: 0.4 },
        ],
        suggestedEvents: [
          {
            title: "Vencimiento de garantía",
            eventType: "garantia",
            date: inDays(365 * 2),
            dateKind: "calculada",
            priority: "baja",
            reason: "Calculada a partir de una duración de ejemplo de 24 meses desde hoy.",
          },
        ],
      },
      contrato: {
        category: "contrato",
        summary: "Contrato detectado (datos de ejemplo, modo demostración).",
        fields: [
          { key: "contraparte", label: "Contraparte", value: "Proveedor de ejemplo", confidence: 0.4 },
          { key: "renovacion", label: "Tipo de renovación", value: "Tácita, anual", confidence: 0.3 },
        ],
        suggestedEvents: [
          {
            title: "Posible renovación de contrato",
            eventType: "renovacion",
            date: inDays(90),
            dateKind: "sugerida",
            priority: "media",
            reason: "Fecha orientativa de ejemplo — confírmala tras leer las condiciones reales del contrato.",
          },
        ],
      },
      seguro: {
        category: "seguro",
        summary: "Póliza de seguro detectada (datos de ejemplo, modo demostración).",
        fields: [
          { key: "compañia", label: "Compañía", value: "Aseguradora de ejemplo", confidence: 0.4 },
          { key: "prima", label: "Prima anual", value: "340,00 €", confidence: 0.3 },
        ],
        suggestedEvents: [
          {
            title: "Renovación de póliza",
            eventType: "renovacion",
            date: inDays(365),
            dateKind: "sugerida",
            priority: "alta",
            reason: "Fecha orientativa de ejemplo a un año vista.",
          },
        ],
      },
      suscripcion: {
        category: "suscripcion",
        summary: "Suscripción detectada (datos de ejemplo, modo demostración).",
        fields: [{ key: "servicio", label: "Servicio", value: "Servicio de ejemplo", confidence: 0.4 }],
        suggestedEvents: [
          {
            title: "Próximo cobro de suscripción",
            eventType: "pago",
            date: inDays(30),
            dateKind: "sugerida",
            priority: "baja",
            reason: "Periodicidad mensual asumida como ejemplo.",
          },
        ],
      },
      justificante: {
        category: "justificante",
        summary: "Justificante de pago detectado (datos de ejemplo, modo demostración).",
        fields: [{ key: "importe", label: "Importe", value: "45,00 €", confidence: 0.4 }],
        suggestedEvents: [],
      },
      manual_producto: {
        category: "manual_producto",
        summary: "Manual de producto detectado (datos de ejemplo, modo demostración).",
        fields: [{ key: "producto", label: "Producto", value: "Producto de ejemplo", confidence: 0.3 }],
        suggestedEvents: [],
      },
      otro: {
        category: "otro",
        summary: "No se ha podido anticipar el tipo de documento en modo demostración.",
        fields: [],
        suggestedEvents: [],
      },
    };

    const base = byCategory[category];
    return { ...base, mode: "demo", possibleDuplicateHint: null };
  }
}

function guessCategory(filename: string): DocumentCategory {
  const map: [RegExp, DocumentCategory][] = [
    [/factura|recibo|ticket/, "factura"],
    [/garant/, "garantia"],
    [/contrato/, "contrato"],
    [/seguro|poliza|póliza/, "seguro"],
    [/suscripcion|suscripción|subscription/, "suscripcion"],
    [/justificante|pago|transferencia/, "justificante"],
    [/manual|instrucciones/, "manual_producto"],
  ];
  for (const [re, cat] of map) if (re.test(filename)) return cat;
  return "otro";
}
