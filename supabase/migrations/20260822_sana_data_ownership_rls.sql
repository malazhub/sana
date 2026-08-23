-- ============================================================
-- SANA DATA OWNERSHIP / SCOPE RLS
-- Migration: 20260822_sana_data_ownership_rls.sql
--
-- Scope rules:
--
-- Guest:
--   guest_id = 'guest_shared_workspace'
--   user_id  = NULL
--
-- Active authenticated user:
--   user_id = auth.uid()
--   guest_id = NULL
--
-- Administrator:
--   users.id = auth.uid()
--   users.role = 'admin'
--
-- Expired users keep their private records.
-- Subscription expiration does NOT delete application data.
-- ============================================================


-- ============================================================
-- 1. CANONICAL SHARED GUEST IDENTIFIER
-- ============================================================

create or replace function public.sana_guest_scope()
returns text
language sql
immutable
as $$
  select 'guest_shared_workspace'::text;
$$;


-- ============================================================
-- 2. ADD GUEST SCOPE TO INSURANCE
-- ============================================================

alter table public.insurance_cards
add column if not exists guest_id text;


-- ============================================================
-- 3. NORMALIZE EXISTING DATA
-- ============================================================

-- Authenticated/private records must remain owned by user_id.
-- Existing guest records that already have guest_id remain
-- untouched.

-- Do not automatically convert records to the shared guest
-- workspace because that could incorrectly merge private data.


-- ============================================================
-- 4. INDEXES
-- ============================================================

create index if not exists medications_user_id_idx
on public.medications(user_id);

create index if not exists medications_guest_id_idx
on public.medications(guest_id);

create index if not exists doctors_user_id_idx
on public.doctors(user_id);

create index if not exists doctors_guest_id_idx
on public.doctors(guest_id);

create index if not exists pharmacies_user_id_idx
on public.pharmacies(user_id);

create index if not exists pharmacies_guest_id_idx
on public.pharmacies(guest_id);

create index if not exists insurance_cards_user_id_idx
on public.insurance_cards(user_id);

create index if not exists insurance_cards_guest_id_idx
on public.insurance_cards(guest_id);


-- ============================================================
-- 5. ENABLE RLS
-- ============================================================

alter table public.medications enable row level security;
alter table public.doctors enable row level security;
alter table public.pharmacies enable row level security;
alter table public.insurance_cards enable row level security;


-- ============================================================
-- 6. MEDICATIONS
-- ============================================================

drop policy if exists "medications_select_scoped"
on public.medications;

drop policy if exists "medications_insert_scoped"
on public.medications;

drop policy if exists "medications_update_scoped"
on public.medications;

drop policy if exists "medications_delete_scoped"
on public.medications;


create policy "medications_select_scoped"
on public.medications
for select
to anon, authenticated
using (
  (
    auth.uid() is null
    and guest_id = public.sana_guest_scope()
    and user_id is null
  )
  or
  (
    auth.uid() is not null
    and user_id = auth.uid()
  )
  or
  (
    exists (
      select 1
      from public.users u
      where u.id = auth.uid()
        and lower(coalesce(u.role, 'user')) = 'admin'
    )
  )
);


create policy "medications_insert_scoped"
on public.medications
for insert
to anon, authenticated
with check (
  (
    auth.uid() is null
    and guest_id = public.sana_guest_scope()
    and user_id is null
  )
  or
  (
    auth.uid() is not null
    and user_id = auth.uid()
    and guest_id is null
  )
  or
  (
    exists (
      select 1
      from public.users u
      where u.id = auth.uid()
        and lower(coalesce(u.role, 'user')) = 'admin'
    )
  )
);


create policy "medications_update_scoped"
on public.medications
for update
to anon, authenticated
using (
  (
    auth.uid() is null
    and guest_id = public.sana_guest_scope()
    and user_id is null
  )
  or
  (
    auth.uid() is not null
    and user_id = auth.uid()
  )
  or
  (
    exists (
      select 1
      from public.users u
      where u.id = auth.uid()
        and lower(coalesce(u.role, 'user')) = 'admin'
    )
  )
)
with check (
  (
    auth.uid() is null
    and guest_id = public.sana_guest_scope()
    and user_id is null
  )
  or
  (
    auth.uid() is not null
    and user_id = auth.uid()
    and guest_id is null
  )
  or
  (
    exists (
      select 1
      from public.users u
      where u.id = auth.uid()
        and lower(coalesce(u.role, 'user')) = 'admin'
    )
  )
);


create policy "medications_delete_scoped"
on public.medications
for delete
to anon, authenticated
using (
  (
    auth.uid() is null
    and guest_id = public.sana_guest_scope()
    and user_id is null
  )
  or
  (
    auth.uid() is not null
    and user_id = auth.uid()
  )
  or
  (
    exists (
      select 1
      from public.users u
      where u.id = auth.uid()
        and lower(coalesce(u.role, 'user')) = 'admin'
    )
  )
);


