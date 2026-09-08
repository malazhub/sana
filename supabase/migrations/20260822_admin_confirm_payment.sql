-- ============================================================
-- SANA
-- 20260822_admin_confirm_payment.sql
--
-- FINAL ADMIN PAYMENT CONFIRMATION + ONE-YEAR SUBSCRIPTION
--
-- Flutter contract:
--
-- admin_confirm_payment(
--   target_user_id,
--   p_transaction_id,
--   p_amount,
--   p_currency,
--   p_paid_at,
--   p_notes
-- )
--
-- SECURITY:
--   - Only users.role = 'admin' may confirm payments.
--   - Anonymous users cannot execute the RPC.
--   - The client cannot choose expires_at.
--   - PostgreSQL controls activation and expiry.
--   - Duplicate transaction IDs are rejected.
--   - Payment records are permanently stored.
--   - Expiration NEVER deletes user data.
-- ============================================================


-- ============================================================
-- 1. REQUIRED UNIQUE SUBSCRIPTION
-- ============================================================

create unique index if not exists
  user_subscriptions_user_id_unique_idx
on public.user_subscriptions(user_id);


-- ============================================================
-- 2. PAYMENT CONFIRMATION TABLE
--
-- Created here defensively in case the earlier migration
-- has not been applied.
-- ============================================================

create table if not exists public.payment_confirmations (
  id uuid primary key default gen_random_uuid(),

  user_id uuid not null,

  confirmed_by uuid not null,

  transaction_id text not null,

  amount numeric(12,2) not null
    check (amount > 0),

  currency text not null default 'USD',

  paid_at timestamptz not null,

  confirmed_at timestamptz not null default now(),

  notes text
);


-- ============================================================
-- 3. PAYMENT INDEXES
-- ============================================================

create unique index if not exists
  payment_confirmations_transaction_id_unique_idx
on public.payment_confirmations(transaction_id);


create index if not exists
  payment_confirmations_user_id_idx
on public.payment_confirmations(user_id);


create index if not exists
  payment_confirmations_confirmed_by_idx
on public.payment_confirmations(confirmed_by);


create index if not exists
  payment_confirmations_paid_at_idx
on public.payment_confirmations(paid_at);


-- ============================================================
-- 4. PAYMENT RLS
-- ============================================================

alter table public.payment_confirmations
enable row level security;


drop policy if exists
  "users read own payment confirmations"
on public.payment_confirmations;


create policy
  "users read own payment confirmations"
on public.payment_confirmations
for select
to authenticated
using (
  user_id = auth.uid()
  or public.sana_is_admin()
);


drop policy if exists
  "admins manage payment confirmations"
on public.payment_confirmations;


create policy
  "admins manage payment confirmations"
on public.payment_confirmations
for all
to authenticated
using (
  public.sana_is_admin()
)
with check (
  public.sana_is_admin()
);


revoke all
on public.payment_confirmations
from anon;


-- ============================================================
-- 5. ADMIN PAYMENT CONFIRMATION
--
-- THIS IS THE ONLY PAYMENT ACTIVATION PATH.
--
-- Flow:
--
--   admin
--      ↓
--   payment_confirmations
--      ↓
--   user_subscriptions
--      ↓
--   users.is_active = true
--
-- Expiry:
--
--   database_now + interval '1 year'
--
-- NOT Flutter time.
-- NOT a hardcoded 365 days.
-- NOT a client-provided expiry date.
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
  admin_user_id uuid;

  target_email text;
  target_phone text;

  activation_time timestamptz;
  subscription_expiry timestamptz;

  normalized_transaction_id text;
  normalized_currency text;
