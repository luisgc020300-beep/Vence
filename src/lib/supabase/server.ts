import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import type { Database } from "@/lib/db/types";

// Server-side client: lee/escribe cookies de sesión en Server Components,
// Server Actions y Route Handlers. En Server Components la escritura de
// cookies falla silenciosamente a propósito (Next.js no lo permite ahí);
// el middleware es quien realmente refresca la sesión en cada request.
export async function createClient() {
  const cookieStore = await cookies();

  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            for (const { name, value, options } of cookiesToSet) {
              cookieStore.set(name, value, options);
            }
          } catch {
            // Llamado desde un Server Component: ignorado, el middleware refresca la sesión.
          }
        },
      },
    },
  );
}

// Cliente con la service role key: solo para operaciones de servidor que
// deban saltarse RLS de forma controlada (p.ej. el worker de análisis de
// IA escribiendo resultados). Nunca se expone al cliente.
export function createServiceRoleClient() {
  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { cookies: { getAll: () => [], setAll: () => {} } },
  );
}
