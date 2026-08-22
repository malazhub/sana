-- SANA server-controlled subscription/payment system
-- Administrator: malazjanbeih@gmail.com
-- Customers NEVER activate their own subscription.

create table if not exists public.subscriptions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending','active','expired','cancelled')),
  started_at timestamptz,
  expires_at timestamptz,
  grace_until timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.payment_confirmations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  confirmed_by text not null,
  transaction_id text not null,
  amount numeric(12,2) not null,
  currency text not null default 'USD',
  paid_at timestamptz not null,
  confirmed_at timestamptz not null default now(),
  notes text
);

create unique index if not exists payment_confirmations_transaction_id_idx
on public.payment_confirmations(transaction_id);

alter table public.subscriptions enable row level security;
alter table public.payment_confirmations enable row level security;

drop policy if exists "users read own subscription"
on public.subscriptions;

create policy "users read own subscription"
on public.subscriptions
for select
to authenticated
using (
  (select auth.uid()) = user_id
);

drop policy if exists "users create own pending subscription"
on public.subscriptions;

create policy "users create own pending subscription"
on public.subscriptions
for insert
to authenticated
with check (
  (select auth.uid()) = user_id
  and status = 'pending'
);

drop policy if exists "users cancel own pending subscription"
on public.subscriptions;

create policy "users cancel own pending subscription"
on public.subscriptions
for update
to authenticated
using (
  (select auth.uid()) = user_id
  and status = 'pending'
)
with check (
  (select auth.uid()) = user_id
  and status = 'cancelled'
);

drop policy if exists "users read own payment confirmations"
on public.payment_confirmations;

create policy "users read own payment confirmations"
on public.payment_confirmations
for select
to authenticated
using (
  (select auth.uid()) = user_id
);

revoke all on public.payment_confirmations
from anon;

revoke insert, update, delete
on public.payment_confirmations
from authenticated;

create or replace function public.request_private_subscription()
returns public.subscriptions
language plpgsql
security definer
set search_path = public
as $$
declare
  result public.subscriptions;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  insert into public.subscriptions(
    user_id,
    status
  )
  values(
    auth.uid(),
    'pending'
  )
  on conflict(user_id)
  do update set
    status = case
      when public.subscriptions.status = 'cancelled'
      then 'pending'
      else public.subscriptions.status
    end,
    updated_at = now()
  returning * into result;

  return result;
end;
$$;

revoke all
on function public.request_private_subscription()
from public;

grant execute
on function public.request_private_subscription()
to authenticated;

create or replace function public.admin_confirm_payment(
  p_user_id uuid,
  p_transaction_id text,
  p_amount numeric,
  p_currency text default 'USD',
  p_paid_at timestamptz default now(),
  p_notes text default null
)
returns public.subscriptions
language plpgsql
security definer
set search_path = public
as $$
declare
  result public.subscriptions;
  admin_email text;
begin
  admin_email :=
    lower(
      coalesce(
        auth.email(),
        ''
      )
    );

  if admin_email <> 'malazjanbeih@gmail.com' then
    raise exception
      'Administrator authorization required';
  end if;

  if p_user_id is null then
    raise exception
      'Customer is required';
  end if;

  if p_transaction_id is null
     or length(trim(p_transaction_id)) < 3 then
    raise exception
      'Payoneer transaction ID is required';
  end if;

  if p_amount <= 0 then
    raise exception
      'Payment amount must be greater than zero';
  end if;

  insert into public.payment_confirmations(
    user_id,
    confirmed_by,
    transaction_id,
    amount,
    currency,
    paid_at,
    notes
  )
  values(
    p_user_id,
    admin_email,
    trim(p_transaction_id),
    p_amount,
    upper(trim(p_currency)),
    p_paid_at,
    p_notes
  );

  /*
   * Administrator activation grants exactly
   * one year of access.
   *
   * Existing private user data is NOT deleted
   * when a subscription expires.
   *
   * Re-activation uses the same user_id and
   * therefore restores access to the same
   * private data.
   */
  insert into public.subscriptions(
    user_id,
    status,
    started_at,
    expires_at,
    grace_until,
    updated_at
  )
  values(
    p_user_id,
    'active',
    now(),
    now() + interval '1 year',
    null,
    now()
  )
  on conflict(user_id)
  do update set
    status = 'active',
    started_at = now(),
    expires_at = now() + interval '1 year',
    grace_until = null,
    updated_at = now()
  returning * into result;

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

create or replace function public.expire_sana_subscriptions()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  /*
   * Expiration only changes subscription status.
   *
   * It does NOT delete:
   * - medications
   * - doctors
   * - pharmacies
   * - documents
   * - insurance cards
   *
   * Those records remain associated with the
   * user's account for future reactivation.
   */
  update public.subscriptions
  set
    status = 'expired',
    updated_at = now()
  where status = 'active'
    and expires_at is not null
    and expires_at <= now();
end;
$$;

revoke all
on function public.expire_sana_subscriptions()
from public, anon, authenticated;

create index if not exists subscriptions_expires_at_idx
on public.subscriptions(expires_at);

create index if not exists subscriptions_grace_until_idx
on public.subscriptions(grace_until);

-- Requires pg_cron to be enabled in the Supabase project.

do $$
begin
  if exists (
    select 1
    from pg_extension
    where extname = 'pg_cron'
  ) then

    perform cron.unschedule(
      'sana-expire-subscriptions'
    )
    where exists (
      select 1
      from cron.job
      where jobname =
        'sana-expire-subscriptions'
    );

    perform cron.unschedule(
      'sana-delete-expired-data'
    )
    where exists (
      select 1
      from cron.job
      where jobname =
        'sana-delete-expired-data'
    );

    perform cron.schedule(
      'sana-expire-subscriptions',
      '*/15 * * * *',
      'select public.expire_sana_subscriptions()'
    );

  end if;
end
$$;
