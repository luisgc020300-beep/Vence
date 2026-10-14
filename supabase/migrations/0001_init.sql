-- Vence — esquema inicial
-- Todas las tablas usan RLS: cada usuario solo ve/edita sus propias filas.
-- auth.users es la tabla de Supabase Auth; profiles es 1:1 con ella.

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  locale text not null default 'es-ES',
  timezone text not null default 'Europe/Madrid',
  notif_email boolean not null default true,
  notif_days_before smallint not null default 7,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles_select_own" on public.profiles for select using (id = auth.uid());
create policy "profiles_update_own" on public.profiles for update using (id = auth.uid());
create policy "profiles_insert_own" on public.profiles for insert with check (id = auth.uid());

-- Crea el profile automáticamente al registrarse.
create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, new.email);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ---------------------------------------------------------------------
-- documents
-- ---------------------------------------------------------------------
create type document_status as enum ('pendiente_analisis', 'analizando', 'en_revision', 'organizado', 'archivado');
create type document_category as enum ('factura', 'garantia', 'contrato', 'seguro', 'suscripcion', 'justificante', 'manual_producto', 'otro');
create type analysis_mode as enum ('demo', 'real', 'manual');

create table public.documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  original_filename text not null,
  storage_path text,
  mime_type text,
  size_bytes bigint,
  category document_category not null default 'otro',
  status document_status not null default 'pendiente_analisis',
  analysis_mode analysis_mode not null default 'manual',
  summary text,
  raw_text text,
  is_duplicate_of uuid references public.documents(id),
  -- Recordatorios que el analizador ha propuesto pero el usuario aún no ha
  -- aprobado. Se vacía (y se vuelcan filas reales en "events") cuando el
  -- usuario confirma la revisión en la bandeja de entrada.
  pending_events jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index documents_user_idx on public.documents (user_id, created_at desc);

alter table public.documents enable row level security;
create policy "documents_all_own" on public.documents for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------
-- extracted_fields — cada dato extraído de un documento, con su propio
-- estado de confianza/revisión (detectado / confirmado / corregido).
-- ---------------------------------------------------------------------
create type field_status as enum ('detectado', 'confirmado', 'corregido');
create type field_source as enum ('ia', 'manual');

create table public.extracted_fields (
  id uuid primary key default gen_random_uuid(),
  document_id uuid not null references public.documents(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  field_key text not null,
  field_label text not null,
  field_value text,
  confidence numeric(4,3),
  status field_status not null default 'detectado',
  source field_source not null default 'ia',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index extracted_fields_document_idx on public.extracted_fields (document_id);

alter table public.extracted_fields enable row level security;
create policy "extracted_fields_all_own" on public.extracted_fields for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------
-- events — vencimientos, renovaciones, tareas y recordatorios.
-- ---------------------------------------------------------------------
create type event_type as enum ('vencimiento', 'renovacion', 'devolucion', 'garantia', 'revision', 'pago', 'manual');
create type date_kind as enum ('explicita', 'calculada', 'sugerida');
create type event_priority as enum ('alta', 'media', 'baja');
create type event_status as enum ('pendiente', 'completada', 'pospuesta', 'cancelada');

create table public.events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  document_id uuid references public.documents(id) on delete set null,
  title text not null,
  notes text,
  event_type event_type not null default 'manual',
  event_date date not null,
  date_kind date_kind not null default 'explicita',
  priority event_priority not null default 'media',
  status event_status not null default 'pendiente',
  remind_days_before smallint,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index events_user_date_idx on public.events (user_id, event_date);

alter table public.events enable row level security;
create policy "events_all_own" on public.events for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------
-- entities — productos, proveedores, viviendas, servicios mencionados en
-- los documentos, para poder relacionar varios documentos entre sí.
-- ---------------------------------------------------------------------
create type entity_type as enum ('producto', 'proveedor', 'vivienda', 'servicio');

create table public.entities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  entity_type entity_type not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.entities enable row level security;
create policy "entities_all_own" on public.entities for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create table public.document_entities (
  document_id uuid not null references public.documents(id) on delete cascade,
  entity_id uuid not null references public.entities(id) on delete cascade,
  primary key (document_id, entity_id)
);

alter table public.document_entities enable row level security;
create policy "document_entities_select" on public.document_entities for select using (
  exists (select 1 from public.documents d where d.id = document_id and d.user_id = auth.uid())
);
create policy "document_entities_modify" on public.document_entities for all using (
  exists (select 1 from public.documents d where d.id = document_id and d.user_id = auth.uid())
) with check (
  exists (select 1 from public.documents d where d.id = document_id and d.user_id = auth.uid())
);

-- document_relations — p.ej. factura <-> garantía <-> manual de la misma compra.
create table public.document_relations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  document_id uuid not null references public.documents(id) on delete cascade,
  related_document_id uuid not null references public.documents(id) on delete cascade,
  relation_label text not null default 'relacionado',
  created_at timestamptz not null default now(),
  constraint document_relations_no_self check (document_id <> related_document_id)
);

alter table public.document_relations enable row level security;
create policy "document_relations_all_own" on public.document_relations for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------
-- conversations / messages — asistente de IA con fuentes citadas.
-- ---------------------------------------------------------------------
create type message_role as enum ('user', 'assistant');

create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null default 'Nueva conversación',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.conversations enable row level security;
create policy "conversations_all_own" on public.conversations for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role message_role not null,
  content text not null,
  is_demo boolean not null default false,
  created_at timestamptz not null default now()
);

create index messages_conversation_idx on public.messages (conversation_id, created_at);

alter table public.messages enable row level security;
create policy "messages_all_own" on public.messages for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create table public.message_sources (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.messages(id) on delete cascade,
  document_id uuid not null references public.documents(id) on delete cascade,
  snippet text,
  user_id uuid not null references auth.users(id) on delete cascade
);

alter table public.message_sources enable row level security;
create policy "message_sources_all_own" on public.message_sources for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------
-- audit_log — historial de acciones relevantes (creación, confirmación,
-- descarte de propuestas, exportación/eliminación de datos).
-- ---------------------------------------------------------------------
create table public.audit_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  action text not null,
  target_table text,
  target_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.audit_log enable row level security;
create policy "audit_log_select_own" on public.audit_log for select using (user_id = auth.uid());
create policy "audit_log_insert_own" on public.audit_log for insert with check (user_id = auth.uid());

-- ---------------------------------------------------------------------
-- Storage: bucket privado para los archivos originales.
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('documents', 'documents', false)
on conflict (id) do nothing;

create policy "documents_bucket_select_own"
  on storage.objects for select
  using (bucket_id = 'documents' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "documents_bucket_insert_own"
  on storage.objects for insert
  with check (bucket_id = 'documents' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "documents_bucket_delete_own"
  on storage.objects for delete
  using (bucket_id = 'documents' and (storage.foldername(name))[1] = auth.uid()::text);
