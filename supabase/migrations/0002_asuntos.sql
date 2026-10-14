-- Vence — motor de Asuntos (matters/cases).
-- Un Asunto es la unidad de trabajo real del usuario: "la lavadora que se
-- ha roto", "la devolución del pedido X". Documentos y tareas (events) son
-- piezas que cuelgan de un Asunto; un documento puede pertenecer a varios
-- asuntos (p.ej. una factura usada en una compra Y en una incidencia).

create type asunto_tipo as enum ('compra', 'devolucion', 'incidencia', 'poliza', 'contrato', 'documento_personal', 'gestion', 'otro');

create type asunto_estado as enum (
  'nuevo',
  'necesita_revision',
  'en_curso',
  'pendiente_usuario',
  'pendiente_tercero',
  'bloqueado',
  'listo_para_accion',
  'completado',
  'cerrado',
  'reabierto'
);

create type asunto_prioridad as enum ('alta', 'media', 'baja');

create table public.asuntos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  tipo asunto_tipo not null default 'otro',
  titulo text not null,
  objetivo text,
  estado asunto_estado not null default 'nuevo',
  prioridad asunto_prioridad not null default 'media',
  -- Motivo del bloqueo cuando estado = 'bloqueado'; nunca se infiere, lo
  -- escribe el usuario o una automatización explícita.
  bloqueo_motivo text,
  -- Qué debe ser verdad para poder cerrar el asunto (p. ej. "recibir el
  -- reembolso" o "confirmación por escrito del seguro"). Si está vacío,
  -- no se puede marcar como completado — ver confirm_cierre_requiere_criterio.
  criterio_cierre text,
  cerrado_en timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index asuntos_user_idx on public.asuntos (user_id, updated_at desc);

alter table public.asuntos enable row level security;
create policy "asuntos_all_own" on public.asuntos for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Un documento puede pertenecer a varios asuntos; 'role' distingue un
-- documento de partida (p. ej. la factura) de una evidencia de cierre
-- (p. ej. el email de confirmación del reembolso).
create type asunto_documento_role as enum ('documento', 'evidencia');

create table public.asunto_documentos (
  asunto_id uuid not null references public.asuntos(id) on delete cascade,
  document_id uuid not null references public.documents(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role asunto_documento_role not null default 'documento',
  created_at timestamptz not null default now(),
  primary key (asunto_id, document_id)
);

alter table public.asunto_documentos enable row level security;
create policy "asunto_documentos_all_own" on public.asunto_documentos for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Cronología legible del asunto: cada cambio de estado, documento añadido,
-- tarea creada o nota del usuario queda aquí para poder responder "qué ha
-- pasado con esto" sin reconstruirlo a partir de otras tablas.
create table public.asunto_actividad (
  id uuid primary key default gen_random_uuid(),
  asunto_id uuid not null references public.asuntos(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  tipo text not null,
  descripcion text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index asunto_actividad_asunto_idx on public.asunto_actividad (asunto_id, created_at desc);

alter table public.asunto_actividad enable row level security;
create policy "asunto_actividad_all_own" on public.asunto_actividad for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Las tareas/recordatorios (events) pueden colgar de un asunto. Nullable:
-- un recordatorio suelto (p. ej. "renovar el DNI") no necesita un asunto.
alter table public.events add column asunto_id uuid references public.asuntos(id) on delete set null;
create index events_asunto_idx on public.events (asunto_id);

-- No se puede cerrar/completar un asunto sin un criterio de cierre
-- explícito — automatiza la regla de la sección 8 ("no cierres un asunto
-- solo porque se ha pulsado un botón").
create function public.check_asunto_cierre()
returns trigger
language plpgsql
as $$
begin
  if new.estado in ('completado', 'cerrado') and (new.criterio_cierre is null or length(trim(new.criterio_cierre)) = 0) then
    raise exception 'No se puede cerrar un asunto sin un criterio de cierre explícito.';
  end if;
  if new.estado <> old.estado then
    insert into public.asunto_actividad (asunto_id, user_id, tipo, descripcion, metadata)
    values (new.id, new.user_id, 'cambio_estado', format('Estado cambiado de %s a %s', old.estado, new.estado), jsonb_build_object('de', old.estado, 'a', new.estado));
  end if;
  new.updated_at = now();
  return new;
end;
$$;

create trigger asuntos_before_update
  before update on public.asuntos
  for each row execute procedure public.check_asunto_cierre();
