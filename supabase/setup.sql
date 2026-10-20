-- Budget Buddy: Supabase setup
--
-- Paste this whole file into Supabase > SQL Editor > New query and press Run.
-- It is safe to run again: it never drops or deletes anything.

-- 1. Transactions ------------------------------------------------------------

create table if not exists public.transactions (
  id                uuid primary key,
  user_id           uuid not null default auth.uid()
                    references auth.users (id) on delete cascade,
  title             text not null,
  description       text,
  amount            numeric not null,
  category          text,
  occurred_at       timestamptz not null,
  -- Set by the app when a transaction is edited. The newest edit wins.
  updated_at        timestamptz not null,
  -- Deletions are kept as markers so every device learns about them.
  deleted           boolean not null default false,
  -- Set by the database on every change. Devices download rows newer than
  -- the last one they saw.
  server_updated_at timestamptz not null default now(),
  -- Set once the optional AI function has looked at the row.
  ai_checked_at     timestamptz
);

create index if not exists transactions_user_changes_idx
  on public.transactions (user_id, server_updated_at);

-- Every signed-in user can only see and change their own rows.
alter table public.transactions enable row level security;

do $$
begin
  if not exists (select 1 from pg_policies
                 where schemaname = 'public' and tablename = 'transactions'
                   and policyname = 'Own transactions') then
    create policy "Own transactions" on public.transactions
      for all to authenticated
      using ((select auth.uid()) = user_id)
      with check ((select auth.uid()) = user_id);
  end if;
end;
$$;

grant select, insert, update, delete on public.transactions to authenticated;

create or replace function public.touch_server_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.server_updated_at := now();
  return new;
end;
$$;

create or replace trigger transactions_touch
  before insert or update on public.transactions
  for each row execute function public.touch_server_updated_at();

-- 2. Upload changes from the app ---------------------------------------------
-- Inserts new rows and updates existing ones only when the incoming edit is
-- newer. A missing category never erases one the AI function filled in.

create or replace function public.push_transactions(changes jsonb)
returns void
language sql
security invoker
set search_path = ''
as $$
  insert into public.transactions as t
    (id, user_id, title, description, amount, category,
     occurred_at, updated_at, deleted)
  select c.id, auth.uid(), c.title, c.description, c.amount, c.category,
         c.occurred_at, c.updated_at, coalesce(c.deleted, false)
  from jsonb_to_recordset(changes) as c (
    id uuid, title text, description text, amount numeric, category text,
    occurred_at timestamptz, updated_at timestamptz, deleted boolean
  )
  on conflict (id) do update set
    title         = excluded.title,
    description   = excluded.description,
    amount        = excluded.amount,
    category      = coalesce(excluded.category, t.category),
    occurred_at   = excluded.occurred_at,
    updated_at    = excluded.updated_at,
    deleted       = excluded.deleted,
    ai_checked_at = case when excluded.title is distinct from t.title
                         then null else t.ai_checked_at end
  where t.updated_at < excluded.updated_at;
$$;

revoke all on function public.push_transactions(jsonb) from public, anon;
grant execute on function public.push_transactions(jsonb) to authenticated;

-- 3. Per-user settings (starting balance) ------------------------------------

create table if not exists public.user_settings (
  user_id         uuid primary key default auth.uid()
                  references auth.users (id) on delete cascade,
  opening_balance numeric not null default 0,
  updated_at      timestamptz not null default now()
);

alter table public.user_settings enable row level security;

do $$
begin
  if not exists (select 1 from pg_policies
                 where schemaname = 'public' and tablename = 'user_settings'
                   and policyname = 'Own settings') then
    create policy "Own settings" on public.user_settings
      for all to authenticated
      using ((select auth.uid()) = user_id)
      with check ((select auth.uid()) = user_id);
  end if;
end;
$$;

grant select, insert, update, delete on public.user_settings to authenticated;

-- Make the API pick up the changes right away.
notify pgrst, 'reload schema';
