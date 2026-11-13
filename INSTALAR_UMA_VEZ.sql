-- HepaMap — rode ESTE arquivo UMA ÚNICA VEZ no SQL Editor do Supabase.
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
select id from auth.users where email = 'SEU-EMAIL-DE-LOGIN@exemplo.com'
on conflict do nothing;
