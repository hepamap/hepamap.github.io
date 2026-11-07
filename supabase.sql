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
