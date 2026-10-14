import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { uploadAndAnalyzeDocument, createManualDocument, DocumentUploadError } from "@/lib/server/documents";
import type { DocumentCategory } from "@/lib/db/types";

export async function POST(request: Request) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "No autenticado." }, { status: 401 });

  const formData = await request.formData();
  const file = formData.get("file");

  try {
    if (file instanceof File) {
      const { documentId } = await uploadAndAnalyzeDocument(supabase, user.id, file);
      return NextResponse.json({ documentId });
    }

    const title = String(formData.get("title") ?? "").trim();
    const category = String(formData.get("category") ?? "otro") as DocumentCategory;
    const fieldsRaw = String(formData.get("fields") ?? "[]");
    if (!title) return NextResponse.json({ error: "El título es obligatorio." }, { status: 400 });

    const fields = JSON.parse(fieldsRaw) as { label: string; value: string }[];
    const { documentId } = await createManualDocument(supabase, user.id, { title, category, fields });
    return NextResponse.json({ documentId });
  } catch (err) {
    if (err instanceof DocumentUploadError) {
      return NextResponse.json({ error: err.message }, { status: 400 });
    }
    console.error(err);
    return NextResponse.json({ error: "Error inesperado al guardar el documento." }, { status: 500 });
  }
}
