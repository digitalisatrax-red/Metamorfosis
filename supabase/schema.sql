-- Metamorfosis: datos colaborativos de los predios
create table if not exists public.predio_edits (
  predio_id text primary key,
  properties jsonb not null default '{}'::jsonb,
  geometry jsonb,
  annotations jsonb not null default '[]'::jsonb,
  optioned boolean not null default false,
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now()
);

alter table public.predio_edits enable row level security;
grant select on public.predio_edits to anon;
grant select, insert, update on public.predio_edits to authenticated;

-- Lectura publica: el mapa muestra las ediciones sin autenticarse
drop policy if exists "Public can read edits" on public.predio_edits;
create policy "Public can read edits"
  on public.predio_edits for select to anon
  using (true);

drop policy if exists "Authorized Metamorfosis users can read edits" on public.predio_edits;
create policy "Authorized Metamorfosis users can read edits"
  on public.predio_edits for select to authenticated
  using ((auth.jwt() ->> 'email') in ('jorgeruiz@fcvcol.org', 'kellyorozco@fcvcol.org'));

drop policy if exists "Authorized Metamorfosis users can insert edits" on public.predio_edits;
create policy "Authorized Metamorfosis users can insert edits"
  on public.predio_edits for insert to authenticated
  with check ((auth.jwt() ->> 'email') in ('jorgeruiz@fcvcol.org', 'kellyorozco@fcvcol.org'));

drop policy if exists "Authorized Metamorfosis users can update edits" on public.predio_edits;
create policy "Authorized Metamorfosis users can update edits"
  on public.predio_edits for update to authenticated
  using ((auth.jwt() ->> 'email') in ('jorgeruiz@fcvcol.org', 'kellyorozco@fcvcol.org'))
  with check ((auth.jwt() ->> 'email') in ('jorgeruiz@fcvcol.org', 'kellyorozco@fcvcol.org'));

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'predio_edits'
  ) then
    alter publication supabase_realtime add table public.predio_edits;
  end if;
end $$;
