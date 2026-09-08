-- ============================================================
-- SANA
-- 20260816_sana_subscription_payment_admin.sql
--
-- Server-controlled annual subscription/payment system.
--
-- DATABASE CONTRACT:
--   users.id                 = auth.uid()
--   users.role               = admin/user
--   user_subscriptions.user_id = users.id
--
-- IMPORTANT:
--   - No hardcoded administrator email authorization.
--   - Customers can request subscriptions.
--   - Only users.role = 'admin' can confirm payments.
--   - Subscription duration = exactly 1 year.
--   - Expiration NEVER deletes private medical data.
--   - Existing user_subscriptions table is preserved.
-- ============================================================


-- ============================================================
-- 1. REQUIRED UNIQUE USER SUBSCRIPTION
-- ============================================================

create unique index if not exists
  user_subscriptions_user_id_unique_idx
on public.user_subscriptions(user_id);


-- ============================================================
-- 2. PAYMENT CONFIRMATIONS
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


create unique index if not exists
  payment_confirmations_transaction_id_idx
on public.payment_confirmations(transaction_id);


create index if not exists
  payment_confirmations_user_id_idx
on public.payment_confirmations(user_id);


create index if not exists
  payment_confirmations_confirmed_by_idx
on public.payment_confirmations(confirmed_by);


alter table public.payment_confirmations
enable row level security;


-- ============================================================
-- 3. ADMIN AUTHORIZATION HELPER
--
-- Authorization:
--
-- auth.uid()
--     ↓
-- users.id
--     ↓
-- users.role = 'admin'
--
-- NO EMAIL CHECKS.
-- ============================================================

create or replace function public.sana_is_admin()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.users u
    where u.id = auth.uid()
      and lower(coalesce(u.role, '')) = 'admin'
  );
$$;


revoke all
on function public.sana_is_admin()
from public;


grant execute
on function public.sana_is_admin()
to authenticated;


-- ============================================================
-- 4. PAYMENT CONFIRMATION RLS
-- ============================================================

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
-- 5. USER SUBSCRIPTION RLS
-- ============================================================

alter table public.user_subscriptions
enable row level security;


drop policy if exists
  "users read own subscription"
on public.user_subscriptions;


create policy
  "users read own subscription"
on public.user_subscriptions
for select
to authenticated
using (
  user_id = auth.uid()
  or public.sana_is_admin()
);


drop policy if exists
  "admins manage subscriptions"
on public.user_subscriptions;


create policy
  "admins manage subscriptions"
on public.user_subscriptions
for all
to authenticated
using (
  public.sana_is_admin()
)
with check (
  public.sana_is_admin()
);


-- Customers must NOT directly insert/update subscriptions.
revoke insert, update, delete
on public.user_subscriptions
from authenticated;


-- ============================================================
-- 6. CUSTOMER SUBSCRIPTION REQUEST
--
-- Creates or reopens a pending request.
--
-- Customer NEVER becomes active here.
-- ============================================================

create or replace function public.request_private_subscription()
returns public.user_subscriptions
language plpgsql
security definer
set search_path = public
as $$
declare
  result public.user_subscriptions;
  current_user_id uuid;
  current_email text;
  current_name text;
  current_phone text;
begin

  current_user_id := auth.uid();

  if current_user_id is null then
    raise exception 'Authentication required';
  end if;


  select
    au.email,
    coalesce(au.raw_user_meta_data ->> 'name', ''),
    coalesce(au.raw_user_meta_data ->> 'phone', '')
  into
    current_email,
    current_name,
    current_phone
  from auth.users au
  where au.id = current_user_id;


  if current_email is null
     or length(trim(current_email)) = 0 then
    raise exception 'Authenticated email is required';
  end if;


  insert into public.user_subscriptions (
    user_id,
    user_email,
    user_phone,
    status,
    activated_at,
    expires_at,
    reminder_20day_sent
  )
  values (
    current_user_id,
    lower(trim(current_email)),
    nullif(trim(current_phone), ''),
    'pending',
    null,
    null,
    false
  )
  on conflict (user_id)
  do update set
    user_email = excluded.user_email,
    user_phone = excluded.user_phone,

    status = case
      when public.user_subscriptions.status
        in ('active')
      then public.user_subscriptions.status

      else 'pending'
    end,

    reminder_20day_sent = case
      when public.user_subscriptions.status
        = 'active'
      then public.user_subscriptions.reminder_20day_sent

      else false
    end

  returning *
  into result;


  return result;

end;
$$;


revoke all
on function public.request_private_subscription()
from public;


grant execute
on function public.request_private_subscription()
to authenticated;


-- ============================================================
-- 7. ADMIN PAYMENT CONFIRMATION
--
-- THIS IS THE ONLY ACTIVATION PATH.
--
-- Duration:
--     now() + interval '1 year'
--
-- No 30-day period.
-- No 60-day grace period.
-- No destructive expiration.
-- ============================================================

create or replace function public.admin_confirm_payment(
  p_user_id uuid,
  p_transaction_id text,
  p_amount numeric,
  p_currency text default 'USD',
  p_paid_at timestamptz default now(),
  p_notes text default null
)
returns public.user_subscriptions
language plpgsql
security definer
set search_path = public
as $$
declare
  result public.user_subscriptions;
  admin_user_id uuid;
  target_exists boolean;
