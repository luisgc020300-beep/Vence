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

## Principio de producto: Asuntos, no solo documentos

Vence no es un archivador. Un **Asunto** (`asuntos`) es la unidad de trabajo real —
"la lavadora que se ha roto", "la devolución del pedido X"— con estado, objetivo,
documentos y evidencias vinculadas, próximos pasos (tareas) y una cronología de
actividad. Un documento puede pertenecer a varios asuntos (p. ej. una factura
usada en una compra y, más tarde, en una incidencia).

Estados de un asunto: `nuevo → necesita_revision/en_curso → pendiente_usuario/
pendiente_tercero/bloqueado → listo_para_accion → completado → cerrado` (con
`reabierto` disponible siempre). Las transiciones incoherentes están bloqueadas
en servidor (`ASUNTO_TRANSICIONES` + `changeEstado`), y **no se puede completar
ni cerrar un asunto sin un criterio de cierre explícito** — lo impone un trigger
de Postgres (`check_asunto_cierre`), no solo la interfaz.

## Qué funciona de verdad ahora mismo

- **Autenticación real** (enlace de acceso por email vía Supabase Auth) con aislamiento de datos por usuario (RLS en todas las tablas).
- **Subida de documentos** (PDF/JPG/PNG/WEBP, máx. 15 MB) a un bucket privado de Storage, o **alta manual** sin archivo.
- **Análisis automático**: con `ANTHROPIC_API_KEY` configurada, Claude lee el PDF/imagen de verdad (vía tool-use forzado, para una extracción JSON fiable) y propone categoría, campos y recordatorios con su propio razonamiento de fecha explícita/calculada/sugerida. Sin clave, un analizador de demostración determinista genera datos de ejemplo **siempre etiquetados como tal** en la interfaz.
- **Bandeja de revisión**: cada dato extraído tiene estado `detectado → confirmado/corregido`; los recordatorios propuestos se aprueban o descartan uno a uno antes de convertirse en tareas reales.
- **Motor de Asuntos**: crear un asunto desde un documento o desde cero, vincular más documentos/evidencias, crear tareas vinculadas, avanzar el estado (con bloqueo de transiciones incoherentes y criterio de cierre obligatorio), cronología de actividad auditable, y un generador de **borradores de comunicación con IA** (reclamaciones, solicitudes) que **nunca se envían solos** — quedan para que el usuario los revise y los envíe por su cuenta.
- **Calendario**: recordatorios agrupados por mes, con completar/posponer/cancelar y creación manual de tareas (sueltas o vinculadas a un asunto).
- **Asistente**: responde solo con el contexto real de tus documentos/eventos (nunca con conocimiento externo), cita las fuentes y marca `confident: false` cuando no tiene datos suficientes. En modo demostración responde con reglas simples sobre tus datos reales, no con un modelo.
- **Perfil**: preferencias de notificación, exportación completa de datos (JSON) y eliminación de cuenta (borra Storage + fila de Auth, con cascada sobre el resto de tablas).
- **Persistencia real**: todo sobrevive a recarga y a una nueva sesión (Postgres, no `localStorage`).

## Archivos principales

```
supabase/migrations/0001_init.sql   # documentos, campos extraídos, eventos, RLS + bucket de Storage
supabase/migrations/0002_asuntos.sql # motor de Asuntos: tabla, cronología, trigger de cierre, asunto_id en events
src/lib/db/types.ts                 # tipos de la base de datos (a mano; regenerable con supabase gen types)
src/lib/ai/                         # capa de IA intercambiable (demo/real) — analizador de documentos, asistente, redactor de borradores
src/lib/server/documents.ts         # lógica de subida, análisis y alta manual
src/lib/server/asuntos.ts           # crear asunto, vincular documento/evidencia, cambiar estado (con validación de transición + criterio de cierre)
src/lib/supabase/{client,server,middleware}.ts  # clientes Supabase (browser/servidor/sesión)
src/app/(app)/                      # Inicio, Documentos, Calendario, Asistente, Perfil + Asuntos (accesible desde Inicio/Documentos, sin pestaña propia)
src/app/api/                        # rutas de documentos, asuntos, eventos, asistente y cuenta
src/components/                     # navegación (sidebar/bottom nav), UI compartida, diálogos
```

## Diagnóstico honesto / limitaciones conocidas (pendientes, no ocultas)

- **Nada de esto se ha probado en ejecución real todavía**: no hay proyecto Supabase conectado en este entorno (solo placeholders en `.env.local` para poder compilar). `tsc`, `eslint` y `next build` pasan limpios; falta la prueba manual guiada con un proyecto real.
- **Cero pruebas automatizadas**: el prompt de producto pide una matriz extensa (documentos, asuntos, fechas, automatizaciones, seguridad). No existe ninguna todavía — no se afirma que "todo esté probado".
- **Sin investigación de mercado/competencia ni modelo de negocio**: sección pendiente del brief, requiere búsqueda web dedicada y no se ha hecho.
- **Sin métricas de producto instrumentadas** (tiempo de captura a revisión, % de campos corregidos, etc.).
- **Automatización de un solo nivel**: solo existen las propuestas de la sección "Nivel 1" (clasificar, sugerir campos/fechas/tareas, generar un borrador). No hay disparadores automáticos por eventos, reintentos ni ejecución de integraciones externas (Nivel 2/3 del brief) — intencionadamente, para no simular algo que no existe.
- **Sin búsqueda semántica**: el asistente usa los últimos documentos/eventos del usuario como contexto (hasta 40/60), no embeddings. Con un archivo grande, esto no escala — el siguiente paso natural es `pgvector` en Supabase.
- **Sin importación de correo ni calendarios externos** (Fase 2/3 de integraciones del brief, no iniciada).
- **Notificaciones por email**: el perfil permite configurar preferencias, pero no hay ningún envío automático todavía — falta un cron/Edge Function en Supabase. No se afirma en ningún sitio de la UI que se envíen.
- **Vista de calendario**: es una lista cronológica agrupada por mes, no una cuadrícula mensual interactiva.

## Próximos tres pasos de mayor valor

1. **Probar de verdad contra un proyecto Supabase real** — crear el proyecto, ejecutar las migraciones, recorrer el flujo completo descrito en la sección 7 (compra → asunto → documentos → tarea → borrador → cierre) y corregir lo que falle. Todo lo construido hasta ahora solo ha pasado comprobaciones estáticas.
2. **Primera pasada de pruebas automatizadas** — al menos los casos de la sección 17 más críticos: aislamiento de datos entre usuarios (RLS), no poder cerrar un asunto sin criterio, transición de estado inválida rechazada.
3. **Notificaciones reales + búsqueda semántica (`pgvector`)** — son los dos huecos que más limitan que el producto funcione sin supervisión constante del usuario.
