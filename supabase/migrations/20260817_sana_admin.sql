-- ============================================================
-- SANA ADMIN STANDARDIZATION
-- Annual subscription: 1 YEAR
-- Expiration is NON-DESTRUCTIVE.
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

revoke all
on function public.sana_is_admin()
from public, anon;

grant execute
on function public.sana_is_admin()
to authenticated;


-- ============================================================
-- INITIAL ADMIN SEED
-- Email is used ONLY to locate the initial administrator.
-- Runtime authorization uses users.id + users.role.
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
  coalesce(au.raw_user_meta_data->>'name', ''),
  au.email,
  coalesce(au.raw_user_meta_data->>'phone', ''),
  coalesce(au.created_at, now()),
  true,
  null,
  'admin'
from auth.users au
where lower(coalesce(au.email, '')) = 'malazjanbeih@gmail.com'
on conflict (id)
do update set
  role = 'admin',
  is_active = true,
  expiry_date = null;


-- ============================================================
-- ADMIN LIST USERS
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
    coalesce(us.status, 'pending'),
    us.expires_at
  from public.users u
  left join public.user_subscriptions us
    on us.user_id = u.id
  where public.sana_is_admin()
    and lower(coalesce(u.role, 'user')) <> 'admin'
  order by u.created_at desc;
$$;

revoke all
on function public.admin_list_users()
from public, anon;

grant execute
on function public.admin_list_users()
to authenticated;


-- ============================================================
-- ACTIVATE ANNUAL SUBSCRIPTION
--
-- EXACTLY ONE YEAR.
-- Existing private data is NOT deleted.
-- ============================================================

create or replace function public.activate_annual_subscription(
  target_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  customer_email text;
  customer_phone text;
  expiration timestamptz;
begin

  if not public.sana_is_admin() then
    raise exception
      'Administrator authorization required';
  end if;

  if target_user_id is null then
    raise exception
      'Customer is required';
  end if;

  select
    au.email,
    coalesce(
      au.raw_user_meta_data->>'phone',
      ''
    )
  into
    customer_email,
    customer_phone
  from auth.users au
  where au.id = target_user_id;

  if customer_email is null then
    raise exception
      'Customer does not exist';
  end if;

  -- EXACTLY ONE YEAR FROM ACTIVATION
  expiration := now() + interval '1 year';

  -- Update existing subscription.
  update public.user_subscriptions
  set
    user_email = customer_email,
    user_phone = customer_phone,
    status = 'active',
    activated_at = now(),
    expires_at = expiration,
    reminder_20day_sent = false
  where user_id = target_user_id;

  -- Create subscription if one does not already exist.
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
    values (
      target_user_id,
      customer_email,
      customer_phone,
      'active',
      now(),
      expiration,
      false
    );
  end if;

  -- Synchronize user account status.
  update public.users
  set
    is_active = true,
    expiry_date = expiration
  where id = target_user_id;

end;
$$;

revoke all
on function public.activate_annual_subscription(uuid)
from public, anon;

grant execute
on function public.activate_annual_subscription(uuid)
to authenticated;


-- ============================================================
-- EXPIRE SUBSCRIPTIONS
--
-- NON-DESTRUCTIVE.
--
-- NOTHING IS DELETED:
-- medications
-- doctors
-- pharmacies
-- documents
-- insurance_cards
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
    status = 'expired',
    reminder_20day_sent = false
  where lower(coalesce(status, '')) = 'active'
    and expires_at is not null
    and expires_at <= now();

  update public.users u
  set
    is_active = false,
    expiry_date = us.expires_at
  from public.user_subscriptions us
  where us.user_id = u.id
    and lower(coalesce(us.status, '')) = 'expired';

end;
$$;

revoke all
on function public.expire_sana_subscriptions()
from public, anon, authenticated;


-- ============================================================
-- INDEXES
-- ============================================================

create index if not exists user_subscriptions_user_id_idx
on public.user_subscriptions(user_id);

create index if not exists user_subscriptions_status_idx
on public.user_subscriptions(status);

create index if not exists user_subscriptions_expires_at_idx
on public.user_subscriptions(expires_at);


-- ============================================================
-- REMOVE OLD DESTRUCTIVE CRON
-- ============================================================

do $$
begin

  if exists (
    select 1
    from pg_extension
    where extname = 'pg_cron'
  ) then

    perform cron.unschedule(
      'sana-delete-expired-data'
    )
    where exists (
      select 1
      from cron.job
      where jobname = 'sana-delete-expired-data'
    );

    perform cron.unschedule(
      'sana-expire-subscriptions'
    )
    where exists (
      select 1
      from cron.job
      where jobname = 'sana-expire-subscriptions'
    );

    perform cron.schedule(
      'sana-expire-subscriptions',
      '*/15 * * * *',
      'select public.expire_sana_subscriptions()'
    );

  end if;

end;
$$;