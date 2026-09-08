-- ============================================================
-- SANA
-- 20260817_sana_admin.sql
--
-- ADMIN / ROLE STANDARDIZATION
--
-- Responsibilities:
--   1. Server-side administrator detection
--   2. Initial administrator seed
--   3. Secure administrator user listing
--   4. Administrator permissions
--
-- Subscription activation/payment confirmation is handled by:
--
--   20260822_admin_confirm_payment.sql
--
-- Subscription expiration is also finalized there.
--
-- IMPORTANT:
--   This migration NEVER deletes customer data.
-- ============================================================


-- ============================================================
-- 1. ADMIN CHECK
--
-- The database is the source of truth.
--
-- auth.uid()
--     ↓
-- public.users.id
--     ↓
-- public.users.role = 'admin'
-- ============================================================

create or replace function public.sana_is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.users u
    where u.id = (select auth.uid())
      and lower(coalesce(u.role, 'user')) = 'admin'
  );
$$;


-- ============================================================
-- 2. ADMIN CHECK PERMISSIONS
-- ============================================================

revoke all
on function public.sana_is_admin()
from public;


revoke all
on function public.sana_is_admin()
from anon;


grant execute
on function public.sana_is_admin()
to authenticated;


-- ============================================================
-- 3. INITIAL ADMIN SEED
--
-- This only grants the admin role to the existing account.
--
-- Runtime authorization does NOT depend on email.
-- Runtime authorization uses:
--
--     users.id
--     users.role
--
-- The email below is only for the initial installation.
-- ============================================================

insert into public.users (
  id,
  name,
  email,
  phone,
  created_at,
  is_active,
  expiry_date,
  role
)
select
  au.id,
  coalesce(
    au.raw_user_meta_data->>'name',
    ''
  ),
  au.email,
  coalesce(
    au.raw_user_meta_data->>'phone',
    ''
  ),
  coalesce(
    au.created_at,
    now()
  ),
  true,
  null,
  'admin'
from auth.users au
where lower(
  coalesce(au.email, '')
) = 'malazjanbeih@gmail.com'
on conflict (id)
do update set
  role = 'admin',
  is_active = true,
  expiry_date = null;


-- ============================================================
-- 4. ADMIN USER LIST
--
-- This is read-only.
--
-- Admins can see customers.
-- Customers cannot call this successfully.
--
-- Subscription status comes from user_subscriptions.
-- ============================================================

create or replace function public.admin_list_users()
returns table (
  id uuid,
  name text,
  email text,
  phone text,
  joining_date timestamptz,
  status text,
  expires_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    u.id,
    coalesce(u.name, ''),
    coalesce(u.email, ''),
    coalesce(u.phone, ''),
    u.created_at,
    coalesce(
      us.status,
      'pending'
    ),
    us.expires_at
  from public.users u
  left join public.user_subscriptions us
    on us.user_id = u.id
  where public.sana_is_admin()
    and lower(
      coalesce(u.role, 'user')
    ) <> 'admin'
  order by u.created_at desc;
$$;


-- ============================================================
-- 5. ADMIN USER LIST PERMISSIONS
-- ============================================================

revoke all
on function public.admin_list_users()
from public;


revoke all
on function public.admin_list_users()
from anon;


grant execute
on function public.admin_list_users()
to authenticated;


-- ============================================================
-- 6. INDEXES
-- ============================================================

create index if not exists
  user_subscriptions_user_id_idx
on public.user_subscriptions (
  user_id
);


create index if not exists
  user_subscriptions_status_idx
on public.user_subscriptions (
  status
);


create index if not exists
  user_subscriptions_expires_at_idx
on public.user_subscriptions (
  expires_at
);


-- ============================================================
-- 7. REMOVE LEGACY DESTRUCTIVE EXPIRATION JOB
--
-- Expiration must NEVER delete:
--
--   medications
--   doctors
--   pharmacies
--   documents
--   insurance cards
--   application data
--   user profile data
--
-- Only subscription/access state may change.
-- ============================================================

do $$
begin

  if exists (
    select 1
    from pg_extension
    where extname = 'pg_cron'
  ) then

    if exists (
      select 1
      from cron.job
      where jobname = 'sana-delete-expired-data'
    ) then

      perform cron.unschedule(
        'sana-delete-expired-data'
      );

    end if;

  end if;

end;
$$;


-- ============================================================
-- 8. REMOVE LEGACY DESTRUCTIVE FUNCTION
--
-- Do NOT create a replacement here.
--
-- Final expiration logic belongs to the newer migration:
--
--   20260822_admin_confirm_payment.sql
-- ============================================================

drop function if exists
  public.delete_expired_sana_data();


-- ============================================================
-- 9. SAFETY VERIFICATION
-- ============================================================

do $$
begin

  if not exists (
    select 1
    from pg_proc p
    join pg_namespace n
      on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'sana_is_admin'
  ) then

    raise exception
      'sana_is_admin() was not created';

  end if;


  if not exists (
    select 1
    from pg_proc p
    join pg_namespace n
      on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'admin_list_users'
  ) then

    raise exception
      'admin_list_users() was not created';

  end if;

end;
$$;


-- ============================================================
-- END OF MIGRATION
-- ============================================================