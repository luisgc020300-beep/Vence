# Vence

> «Vence se ocupa de tus documentos y te ayuda a que no se te escape nada importante.»

Gestión administrativa personal con IA: sube facturas, garantías, contratos, seguros o
suscripciones; Vence extrae los datos importantes, propone recordatorios y responde
preguntas sobre tus documentos citando siempre la fuente.

## Stack

- **Next.js 16** (App Router, React 19, TypeScript) — web responsive, sidebar en escritorio y barra inferior en móvil.
- **Supabase** — Postgres (con Row Level Security por usuario), Auth (enlace de acceso por email, sin contraseñas) y Storage (bucket privado `documents`).
- **Anthropic Claude** (`@anthropic-ai/sdk`) — análisis de documentos (PDF/imagen) y asistente conversacional. **Opcional**: sin clave configurada, la app funciona en **modo demostración** con una capa de servicio intercambiable (`src/lib/ai/`) que nunca presenta datos de ejemplo como si fueran un análisis real.
- **Tailwind CSS v4** — tokens de color centralizados en `src/app/globals.css` (paleta: azul noche, azul principal, lavanda, ámbar, verde, rojo de alerta).

## Puesta en marcha

### 1. Clona dependencias

```bash
npm install
```

### 2. Crea el proyecto Supabase (gratis, sin tarjeta)

1. Entra en [supabase.com](https://supabase.com) y crea un proyecto nuevo (elige la región más cercana).
2. En **Project Settings → API**, copia `Project URL`, `anon public key` y `service_role key`.
3. En **Authentication → URL Configuration**, añade `http://localhost:3000/auth/callback` a las Redirect URLs (y la URL de producción cuando despliegues).
4. Ejecuta la migración inicial (crea las tablas, las políticas de RLS y el bucket de Storage):

   ```bash
   npx supabase login
   npx supabase link --project-ref <tu-project-ref>
   npx supabase db push
   ```

   (Alternativa sin CLI: pega el contenido de `supabase/migrations/0001_init.sql` en el **SQL Editor** del dashboard de Supabase y ejecútalo.)

### 3. Variables de entorno

Copia `.env.example` a `.env.local` y rellena:

```bash
cp .env.example .env.local
```

```
NEXT_PUBLIC_SUPABASE_URL=...
NEXT_PUBLIC_SUPABASE_ANON_KEY=...
SUPABASE_SERVICE_ROLE_KEY=...      # nunca lo expongas al cliente
ANTHROPIC_API_KEY=...              # opcional — sin esto, modo demostración
NEXT_PUBLIC_SITE_URL=http://localhost:3000
```

### 4. Arranca

```bash
npm run dev
```

Abre `http://localhost:3000`, introduce tu email y entra con el enlace que recibirás por correo (Supabase lo envía automáticamente, incluso en el plan gratuito).

## Qué funciona de verdad ahora mismo

- **Autenticación real** (enlace de acceso por email vía Supabase Auth) con aislamiento de datos por usuario (RLS en todas las tablas).
- **Subida de documentos** (PDF/JPG/PNG/WEBP, máx. 15 MB) a un bucket privado de Storage, o **alta manual** sin archivo.
- **Análisis automático**: con `ANTHROPIC_API_KEY` configurada, Claude lee el PDF/imagen de verdad (vía tool-use forzado, para una extracción JSON fiable) y propone categoría, campos y recordatorios con su propio razonamiento de fecha explícita/calculada/sugerida. Sin clave, un analizador de demostración determinista genera datos de ejemplo **siempre etiquetados como tal** en la interfaz.
- **Bandeja de revisión**: cada dato extraído tiene estado `detectado → confirmado/corregido`; los recordatorios propuestos se aprueban o descartan uno a uno antes de convertirse en tareas reales.
- **Calendario**: recordatorios agrupados por mes, con completar/posponer/cancelar y creación manual de tareas.
- **Asistente**: responde solo con el contexto real de tus documentos/eventos (nunca con conocimiento externo), cita las fuentes y marca `confident: false` cuando no tiene datos suficientes. En modo demostración responde con reglas simples sobre tus datos reales, no con un modelo.
- **Perfil**: preferencias de notificación, exportación completa de datos (JSON) y eliminación de cuenta (borra Storage + fila de Auth, con cascada sobre el resto de tablas).
- **Persistencia real**: todo sobrevive a recarga y a una nueva sesión (Postgres, no `localStorage`).

## Archivos principales

```
supabase/migrations/0001_init.sql   # esquema completo + RLS + bucket de Storage
src/lib/db/types.ts                 # tipos de la base de datos (a mano; regenerable con supabase gen types)
src/lib/ai/                         # capa de IA intercambiable (demo/real) — analizador de documentos + asistente
src/lib/server/documents.ts         # lógica de subida, análisis y alta manual
src/lib/supabase/{client,server,middleware}.ts  # clientes Supabase (browser/servidor/sesión)
src/app/(app)/                      # Inicio, Documentos, Calendario, Asistente, Perfil
src/app/api/                        # rutas de documentos, eventos, asistente y cuenta
src/components/                     # navegación (sidebar/bottom nav), UI compartida, diálogos
```

## Limitaciones conocidas (pendientes, no ocultas)

- **Sin búsqueda semántica**: el asistente usa los últimos documentos/eventos del usuario como contexto (hasta 40/60), no embeddings. Con un archivo grande, esto no escala — el siguiente paso natural es `pgvector` en Supabase.
- **Relaciones entre documentos**: el esquema las soporta (`document_relations`, `entities`), pero la detección de duplicados es solo por nombre de archivo + categoría, y no hay UI todavía para vincular documentos manualmente (p. ej. factura + garantía + manual de la misma compra).
- **Notificaciones por email**: el perfil permite configurar preferencias, pero no hay ningún envío automático todavía — falta un cron/Edge Function en Supabase que revise `events` próximos a vencer y dispare el email. No se afirma en ningún sitio de la UI que se envíen.
- **Vista de calendario**: es una lista cronológica agrupada por mes, no una cuadrícula mensual interactiva.
- **PDFs con múltiples páginas**: Claude los procesa como documento completo (hasta el límite de la API), pero no hay extracción de página/ubicación exacta para citarla en el asistente — las fuentes citan el documento, no el fragmento.

## Próximos tres pasos de mayor valor

1. **Notificaciones reales** — una Supabase Edge Function programada (`pg_cron` + `supabase functions`) que recorra `events` con `remind_days_before`/`notif_days_before` cumplido y envíe el email (Resend o el SMTP de Supabase).
2. **Búsqueda semántica (`pgvector`)** — embeddings de `documents.raw_text`/resúmenes para que el asistente escale más allá de "los últimos N documentos" y pueda razonar sobre un archivo grande.
3. **Vinculación de documentos de una misma compra** — UI para relacionar manualmente factura/garantía/manual (la tabla `document_relations` ya existe) y mostrarlo en el detalle del documento.
