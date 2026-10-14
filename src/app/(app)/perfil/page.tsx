import { createClient } from "@/lib/supabase/server";
import { PageHeader } from "@/components/ui/page-header";
import { ProfileForm } from "@/components/profile/profile-form";
import { AccountActions } from "@/components/profile/account-actions";

export default async function PerfilPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;

  const { data: profile } = await supabase.from("profiles").select("*").eq("id", user.id).single();

  return (
    <div>
      <PageHeader eyebrow="VENCE" title="Perfil" />
      <div className="mx-auto max-w-xl space-y-8 px-5 py-6 md:px-8">
        <section>
          <h2 className="mb-3 text-sm font-semibold text-ink">Datos y preferencias</h2>
          <ProfileForm email={user.email ?? ""} profile={profile} />
        </section>

        <section>
          <h2 className="mb-3 text-sm font-semibold text-ink">Privacidad y cuenta</h2>
          <AccountActions />
        </section>
      </div>
    </div>
  );
}
