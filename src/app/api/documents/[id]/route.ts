import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function DELETE(_request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id: documentId } = await params;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "No autenticado." }, { status: 401 });

  const { data: doc } = await supabase.from("documents").select("storage_path, user_id").eq("id", documentId).single();
  if (!doc || doc.user_id !== user.id) return NextResponse.json({ error: "No encontrado." }, { status: 404 });

  if (doc.storage_path) {
    await supabase.storage.from("documents").remove([doc.storage_path]);
  }
  await supabase.from("documents").delete().eq("id", documentId);

  await supabase.from("audit_log").insert({
    user_id: user.id,
    action: "document_deleted",
    target_table: "documents",
    target_id: documentId,
    metadata: {},
  });

  return NextResponse.json({ ok: true });
}

export async function PATCH(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id: documentId } = await params;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "No autenticado." }, { status: 401 });

  const body = (await request.json()) as { status?: "archivado" | "organizado" };
  const { error } = await supabase
    .from("documents")
    .update(body)
    .eq("id", documentId)
    .eq("user_id", user.id);

  if (error) return NextResponse.json({ error: error.message }, { status: 400 });
  return NextResponse.json({ ok: true });
}