begin

  admin_user_id := auth.uid();


  -- ----------------------------------------------------------
  -- ADMIN AUTHORIZATION
  -- ----------------------------------------------------------

  if admin_user_id is null then
    raise exception 'Authentication required';
  end if;


  if not public.sana_is_admin() then
    raise exception 'Administrator authorization required';
  end if;


  -- ----------------------------------------------------------
  -- VALIDATION
  -- ----------------------------------------------------------

  if p_user_id is null then
    raise exception 'Customer is required';
  end if;


  select exists (
    select 1
    from public.users u
    where u.id = p_user_id
      and lower(coalesce(u.role, 'user')) <> 'admin'
  )
  into target_exists;


  if not target_exists then
    raise exception 'Customer account not found';
  end if;


  if p_transaction_id is null
     or length(trim(p_transaction_id)) < 3 then
    raise exception 'Transaction ID is required';
  end if;


  if p_amount is null
     or p_amount <= 0 then
    raise exception 'Payment amount must be greater than zero';
  end if;


  if p_currency is null
     or length(trim(p_currency)) = 0 then
    raise exception 'Currency is required';
  end if;


  -- ----------------------------------------------------------
  -- PAYMENT RECORD
  -- ----------------------------------------------------------

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
    p_user_id,
    admin_user_id,
    trim(p_transaction_id),
    p_amount,
    upper(trim(p_currency)),
    coalesce(p_paid_at, now()),
    p_notes
  );


  -- ----------------------------------------------------------
  -- ACTIVATE FOR ONE YEAR
  -- ----------------------------------------------------------

  update public.user_subscriptions
  set
    status = 'active',

    activated_at = now(),

    expires_at = now() + interval '1 year',

    reminder_20day_sent = false
  where user_id = p_user_id
  returning *
  into result;


  -- ----------------------------------------------------------
  -- CREATE SUBSCRIPTION ROW IF IT DOES NOT EXIST
  -- ----------------------------------------------------------

  if not found then

    insert into public.user_subscriptions (
      user_id,
      user_email,
      user_phone,
      status,
      activated_at,
      expires_at,
      reminder_20day_sent
    )
    select
      au.id,
      lower(trim(au.email)),
      nullif(
        trim(
          coalesce(
            au.raw_user_meta_data ->> 'phone',
            ''
          )
        ),
        ''
      ),
      'active',
      now(),
      now() + interval '1 year',
      false
    from auth.users au
    where au.id = p_user_id
    returning *
    into result;

  end if;


  -- ----------------------------------------------------------
  -- SYNCHRONIZE users ACCOUNT ACCESS
  -- ----------------------------------------------------------

  update public.users
  set
    is_active = true,
    expiry_date = result.expires_at
  where id = p_user_id;


  return result;

end;
$$;


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
-- 8. NON-DESTRUCTIVE EXPIRATION
--
-- Expiration ONLY changes subscription/access state.
--
-- PRIVATE MEDICAL DATA IS NEVER DELETED.
-- ============================================================

create or replace function public.expire_sana_subscriptions()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin

  update public.user_subscriptions
  set
    status = 'expired'
  where status = 'active'
    and expires_at is not null
    and expires_at <= now();


  update public.users u
  set
    is_active = false,
    expiry_date = s.expires_at
  from public.user_subscriptions s
  where s.user_id = u.id
    and s.status = 'expired'
    and s.expires_at is not null
    and s.expires_at <= now();

end;
$$;


revoke all
on function public.expire_sana_subscriptions()
from public, anon, authenticated;


-- ============================================================
-- 9. IMPORTANT:
-- DELETE-EXPIRED-DATA FUNCTION IS INTENTIONALLY REMOVED.
--
-- DO NOT recreate:
--
--   delete_expired_sana_data()
--
-- It must NEVER delete:
--   medications
--   doctors
--   pharmacies
--   documents
--   insurance_cards
--
-- User data remains available after reactivation.
-- ============================================================


-- Remove old destructive function if it exists.

drop function if exists public.delete_expired_sana_data();


-- ============================================================
-- 10. INDEXES
-- ============================================================

create index if not exists
  user_subscriptions_expires_at_idx
on public.user_subscriptions(expires_at);


create index if not exists
  user_subscriptions_status_idx
on public.user_subscriptions(status);


create index if not exists
  payment_confirmations_paid_at_idx
on public.payment_confirmations(paid_at);


-- ============================================================
-- 11. EXPIRATION CRON
-- ============================================================

do $$
begin

  if exists (
    select 1
    from pg_extension
    where extname = 'pg_cron'
  ) then

    perform cron.unschedule('sana-expire-subscriptions')
    where exists (
      select 1
      from cron.job
      where jobname = 'sana-expire-subscriptions'
    );


    perform cron.unschedule('sana-delete-expired-data')
    where exists (
      select 1
      from cron.job
      where jobname = 'sana-delete-expired-data'
    );


    perform cron.schedule(
      'sana-expire-subscriptions',
      '*/15 * * * *',
      'select public.expire_sana_subscriptions()'
    );

  end if;

end
$$;