-- ============================================================
-- 7. DOCTORS
-- ============================================================

drop policy if exists "doctors_select_scoped"
on public.doctors;

drop policy if exists "doctors_insert_scoped"
on public.doctors;

drop policy if exists "doctors_update_scoped"
on public.doctors;

drop policy if exists "doctors_delete_scoped"
on public.doctors;


create policy "doctors_select_scoped"
on public.doctors
for select
to anon, authenticated
using (
  (
    auth.uid() is null
    and guest_id = public.sana_guest_scope()
    and user_id is null
  )
  or
  (
    auth.uid() is not null
    and user_id = auth.uid()
  )
  or
  (
    exists (
      select 1
      from public.users u
      where u.id = auth.uid()
        and lower(coalesce(u.role, 'user')) = 'admin'
    )
  )
);


create policy "doctors_insert_scoped"
on public.doctors
for insert
to anon, authenticated
with check (
  (
    auth.uid() is null
    and guest_id = public.sana_guest_scope()
    and user_id is null
  )
  or
  (
    auth.uid() is not null
    and user_id = auth.uid()
    and guest_id is null
  )
  or
  (
    exists (
      select 1
      from public.users u
      where u.id = auth.uid()
        and lower(coalesce(u.role, 'user')) = 'admin'
    )
  )
);


create policy "doctors_update_scoped"
on public.doctors
for update
to anon, authenticated
using (
  (
    auth.uid() is null
    and guest_id = public.sana_guest_scope()
    and user_id is null
  )
  or
  (
    auth.uid() is not null
    and user_id = auth.uid()
  )
  or
  (
    exists (
      select 1
      from public.users u
      where u.id = auth.uid()
        and lower(coalesce(u.role, 'user')) = 'admin'
    )
  )
)
with check (
  (
    auth.uid() is null
    and guest_id = public.sana_guest_scope()
    and user_id is null
  )
  or
  (
    auth.uid() is not null
    and user_id = auth.uid()
    and guest_id is null
  )
  or
  (
    exists (
      select 1
      from public.users u
      where u.id = auth.uid()
        and lower(coalesce(u.role, 'user')) = 'admin'
    )
  )
);


create policy "doctors_delete_scoped"
on public.doctors
for delete
to anon, authenticated
using (
  (
    auth.uid() is null
    and guest_id = public.sana_guest_scope()
    and user_id is null
  )
  or
  (
    auth.uid() is not null
    and user_id = auth.uid()
  )
  or
  (
    exists (
      select 1
      from public.users u
      where u.id = auth.uid()
        and lower(coalesce(u.role, 'user')) = 'admin'
    )
  )
);


-- ============================================================
-- 8. PHARMACIES
-- ============================================================

drop policy if exists "pharmacies_select_scoped"
on public.pharmacies;

drop policy if exists "pharmacies_insert_scoped"
on public.pharmacies;

drop policy if exists "pharmacies_update_scoped"
on public.pharmacies;

drop policy if exists "pharmacies_delete_scoped"
on public.pharmacies;


create policy "pharmacies_select_scoped"
on public.pharmacies
for select
to anon, authenticated
using (
  (
    auth.uid() is null
    and guest_id = public.sana_guest_scope()
    and user_id is null
  )
  or
  (
    auth.uid() is not null
    and user_id = auth.uid()
  )
  or
  (
    exists (
      select 1
      from public.users u
      where u.id = auth.uid()
        and lower(coalesce(u.role, 'user')) = 'admin'
    )
  )
);


create policy "pharmacies_insert_scoped"
on public.pharmacies
for insert
to anon, authenticated
with check (
  (
    auth.uid() is null
    and guest_id = public.sana_guest_scope()
    and user_id is null
  )
  or
  (
    auth.uid() is not null
    and user_id = auth.uid()
    and guest_id is null
  )
  or
  (
    exists (
      select 1
      from public.users u
      where u.id = auth.uid()
        and lower(coalesce(u.role, 'user')) = 'admin'
    )
  )
);


create policy "pharmacies_update_scoped"
on public.pharmacies
for update
to anon, authenticated
using (
  (
    auth.uid() is null
    and guest_id = public.sana_guest_scope()
    and user_id is null
  )
  or
  (
    auth.uid() is not null
    and user_id = auth.uid()
  )
  or
  (
    exists (
      select 1
      from public.users u
      where u.id = auth.uid()
        and lower(coalesce(u.role, 'user')) = 'admin'
    )
  )
)
with check (
  (
    auth.uid() is null
    and guest_id = public.sana_guest_scope()
    and user_id is null
  )
  or
  (
    auth.uid() is not null
    and user_id = auth.uid()
    and guest_id is null
  )
  or
  (
    exists (
      select 1
      from public.users u
      where u.id = auth.uid()
        and lower(coalesce(u.role, 'user')) = 'admin'
    )
  )
);


