-- SANA 2026-08-25 access, guest isolation, and admin management

alter table if exists public.users
  add column if not exists is_active boolean not null default false;

alter table if exists public.users
  add column if not exists expiry_date timestamptz;

alter table if exists public.users
  add column if not exists role text not null default 'user';

alter table if exists public.medications
  add column if not exists guest_id uuid;

alter table if exists public.doctors
  add column if not exists guest_id uuid;

alter table if exists public.pharmacies
  add column if not exists guest_id uuid;

alter table if exists public.documents
  add column if not exists guest_id uuid;

alter table if exists public.insurance_cards
  add column if not exists guest_id uuid;

alter table if exists public.medications
  add column if not exists photo_base64 text;

alter table if exists public.medications
  add column if not exists ringtone_path text;

alter table if exists public.medications
  add column if not exists description text default '';

alter table if exists public.medications
  add column if not exists reminder_time text default '';

alter table if exists public.medications
  add column if not exists quantity integer not null default 1;

alter table if exists public.documents
  add column if not exists file_type text not null default 'file';

-- Guest and active-user isolation.
-- Anonymous Supabase users receive a real auth.uid(), which is stored in guest_id.
alter table if exists public.medications enable row level security;
alter table if exists public.doctors enable row level security;
alter table if exists public.pharmacies enable row level security;
alter table if exists public.documents enable row level security;
alter table if exists public.insurance_cards enable row level security;

drop policy if exists "SANA isolated medications" on public.medications;
create policy "SANA isolated medications"
on public.medications
for all
using (
  auth.uid() = user_id
  or auth.uid() = guest_id
)
with check (
  auth.uid() = user_id
  or auth.uid() = guest_id
);

drop policy if exists "SANA isolated doctors" on public.doctors;
create policy "SANA isolated doctors"
on public.doctors
for all
using (
  auth.uid() = user_id
  or auth.uid() = guest_id
)
with check (
  auth.uid() = user_id
  or auth.uid() = guest_id
);

drop policy if exists "SANA isolated pharmacies" on public.pharmacies;
create policy "SANA isolated pharmacies"
on public.pharmacies
for all
using (
  auth.uid() = user_id
  or auth.uid() = guest_id
)
with check (
  auth.uid() = user_id
  or auth.uid() = guest_id
);

drop policy if exists "SANA isolated documents" on public.documents;
create policy "SANA isolated documents"
on public.documents
for all
using (
  auth.uid() = user_id
  or auth.uid() = guest_id
)
with check (
  auth.uid() = user_id
  or auth.uid() = guest_id
);

drop policy if exists "SANA isolated insurance" on public.insurance_cards;
create policy "SANA isolated insurance"
on public.insurance_cards
for all
using (
  auth.uid() = user_id
  or auth.uid() = guest_id
)
with check (
  auth.uid() = user_id
  or auth.uid() = guest_id
);

-- Admin check.
create or replace function public.sana_is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.users
    where id = auth.uid()
      and lower(coalesce(role, 'user')) = 'admin'
  );
$$;

revoke all on function public.sana_is_admin() from public;
grant execute on function public.sana_is_admin() to authenticated;

-- Admin user table.
create or replace function public.admin_list_users()
returns setof public.users
language sql
security definer
set search_path = public
as $$
  select u.*
  from public.users u
  where public.sana_is_admin()
  order by u.created_at desc;
$$;

revoke all on function public.admin_list_users() from public;
revoke all on function public.admin_list_users() from anon;
grant execute on function public.admin_list_users() to authenticated;

-- Admin activation/deactivation.
create or replace function public.admin_set_user_active(
  target_user uuid,
  activate boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  if not public.sana_is_admin() then
    raise exception 'Administrator authorization required';
  end if;

  if target_user is null then
    raise exception 'Target user is required';
  end if;

  if exists (
    select 1
    from public.users
    where id = target_user
      and lower(coalesce(role, 'user')) = 'admin'
  ) then
    raise exception 'Administrator accounts cannot be changed';
  end if;

  update public.users
  set is_active = activate
  where id = target_user;

  if not found then
    raise exception 'User account not found';
  end if;
end;
$$;

revoke all
on function public.admin_set_user_active(uuid, boolean)
from public;

revoke all
on function public.admin_set_user_active(uuid, boolean)
from anon;

grant execute
on function public.admin_set_user_active(uuid, boolean)
to authenticated;

-- Existing application RPC retained.
grant execute
on function public.admin_set_user_active(uuid, boolean)
to authenticated;
