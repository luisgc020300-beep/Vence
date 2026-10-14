import { NextResponse } from "next/server";
import { createClient, createServiceRoleClient } from "@/lib/supabase/server";

export async function PATCH(request: Request) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "No autenticado." }, { status: 401 });

  const body = (await request.json()) as {
    display_name?: string;
    timezone?: string;
    locale?: string;
    notif_email?: boolean;
    notif_days_before?: number;
  };

  const { error } = await supabase.from("profiles").update(body).eq("id", user.id);
  if (error) return NextResponse.json({ error: error.message }, { status: 400 });
  return NextResponse.json({ ok: true });
}

// Elimina la cuenta y todos sus datos: primero los archivos del Storage
// (el borrado en cascada de las tablas lo hace Postgres al eliminar la
// fila de auth.users, pero los objetos de Storage no se limpian solos),
// después el usuario de Auth (requiere la service role key).
export async function DELETE() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "No autenticado." }, { status: 401 });

  const { data: documents } = await supabase.from("documents").select("storage_path").eq("user_id", user.id);
  const paths = (documents ?? []).map((d) => d.storage_path).filter((p): p is string => !!p);
  if (paths.length > 0) {
    await supabase.storage.from("documents").remove(paths);
  }

  const admin = createServiceRoleClient();
  const { error } = await admin.auth.admin.deleteUser(user.id);
  if (error) return NextResponse.json({ error: error.message }, { status: 500 });

  return NextResponse.json({ ok: true });
}
