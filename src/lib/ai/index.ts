import type { Assistant, DocumentAnalyzer, DraftWriter } from "./types";
import { DemoDocumentAnalyzer } from "./demo-document-analyzer";
import { AnthropicDocumentAnalyzer } from "./anthropic-document-analyzer";
import { DemoAssistant } from "./demo-assistant";
import { AnthropicAssistant } from "./anthropic-assistant";
import { DemoDraftWriter } from "./demo-draft-writer";
import { AnthropicDraftWriter } from "./anthropic-draft-writer";

// Capa de servicio intercambiable: el resto de la app pide un
// DocumentAnalyzer/Assistant sin saber si hay una clave de Anthropic real
// configurada. Sin ANTHROPIC_API_KEY, cae automáticamente al modo
// demostración — nunca se finge un análisis real.
export function getDocumentAnalyzer(): DocumentAnalyzer {
  const key = process.env.ANTHROPIC_API_KEY;
  return key ? new AnthropicDocumentAnalyzer(key) : new DemoDocumentAnalyzer();
}

export function getAssistant(): Assistant {
  const key = process.env.ANTHROPIC_API_KEY;
  return key ? new AnthropicAssistant(key) : new DemoAssistant();
}

export function getDraftWriter(): DraftWriter {
  const key = process.env.ANTHROPIC_API_KEY;
  return key ? new AnthropicDraftWriter(key) : new DemoDraftWriter();
}

export type { DocumentAnalyzer, Assistant } from "./types";
export * from "./types";
