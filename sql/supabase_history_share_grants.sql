-- ==========================================
-- FEATURE: Friend History Sharing (Phương án A)
-- Description: Stores grants where a user allows a friend to see 30 days of past photo history.
-- ==========================================

-- 1. Create the table
create table if not exists public.history_share_grants (
  id uuid primary key default gen_random_uuid(),
  granter_id uuid references auth.users(id) on delete cascade not null,
  grantee_id uuid references auth.users(id) on delete cascade not null,
  granted_at timestamp with time zone default now() not null,
  unique(granter_id, grantee_id)
);

-- 2. Enable RLS
alter table public.history_share_grants enable row level security;

-- 3. Policies
-- Users can view grants where they are either the granter or the grantee
create policy "Users can view their own grants"
  on public.history_share_grants for select
  using (auth.uid() = granter_id or auth.uid() = grantee_id);

-- Users can only insert grants where they are the granter (sharing their own history)
create policy "Users can insert their own grants"
  on public.history_share_grants for insert
  with check (auth.uid() = granter_id);

-- Add comments for documentation
comment on table public.history_share_grants is 'Stores history sharing permissions between friends.';
comment on column public.history_share_grants.granter_id is 'The user who is sharing their history.';
comment on column public.history_share_grants.grantee_id is 'The friend who is allowed to see the history.';
