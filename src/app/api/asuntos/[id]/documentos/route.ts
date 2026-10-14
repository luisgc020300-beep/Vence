import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { linkDocument, AsuntoError } from "@/lib/server/asuntos";
import type { AsuntoDocumentoRole } from "@/lib/db/types";

export async function POST(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "No autenticado." }, { status: 401 });

  const body = (await request.json()) as { documentId: string; role?: AsuntoDocumentoRole };
  if (!body.documentId) return NextResponse.json({ error: "Falta el documento." }, { status: 400 });

  try {
    await linkDocument(supabase, user.id, id, body.documentId, body.role ?? "documento");
    return NextResponse.json({ ok: true });
  } catch (err) {
    if (err instanceof AsuntoError) return NextResponse.json({ error: err.message }, { status: 400 });
    console.error(err);
    return NextResponse.json({ error: "Error inesperado." }, { status: 500 });
  }
}