create policy "pharmacies_delete_scoped"
on public.pharmacies
for delete
to anon, authenticated
using (
  (
    auth.uid() is null
    and guest_id = public.sana_guest_scope()
    and user_id is null
  )
  or
  (
    auth.uid() is not null
    and user_id = auth.uid()
  )
  or
  (
    exists (
      select 1
      from public.users u
      where u.id = auth.uid()
        and lower(coalesce(u.role, 'user')) = 'admin'
    )
  )
);


-- ============================================================
-- 9. INSURANCE CARDS
-- ============================================================

drop policy if exists "insurance_cards_select_scoped"
on public.insurance_cards;

drop policy if exists "insurance_cards_insert_scoped"
on public.insurance_cards;

drop policy if exists "insurance_cards_update_scoped"
on public.insurance_cards;

drop policy if exists "insurance_cards_delete_scoped"
on public.insurance_cards;


create policy "insurance_cards_select_scoped"
on public.insurance_cards
for select
to anon, authenticated
using (
  (
    auth.uid() is null
    and guest_id = public.sana_guest_scope()
    and user_id is null
  )
  or
  (
    auth.uid() is not null
    and user_id = auth.uid()
  )
  or
  (
    exists (
      select 1
      from public.users u
      where u.id = auth.uid()
        and lower(coalesce(u.role, 'user')) = 'admin'
    )
  )
);


create policy "insurance_cards_insert_scoped"
on public.insurance_cards
for insert
to anon, authenticated
with check (
  (
    auth.uid() is null
    and guest_id = public.sana_guest_scope()
    and user_id is null
  )
  or
  (
    auth.uid() is not null
    and user_id = auth.uid()
    and guest_id is null
  )
  or
  (
    exists (
      select 1
      from public.users u
      where u.id = auth.uid()
        and lower(coalesce(u.role, 'user')) = 'admin'
    )
  )
);


create policy "insurance_cards_update_scoped"
on public.insurance_cards
for update
to anon, authenticated
using (
  (
    auth.uid() is null
    and guest_id = public.sana_guest_scope()
    and user_id is null
  )
  or
  (
    auth.uid() is not null
    and user_id = auth.uid()
  )
  or
  (
    exists (
      select 1
      from public.users u
      where u.id = auth.uid()
        and lower(coalesce(u.role, 'user')) = 'admin'
    )
  )
)
with check (
  (
    auth.uid() is null
    and guest_id = public.sana_guest_scope()
    and user_id is null
  )
  or
  (
    auth.uid() is not null
    and user_id = auth.uid()
    and guest_id is null
  )
  or
  (
    exists (
      select 1
      from public.users u
      where u.id = auth.uid()
        and lower(coalesce(u.role, 'user')) = 'admin'
    )
  )
);


create policy "insurance_cards_delete_scoped"
on public.insurance_cards
for delete
to anon, authenticated
using (
  (
    auth.uid() is null
    and guest_id = public.sana_guest_scope()
    and user_id is null
  )
  or
  (
    auth.uid() is not null
    and user_id = auth.uid()
  )
  or
  (
    exists (
      select 1
      from public.users u
      where u.id = auth.uid()
        and lower(coalesce(u.role, 'user')) = 'admin'
    )
  )
);


-- ============================================================
-- 10. SAFETY CHECK CONSTRAINTS
-- ============================================================

-- A private record must not simultaneously identify itself
-- as a guest record.

do $$
begin

  if not exists (
    select 1
    from pg_constraint
    where conname = 'medications_scope_consistency'
      and conrelid = 'public.medications'::regclass
  ) then
    alter table public.medications
    add constraint medications_scope_consistency
    check (
      not (
        user_id is not null
        and guest_id is not null
      )
    );
  end if;


  if not exists (
    select 1
    from pg_constraint
    where conname = 'doctors_scope_consistency'
      and conrelid = 'public.doctors'::regclass
  ) then
    alter table public.doctors
    add constraint doctors_scope_consistency
    check (
      not (
        user_id is not null
        and guest_id is not null
      )
    );
  end if;


  if not exists (
    select 1
    from pg_constraint
    where conname = 'pharmacies_scope_consistency'
      and conrelid = 'public.pharmacies'::regclass
  ) then
    alter table public.pharmacies
    add constraint pharmacies_scope_consistency
    check (
      not (
        user_id is not null
        and guest_id is not null
      )
    );
  end if;


  if not exists (
    select 1
    from pg_constraint
    where conname = 'insurance_cards_scope_consistency'
      and conrelid = 'public.insurance_cards'::regclass
  ) then
    alter table public.insurance_cards
    add constraint insurance_cards_scope_consistency
    check (
      not (
        user_id is not null
        and guest_id is not null
      )
    );
  end if;

end
$$;


-- ============================================================
-- END
-- ============================================================