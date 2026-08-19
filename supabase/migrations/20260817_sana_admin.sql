create or replace function public.admin_list_users()
returns table(id uuid,name text,email text,phone text,joining_date timestamptz,status text,expires_at timestamptz)
language sql security definer set search_path=public,auth as $$
select u.id,coalesce(u.raw_user_meta_data->>'name',''),u.email,coalesce(u.raw_user_meta_data->>'phone',''),u.created_at,coalesce(s.status,'pending'),s.expires_at
from auth.users u left join public.user_subscriptions s on s.user_id=u.id
where lower(coalesce((select email from auth.users where id=auth.uid()),''))='malazjanbeih@gmail.com'
order by u.created_at desc $$;
revoke all on function public.admin_list_users() from public;
grant execute on function public.admin_list_users() to authenticated;
create or replace function public.activate_annual_subscription(target_user_id uuid)
returns void language plpgsql security definer set search_path=public,auth as $$
begin
if lower(coalesce((select email from auth.users where id=auth.uid()),''))<>'malazjanbeih@gmail.com' then raise exception 'admin only'; end if;
insert into public.user_subscriptions(user_id,user_email,status,activated_at,expires_at,reminder_20day_sent)
select id,email,'active',now(),now()+interval '365 days',false from auth.users where id=target_user_id
on conflict(user_id) do update set status='active',activated_at=now(),expires_at=now()+interval '365 days',reminder_20day_sent=false;
end $$;
