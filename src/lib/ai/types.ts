import type { DocumentCategory, DateKind, EventPriority, EventType } from "@/lib/db/types";

export type AnalysisProviderMode = "demo" | "real";

export interface ExtractedFieldDraft {
  key: string;
  label: string;
  value: string;
  /** 0-1. El analizador demo siempre usa un valor fijo bajo para no aparentar certeza real. */
  confidence: number;
}

export interface SuggestedEventDraft {
  title: string;
  eventType: EventType;
  /** ISO yyyy-mm-dd */
  date: string;
  dateKind: DateKind;
  priority: EventPriority;
  reason: string;
}

export interface DocumentAnalysisResult {
  mode: AnalysisProviderMode;
  category: DocumentCategory;
  summary: string;
  fields: ExtractedFieldDraft[];
  suggestedEvents: SuggestedEventDraft[];
  possibleDuplicateHint: string | null;
}

export interface DocumentAnalyzerInput {
  filename: string;
  mimeType: string;
  /** Contenido binario del archivo, para los analizadores reales (PDF/imagen). */
  bytes: Buffer;
}

export interface DocumentAnalyzer {
  readonly mode: AnalysisProviderMode;
  analyze(input: DocumentAnalyzerInput): Promise<DocumentAnalysisResult>;
}

export interface AssistantSource {
  documentId: string;
  documentName: string;
  snippet: string;
}

export interface AssistantAnswer {
  mode: AnalysisProviderMode;
  content: string;
  sources: AssistantSource[];
  confident: boolean;
}

export interface AssistantDocumentContext {
  id: string;
  filename: string;
  category: string;
  summary: string | null;
  fields: { label: string; value: string | null }[];
}

export interface AssistantEventContext {
  id: string;
  title: string;
  date: string;
  type: string;
  status: string;
}

export interface Assistant {
  readonly mode: AnalysisProviderMode;
  ask(question: string, context: { documents: AssistantDocumentContext[]; events: AssistantEventContext[] }): Promise<AssistantAnswer>;
}

export interface DraftRequestContext {
  asuntoTitulo: string;
  asuntoObjetivo: string | null;
  asuntoTipo: string;
  documents: AssistantDocumentContext[];
}

export interface DraftResult {
  mode: AnalysisProviderMode;
  subject: string;
  body: string;
}

export interface DraftWriter {
  readonly mode: AnalysisProviderMode;
  draft(context: DraftRequestContext): Promise<DraftResult>;
}
