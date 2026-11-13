-- HepaMap — trocar o login de administrador.
-- 1) Crie antes o usuário novo em Authentication > Users (com Auto Confirm User).
-- 2) Troque o e-mail abaixo pelo e-mail novo e rode no SQL Editor.
insert into public.hm_admins(user_id)
select id from auth.users where email = 'admin@hepamap.example'
on conflict do nothing;

-- 3) Remove da lista de administradores quem não existe mais
--    (rode depois de apagar o usuário antigo).
delete from public.hm_admins where user_id not in (select id from auth.users);
