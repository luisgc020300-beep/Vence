import { notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { DocumentReview } from "@/components/documents/document-review";

export default async function DocumentDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;

  const { data: document } = await supabase.from("documents").select("*").eq("id", id).eq("user_id", user.id).single();
  if (!document) notFound();

  const { data: fields } = await supabase.from("extracted_fields").select("*").eq("document_id", id).order("created_at", { ascending: true });

  let fileUrl: string | null = null;
  if (document.storage_path) {
    const { data } = await supabase.storage.from("documents").createSignedUrl(document.storage_path, 3600);
    fileUrl = data?.signedUrl ?? null;
  }

  let duplicateOf: { id: string; original_filename: string } | null = null;
  if (document.is_duplicate_of) {
    const { data } = await supabase.from("documents").select("id, original_filename").eq("id", document.is_duplicate_of).single();
    duplicateOf = data ?? null;
  }

  const { data: rawAsuntoLinks } = await supabase.from("asunto_documentos").select("role, asuntos(id, titulo, estado)").eq("document_id", id);
  const asuntoLinks = (rawAsuntoLinks ?? []) as unknown as { asuntos: { id: string; titulo: string; estado: string } | null }[];
  const asuntos = asuntoLinks.map((l) => l.asuntos).filter((a): a is { id: string; titulo: string; estado: string } => !!a);

  return <DocumentReview document={document} fields={fields ?? []} fileUrl={fileUrl} duplicateOf={duplicateOf} asuntos={asuntos} />;
}
