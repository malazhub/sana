-- ============================================================
-- SANA
-- 20260823_admin_deactivate_user.sql
--
-- ADMIN USER DEACTIVATION
--
-- Purpose:
--   Allow an administrator to manually deactivate a customer
--   without deleting any customer data.
--
-- Requirements:
--   public.users
--   public.user_subscriptions
--   public.sana_is_admin()
--
-- Flutter contract:
--
--   admin_deactivate_user(
--     target_user_id
--   )
--
-- Security:
--   - Authentication is required.
--   - Only users.role = 'admin' may execute the operation.
--   - Administrators cannot deactivate another administrator.
--   - Customer data is NEVER deleted.
--   - Medical/application data is NEVER deleted.
-- ============================================================


-- ============================================================
-- 1. ADMIN DEACTIVATION RPC
-- ============================================================

create or replace function public.admin_deactivate_user(
  target_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  caller_id uuid;
  target_role text;
begin

  -- ==========================================================
  -- 1.1 AUTHENTICATION
  -- ==========================================================

  caller_id := auth.uid();

  if caller_id is null then
    raise exception 'Authentication required';
  end if;


  -- ==========================================================
  -- 1.2 ADMIN AUTHORIZATION
  -- ==========================================================

  if not public.sana_is_admin() then
    raise exception
      'Administrator authorization required';
  end if;


  -- ==========================================================
  -- 1.3 VALIDATE TARGET
  -- ==========================================================

  if target_user_id is null then
    raise exception 'Customer is required';
  end if;


  -- ==========================================================
  -- 1.4 VERIFY CUSTOMER EXISTS
  --
  -- Administrators cannot deactivate administrators.
  -- ==========================================================

  select lower(
    coalesce(u.role, 'user')
  )
  into target_role
  from public.users u
  where u.id = target_user_id;


  if not found then
    raise exception 'Customer account not found';
  end if;


  if target_role = 'admin' then
    raise exception
      'Administrator accounts cannot be deactivated';
  end if;


  -- ==========================================================
  -- 1.5 DEACTIVATE SUBSCRIPTION
  --
  -- IMPORTANT:
  --
  -- This changes subscription/access state only.
  --
  -- No customer data is deleted.
  -- ==========================================================

  update public.user_subscriptions
  set
    status = 'expired',
    reminder_20day_sent = false
  where user_id = target_user_id;


  -- ==========================================================
  -- 1.6 DEACTIVATE USER ACCOUNT
  --
  -- We intentionally preserve:
  --
  --   expiry_date
  --   medical data
  --   documents
  --   medications
  --   doctors
  --   pharmacies
  --   insurance information
  --   all other application data
  --
  -- Only access state changes.
  -- ==========================================================

  update public.users
  set
    is_active = false
  where id = target_user_id
    and lower(coalesce(role, 'user')) <> 'admin';


  if not found then
    raise exception
      'Customer account could not be deactivated';
  end if;


end;
$$;


-- ============================================================
-- 2. RPC PERMISSIONS
--
-- Anonymous users cannot call this function.
--
-- Authenticated users can technically invoke the RPC,
-- but sana_is_admin() inside the function is the actual
-- authorization gate.
-- ============================================================

revoke all
on function public.admin_deactivate_user(uuid)
from public;

revoke all
on function public.admin_deactivate_user(uuid)
from anon;

grant execute
on function public.admin_deactivate_user(uuid)
to authenticated;


-- ============================================================
-- 3. VERIFICATION
-- ============================================================

do $$
begin

  if not exists (
    select 1
    from pg_proc p
    join pg_namespace n
      on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'admin_deactivate_user'
      and pg_get_function_identity_arguments(p.oid)
          = 'target_user_id uuid'
  ) then

    raise exception
      'admin_deactivate_user was not created';

  end if;

end;
$$;


-- ============================================================
-- END OF MIGRATION
-- ============================================================