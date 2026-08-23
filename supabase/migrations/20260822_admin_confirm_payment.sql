//but u revised this file more than triple, are u sure """-- ============================================================
-- SANA
-- ADMIN PAYMENT CONFIRMATION + ONE-YEAR SUBSCRIPTION
--
-- File:
-- supabase/migrations/20260822_admin_confirm_payment.sql
--
-- Requirements:
--   public.users
--   public.user_subscriptions
--   public.sana_is_admin()
--
-- Runtime authorization:
--   auth.uid()
--      -> public.users.id
--      -> users.role = 'admin'
--
-- Subscription duration:
--   EXACTLY 1 YEAR from activation time.
--
-- No user data is deleted when a subscription expires.
-- ============================================================


-- ============================================================
-- 1. UNIQUE USER SUBSCRIPTION
--
-- A user should have one current subscription row.
-- This allows the RPC to safely use:
--   ON CONFLICT (user_id)
-- ============================================================

create unique index if not exists
  user_subscriptions_user_id_unique_idx
on public.user_subscriptions(user_id);


-- ============================================================
-- 2. ADMIN CONFIRM PAYMENT
--
-- Called by:
--   lib/services/subscription_service.dart
--
-- This function:
--
--   1. Verifies the caller is an administrator.
--   2. Verifies the target user exists.
--   3. Verifies payment information.
--   4. Creates/updates the subscription.
--   5. Activates the user.
--   6. Sets expiry to exactly one year from NOW().
--
-- The Flutter application does NOT calculate the expiry date.
-- PostgreSQL is the source of truth.
-- ============================================================

create or replace function public.admin_confirm_payment(
  target_user_id uuid,
  p_transaction_id text,
  p_amount numeric,
  p_currency text default 'USD',
  p_paid_at timestamptz default null,
  p_notes text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_email text;
  target_phone text;
  activation_time timestamptz;
  subscription_expiry timestamptz;
begin

  -- ----------------------------------------------------------
  -- ADMIN AUTHORIZATION
  -- ----------------------------------------------------------

  if not public.sana_is_admin() then
    raise exception 'Administrator authorization required';
  end if;


  -- ----------------------------------------------------------
  -- VALIDATE USER ID
  -- ----------------------------------------------------------

  if target_user_id is null then
    raise exception 'Customer is required';
  end if;


  -- ----------------------------------------------------------
  -- VALIDATE TRANSACTION ID
  -- ----------------------------------------------------------

  if nullif(trim(p_transaction_id), '') is null then
    raise exception 'Transaction ID is required';
  end if;


  -- ----------------------------------------------------------
  -- VALIDATE PAYMENT AMOUNT
  -- ----------------------------------------------------------

  if p_amount is null or p_amount <= 0 then
    raise exception 'Payment amount must be greater than zero';
  end if;


  -- ----------------------------------------------------------
  -- GET CUSTOMER
  -- ----------------------------------------------------------

  select
    u.email,
    u.phone
  into
    target_email,
    target_phone
  from public.users u
  where u.id = target_user_id
    and lower(coalesce(u.role, 'user')) <> 'admin';


  if target_email is null then
    raise exception 'Customer does not exist';
  end if;


  -- ----------------------------------------------------------
  -- ACTIVATION TIME
  --
  -- We use the database clock.
  -- This prevents the client device from controlling expiry.
  -- ----------------------------------------------------------

  activation_time := now();


  -- ----------------------------------------------------------
  -- EXACTLY ONE YEAR
  --
  -- PostgreSQL interval '1 year' correctly handles
  -- calendar-year activation dates.
  -- ----------------------------------------------------------

  subscription_expiry :=
    activation_time + interval '1 year';


  -- ----------------------------------------------------------
  -- SAVE / UPDATE SUBSCRIPTION
  -- ----------------------------------------------------------

  insert into public.user_subscriptions (
    user_id,
    user_email,
    user_phone,
    status,
    activated_at,
    expires_at,
    reminder_20day_sent,
    created_at
  )
  values (
    target_user_id,
    target_email,
    target_phone,
    'active',
    activation_time,
    subscription_expiry,
    false,
    activation_time
  )
  on conflict (user_id)
  do update set
    user_email =
      excluded.user_email,

    user_phone =
      excluded.user_phone,

    status =
      'active',

    activated_at =
      excluded.activated_at,

    expires_at =
      excluded.expires_at,

    reminder_20day_sent =
      false;


  -- ----------------------------------------------------------
  -- ACTIVATE USER
  -- ----------------------------------------------------------

  update public.users
  set
    is_active = true,
    expiry_date = subscription_expiry
  where id = target_user_id;


end;
$$;


-- ============================================================
-- 3. FUNCTION PERMISSIONS
--
-- Users cannot call this function anonymously.
-- Authenticated users may technically invoke it, but the
-- function itself requires sana_is_admin().
-- ============================================================

revoke all
on function public.admin_confirm_payment(
  uuid,
  text,
  numeric,
  text,
  timestamptz,
  text
)
from public;

grant execute
on function public.admin_confirm_payment(
  uuid,
  text,
  numeric,
  text,
  timestamptz,
  text
)
to authenticated;


-- ============================================================
-- 4. INDEX FOR EXPIRATION CHECKS
-- ============================================================

create index if not exists
  user_subscriptions_active_expiry_idx
on public.user_subscriptions(
  status,
  expires_at
);


-- ============================================================
-- 5. SAFE EXPIRATION FUNCTION
--
-- Expired subscriptions are marked expired.
-- USER DATA IS NOT DELETED.
-- ============================================================

create or replace function public.expire_sana_subscriptions()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin

  -- Mark expired subscriptions.
  update public.user_subscriptions
  set
    status = 'expired',
    reminder_20day_sent = false
  where lower(coalesce(status, '')) = 'active'
    and expires_at is not null
    and expires_at <= now();


  -- Deactivate corresponding users.
  update public.users u
  set
    is_active = false,
    expiry_date = us.expires_at
  from public.user_subscriptions us
  where us.user_id = u.id
    and lower(coalesce(us.status, '')) = 'expired'
    and (
      u.is_active = true
      or u.expiry_date is distinct from us.expires_at
    );

end;
$$;


-- ============================================================
-- 6. EXPIRATION FUNCTION MUST NOT BE CALLED BY CLIENTS
-- ============================================================

revoke all
on function public.expire_sana_subscriptions()
from public, anon, authenticated;


-- ============================================================
-- 7. VERIFY THE RPC EXISTS
-- ============================================================

do $$
begin

  if not exists (
    select 1
    from pg_proc p
    join pg_namespace n
      on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'admin_confirm_payment'
  ) then

    raise exception
      'admin_confirm_payment was not created';

  end if;

end;
$$;


-- ============================================================
-- END
-- ============================================================