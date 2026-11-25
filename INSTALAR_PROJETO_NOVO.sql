-- HepaMap — INSTALAÇÃO COMPLETA num projeto Supabase NOVO.
-- Rode tudo de uma vez no SQL Editor. Antes, troque o e-mail da linha marcada com <<< pelo login que você criou.

-- HepaMap v3 — rode tudo no SQL Editor do Supabase (pode rodar mais de uma vez)

create table if not exists public.respostas (
  id                bigint generated always as identity primary key,
  criado_em         timestamptz not null default now(),
  cidade            text not null default 'Araraquara',
  bairro            text not null,
  faixa             text,
  sexo              text,
  sexo_sem_protecao text,
  seringa           text,
  objeto_cortante   text,
  sintomas          text[] default '{}',
  contato           text,
  sintomas_contato  text[] default '{}',
  exame             text,
  vacina            text,
  pontos            int default 0
);
alter table public.respostas enable row level security;

-- Quem responde (anônimo) só ENVIA: não lê, não altera, não apaga.
drop policy if exists "formulario envia" on public.respostas;
create policy "formulario envia" on public.respostas for insert to anon
  with check (cidade = 'Araraquara' and char_length(bairro) between 2 and 60 and pontos between 0 and 60);

-- Só agentes logados leem.
drop policy if exists "agentes leem" on public.respostas;
create policy "agentes leem" on public.respostas for select to authenticated using (true);

-- Coordenadas dos bairros (o app preenche sozinho na 1ª vez que vê um bairro novo)
create table if not exists public.bairros_geo (
  nome text primary key,
  lat  double precision not null,
  lng  double precision not null
);
alter table public.bairros_geo enable row level security;
drop policy if exists "agentes geo" on public.bairros_geo;
create policy "agentes geo" on public.bairros_geo for all to authenticated using (true) with check (true);

-- Tempo real: o app recebe cada resposta na hora
do $$ begin
  alter publication supabase_realtime add table public.respostas;
exception when duplicate_object then null; end $$;

-- Depois disso, toda atualização de banco é feita pelo botão "Atualizar" no app.

create table if not exists public.hm_admins (user_id uuid primary key);
create table if not exists public.hm_migracoes (id text primary key, aplicada_em timestamptz not null default now());
alter table public.hm_admins enable row level security;
alter table public.hm_migracoes enable row level security;
drop policy if exists "ver migracoes" on public.hm_migracoes;
create policy "ver migracoes" on public.hm_migracoes for select to authenticated using (true);

create or replace function public.hm_sou_admin() returns boolean
language sql security definer set search_path = public stable as $$
  select exists(select 1 from hm_admins where user_id = auth.uid());
$$;

-- Aplica uma atualização de banco publicada no GitHub. Só administradores.
create or replace function public.hm_aplicar(p_id text, p_sql text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not exists(select 1 from hm_admins where user_id = auth.uid()) then
    raise exception 'Sem permissão de administrador';
  end if;
  if exists(select 1 from hm_migracoes where id = p_id) then return; end if;
  execute p_sql;
  insert into hm_migracoes(id) values (p_id);
end $$;

revoke all on function public.hm_aplicar(text, text) from public, anon;
grant execute on function public.hm_aplicar(text, text) to authenticated;
grant execute on function public.hm_sou_admin() to authenticated;

-- Torna administrador o usuário com este e-mail (troque pelo e-mail de login criado no Supabase).
insert into public.hm_admins(user_id)
select id from auth.users where email = 'admin@hepamap.example' -- <<< troque se usar outro e-mail
on conflict do nothing;

insert into public.hm_migracoes(id) values ('001_base') on conflict do nothing;
