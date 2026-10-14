"use client";

import { useActionState } from "react";
import { requestMagicLink, type MagicLinkState } from "./actions";

const initialState: MagicLinkState = { status: "idle" };

export default function LoginPage() {
  const [state, formAction, pending] = useActionState(requestMagicLink, initialState);

  return (
    <div className="flex flex-1 items-center justify-center bg-background px-4">
      <div className="w-full max-w-sm">
        <div className="mb-8 text-center">
          <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-2xl bg-brand text-white text-xl font-semibold">V</div>
          <h1 className="text-2xl font-semibold text-ink">Vence</h1>
          <p className="mt-1 text-sm text-ink-muted">Se ocupa de tus documentos para que no se te escape nada importante.</p>
        </div>

        <div className="rounded-2xl border border-borde bg-surface p-6 shadow-sm">
          {state.status === "sent" ? (
            <div className="text-center">
              <p className="text-sm font-medium text-ink">Revisa tu correo</p>
              <p className="mt-2 text-sm text-ink-muted">
                Te hemos enviado un enlace de acceso a <span className="font-medium text-ink">{state.message}</span>.
              </p>
            </div>
          ) : (
            <form action={formAction} className="space-y-4">
              <div>
                <label htmlFor="email" className="mb-1.5 block text-sm font-medium text-ink">
                  Correo electrónico
                </label>
                <input
                  id="email"
                  name="email"
                  type="email"
                  required
                  placeholder="tucorreo@ejemplo.com"
                  className="w-full rounded-xl border border-borde bg-surface px-3.5 py-2.5 text-sm text-ink outline-none transition focus:border-brand focus:ring-2 focus:ring-brand/20"
                />
              </div>
              {state.status === "error" && <p className="text-sm text-rojo-text">{state.message}</p>}
              <button
                type="submit"
                disabled={pending}
                className="w-full rounded-xl bg-brand px-4 py-2.5 text-sm font-medium text-white transition hover:bg-brand-strong disabled:opacity-60"
              >
                {pending ? "Enviando..." : "Enviar enlace de acceso"}
              </button>
              <p className="text-center text-xs text-ink-faint">Sin contraseñas: te enviamos un enlace de un solo uso.</p>
            </form>
          )}
        </div>
      </div>
    </div>
  );
}