begin

  -- ==========================================================
  -- 5.1 AUTHENTICATION
  -- ==========================================================

  admin_user_id := auth.uid();

  if admin_user_id is null then
    raise exception 'Authentication required';
  end if;


  -- ==========================================================
  -- 5.2 ADMIN AUTHORIZATION
  -- ==========================================================

  if not public.sana_is_admin() then
    raise exception 'Administrator authorization required';
  end if;


  -- ==========================================================
  -- 5.3 CUSTOMER VALIDATION
  -- ==========================================================

  if target_user_id is null then
    raise exception 'Customer is required';
  end if;


  select
    u.email,
    u.phone
  into
    target_email,
    target_phone
  from public.users u
  where u.id = target_user_id
    and lower(coalesce(u.role, 'user')) <> 'admin';


  if not found then
    raise exception 'Customer account not found';
  end if;


  -- ==========================================================
  -- 5.4 TRANSACTION VALIDATION
  -- ==========================================================

  normalized_transaction_id :=
    trim(p_transaction_id);


  if normalized_transaction_id is null
     or length(normalized_transaction_id) < 3 then
    raise exception 'Transaction ID is required';
  end if;


  -- ==========================================================
  -- 5.5 DUPLICATE TRANSACTION PROTECTION
  --
  -- A transaction can NEVER activate twice.
  -- The unique index is the final database protection.
  -- ==========================================================

  if exists (
    select 1
    from public.payment_confirmations pc
    where pc.transaction_id =
      normalized_transaction_id
  ) then
    raise exception
      'This transaction has already been confirmed';
  end if;


  -- ==========================================================
  -- 5.6 PAYMENT AMOUNT
  -- ==========================================================

  if p_amount is null
     or p_amount <= 0 then
    raise exception
      'Payment amount must be greater than zero';
  end if;


  -- ==========================================================
  -- 5.7 CURRENCY
  -- ==========================================================

  normalized_currency :=
    upper(trim(p_currency));


  if normalized_currency is null
     or length(normalized_currency) <> 3 then
    raise exception
      'Currency must be a 3-letter code';
  end if;


  -- ==========================================================
  -- 5.8 DATABASE ACTIVATION TIME
  -- ==========================================================

  activation_time := now();


  -- ==========================================================
  -- 5.9 EXACTLY ONE CALENDAR YEAR
  -- ==========================================================

  subscription_expiry :=
    activation_time + interval '1 year';


  -- ==========================================================
  -- 5.10 RECORD PAYMENT
  --
  -- This happens BEFORE activation.
  --
  -- If this insert fails, the entire transaction rolls back
  -- and the subscription is NOT activated.
  -- ==========================================================

  insert into public.payment_confirmations (
    user_id,
    confirmed_by,
    transaction_id,
    amount,
    currency,
    paid_at,
    notes
  )
  values (
    target_user_id,
    admin_user_id,
    normalized_transaction_id,
    p_amount,
    normalized_currency,
    coalesce(
      p_paid_at,
      activation_time
    ),
    nullif(
      trim(p_notes),
      ''
    )
  );


  -- ==========================================================
  -- 5.11 CREATE OR UPDATE SUBSCRIPTION
  -- ==========================================================

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


  -- ==========================================================
  -- 5.12 ACTIVATE USER ACCOUNT
  -- ==========================================================

  update public.users
  set
    is_active = true,
    expiry_date = subscription_expiry
  where id = target_user_id;


  -- ==========================================================
  -- 5.13 FINAL SAFETY CHECK
  -- ==========================================================

  if not found then
    raise exception
      'Customer account could not be activated';
  end if;

end;
$$;


-- ============================================================
-- 6. RPC PERMISSIONS
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


revoke all
on function public.admin_confirm_payment(
  uuid,
  text,
  numeric,
  text,
  timestamptz,
  text
)
from anon;


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
-- 7. EXPIRATION INDEX
-- ============================================================

create index if not exists
  user_subscriptions_active_expiry_idx
on public.user_subscriptions (
  status,
  expires_at
);


-- ============================================================
-- 8. NON-DESTRUCTIVE EXPIRATION
--
-- ONLY access/subscription state changes.
--
-- NOTHING IS DELETED.
-- ============================================================

create or replace function public.expire_sana_subscriptions()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin

  -- ----------------------------------------------------------
  -- Mark expired subscriptions.
  -- ----------------------------------------------------------

  update public.user_subscriptions
  set
    status = 'expired',
    reminder_20day_sent = false
  where lower(
          coalesce(status, '')
        ) = 'active'
    and expires_at is not null
    and expires_at <= now();


  -- ----------------------------------------------------------
  -- Deactivate corresponding users.
  -- ----------------------------------------------------------

  update public.users u
  set
    is_active = false,
    expiry_date = s.expires_at
  from public.user_subscriptions s
  where s.user_id = u.id
    and lower(
          coalesce(s.status, '')
        ) = 'expired'
    and s.expires_at is not null
    and s.expires_at <= now()
    and (
      u.is_active = true
      or u.expiry_date is distinct from s.expires_at
    );

end;
$$;


-- ============================================================
-- 9. EXPIRATION RPC IS SERVER-ONLY
-- ============================================================

revoke all
on function public.expire_sana_subscriptions()
from public;


revoke all
on function public.expire_sana_subscriptions()
from anon;


revoke all
on function public.expire_sana_subscriptions()
from authenticated;


-- ============================================================
-- 10. REMOVE OLD DESTRUCTIVE EXPIRATION FUNCTION
--
-- NEVER delete user application/medical data on expiry.
-- ============================================================

drop function if exists
  public.delete_expired_sana_data();


-- ============================================================
-- 11. VERIFY ADMIN RPC
-- ============================================================

do $$
begin

  if not exists (
    select 1
    from pg_proc p
    join pg_namespace n
      on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname =
        'admin_confirm_payment'
  ) then

    raise exception
      'admin_confirm_payment was not created';

  end if;

end;
$$;


-- ============================================================
-- 12. VERIFY EXPIRATION RPC
-- ============================================================

do $$
begin

  if not exists (
    select 1
    from pg_proc p
    join pg_namespace n
      on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname =
        'expire_sana_subscriptions'
  ) then

    raise exception
      'expire_sana_subscriptions was not created';

  end if;

end;
$$;


-- ============================================================
-- END OF MIGRATION
-- ============================================================