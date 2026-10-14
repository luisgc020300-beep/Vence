import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  /* config options here */
  // Desactivado: toda la app es contenido autenticado por sesión (cookies
  // de Supabase en cada request), no estático — Cache Components exigiría
  // envolver cada pantalla en Suspense sin ningún beneficio real aquí.
  turbopack: {
    rules: {
      "*.css": {
        loaders: ["@tailwindcss/turbopack"],
        as: "*.css",
      },
    },
  },
};

export default nextConfig;
