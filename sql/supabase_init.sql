-- Run this file in Supabase SQL Editor once.
-- It creates core tables, trigger functions, and RLS policies used by the app.

-- 0) Extensions
create extension if not exists postgis;

-- 1) Tables
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  date_of_birth date,
  user_code text unique,
  phone_number text,
  is_phone_verified boolean not null default false,
  phone_verified_at timestamptz,
  phone_hash text unique,
  avatar_path text,
  location geography(Point, 4326),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles
  add column if not exists full_name text,
  add column if not exists date_of_birth date,
  add column if not exists user_code text,
  add column if not exists phone_number text,
  add column if not exists is_phone_verified boolean not null default false,
  add column if not exists phone_verified_at timestamptz,
  add column if not exists phone_hash text,
  add column if not exists avatar_path text,
  add column if not exists location geography(Point, 4326);

-- Unique constraints (safe to re-run)
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'profiles_user_code_key'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles add constraint profiles_user_code_key unique (user_code);
  end if;
  if not exists (
    select 1 from pg_constraint
    where conname = 'profiles_phone_hash_key'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles add constraint profiles_phone_hash_key unique (phone_hash);
  end if;
end;
$$;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'display_name'
  ) and exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'username'
  ) then
    execute '
      update public.profiles
      set full_name = coalesce(
        nullif(trim(full_name), ''''),
        nullif(trim(display_name), ''''),
        nullif(trim(username), ''''),
        full_name
      )
    ';
  elsif exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'display_name'
  ) then
    execute '
      update public.profiles
      set full_name = coalesce(
        nullif(trim(full_name), ''''),
        nullif(trim(display_name), ''''),
        full_name
      )
    ';
  elsif exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'username'
  ) then
    execute '
      update public.profiles
      set full_name = coalesce(
        nullif(trim(full_name), ''''),
        nullif(trim(username), ''''),
        full_name
      )
    ';
  end if;
end;
$$;

create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references auth.users(id) on delete cascade,
  addressee_id uuid not null references auth.users(id) on delete cascade,
  status text not null check (status in ('pending', 'accepted', 'rejected')),
  created_at timestamptz not null default now(),
  unique(requester_id, addressee_id)
);

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  image_path text not null,
  caption text,
  amount_vnd integer,
  is_revealed boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.posts
  add column if not exists is_revealed boolean not null default false;

create table if not exists public.user_blocks (
  blocker_id uuid not null references auth.users(id) on delete cascade,
  blocked_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id)
);

create table if not exists public.user_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  reported_id uuid not null references auth.users(id) on delete cascade,
  reason text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.post_reactions (
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  reaction_type text not null check (reaction_type in ('love', 'haha', 'sad')),
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table if not exists public.post_reports (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  reporter_id uuid not null references auth.users(id) on delete cascade,
  reason text not null,
  created_at timestamptz not null default now()
);

-- Indexes
create index if not exists idx_posts_user_created_at
  on public.posts (user_id, created_at desc);

create index if not exists idx_profiles_full_name
  on public.profiles (full_name);

create index if not exists idx_profiles_user_code
  on public.profiles (user_code);

create index if not exists idx_profiles_phone_verified
  on public.profiles (is_phone_verified);

create index if not exists idx_profiles_location
  on public.profiles using gist(location);

create index if not exists idx_post_reactions_post
  on public.post_reactions (post_id, reaction_type);

create index if not exists idx_post_reports_post
  on public.post_reports (post_id);

drop index if exists idx_profiles_username;

alter table public.profiles drop column if exists username;
alter table public.profiles drop column if exists display_name;
alter table public.profiles drop column if exists phone;

-- 2) Trigger helpers
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

-- Generates a unique 8-character alphanumeric user code (e.g. "AB3K7XPQ")
create or replace function public.generate_user_code()
returns text
language plpgsql
as $$
declare
  chars      text    := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  result     text    := '';
  i          int;
  code_taken boolean;
begin
  loop
    result := '';
    for i in 1..8 loop
      result := result || substr(chars, floor(random() * 32 + 1)::int, 1);
    end loop;
    select exists(
      select 1 from public.profiles where user_code = result
    ) into code_taken;
    exit when not code_taken;
  end loop;
  return result;
end;
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  new_code text;
begin
  new_code := public.generate_user_code();
  insert into public.profiles (
    id,
    full_name,
    date_of_birth,
    user_code,
    phone_number,
    is_phone_verified,
    phone_verified_at,
    avatar_path
  )
  values (
    new.id,
    coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
      nullif(trim(new.raw_user_meta_data ->> 'name'), ''),
      nullif(trim(new.raw_user_meta_data ->> 'user_name'), ''),
      nullif(trim(new.raw_user_meta_data ->> 'preferred_username'), ''),
      ''
    ),
    nullif(new.raw_user_meta_data ->> 'date_of_birth', '')::date,
    new_code,
    nullif(trim(new.phone), ''),
    (nullif(trim(new.phone), '') is not null),
    case when nullif(trim(new.phone), '') is not null then now() else null end,
    coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'avatar_url'), ''),
      nullif(trim(new.raw_user_meta_data ->> 'picture'), '')
    )
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- Backfill user_code for existing profiles without one
do $$
declare
  r record;
begin
  for r in select id from public.profiles where user_code is null loop
    update public.profiles
    set user_code = public.generate_user_code()
    where id = r.id;
  end loop;
end;
$$;

-- Backfill OAuth profile names/avatars for existing users when profile fields are blank.
update public.profiles p
set
  full_name = coalesce(
    nullif(trim(p.full_name), ''),
    nullif(trim(u.raw_user_meta_data ->> 'full_name'), ''),
    nullif(trim(u.raw_user_meta_data ->> 'name'), ''),
    nullif(trim(u.raw_user_meta_data ->> 'user_name'), ''),
    nullif(trim(u.raw_user_meta_data ->> 'preferred_username'), ''),
    p.full_name
  ),
  avatar_path = coalesce(
    nullif(trim(p.avatar_path), ''),
    nullif(trim(u.raw_user_meta_data ->> 'avatar_url'), ''),
    nullif(trim(u.raw_user_meta_data ->> 'picture'), ''),
    p.avatar_path
  )
from auth.users u
where u.id = p.id
  and (
    nullif(trim(p.full_name), '') is null
    or nullif(trim(p.avatar_path), '') is null
  );

-- 3) RPC Functions

-- Returns users within radius_m metres. Distance is bucketed to 500 m for privacy.
create or replace function public.get_nearby_users(
  lat      double precision,
  lon      double precision,
  radius_m int default 5000
)
returns table(
  id         uuid,
  full_name  text,
  user_code  text,
  avatar_path text,
  distance_m double precision
)
language sql
stable
security definer
set search_path = public
as $$
  select
    p.id,
    p.full_name,
    p.user_code,
    p.avatar_path,
    round(
      ST_Distance(p.location, ST_MakePoint(lon, lat)::geography) / 500.0
    ) * 500.0 as distance_m
  from public.profiles p
  where p.id != auth.uid()
    and p.location is not null
    and ST_DWithin(p.location, ST_MakePoint(lon, lat)::geography, radius_m)
  order by ST_Distance(p.location, ST_MakePoint(lon, lat)::geography)
  limit 20;
$$;

-- Returns profiles whose SHA-256 phone hash matches any entry in the provided array
create or replace function public.match_contacts(
  phone_hashes text[]
)
returns table(
  id          uuid,
  full_name   text,
  user_code   text,
  avatar_path text,
  matched_phone_hash text
)
language sql
stable
security definer
set search_path = public
as $$
  select p.id, p.full_name, p.user_code, p.avatar_path, p.phone_hash as matched_phone_hash
  from public.profiles p
  where p.id != auth.uid()
    and p.phone_hash = any(phone_hashes)
  limit 50;
$$;

-- Returns memories with two-tier visibility:
-- 1) Shared Memories (owner_id is null): own + accepted-friend posts immediately.
-- 2) Owner Memories (owner_id is set):
--    - self: all own posts
--    - friend: only revealed posts after 3 days.
create or replace function public.get_memories_posts(
  owner_id uuid default null,
  p_page int default 0,
  p_page_size int default 20
)
returns table(
  id uuid,
  image_path text,
  caption text,
  amount_vnd integer,
  created_at timestamptz,
  user_id uuid,
  is_revealed boolean
)
language sql
stable
security definer
set search_path = public
as $$
  select
    p.id,
    p.image_path,
    p.caption,
    p.amount_vnd,
    p.created_at,
    p.user_id,
    p.is_revealed
  from public.posts p
  where (
      owner_id is null
      and (
        p.user_id = auth.uid()
        or exists (
          select 1
          from public.friendships f
          where f.status = 'accepted'
            and (
              (f.requester_id = auth.uid() and f.addressee_id = p.user_id)
              or (f.addressee_id = auth.uid() and f.requester_id = p.user_id)
            )
        )
      )
    )
    or (
      owner_id is not null
      and p.user_id = owner_id
      and (
        owner_id = auth.uid()
        or (
          p.is_revealed = true
          and p.created_at <= now() - interval '3 days'
          and exists (
            select 1
            from public.friendships f
            where f.status = 'accepted'
              and (
                (f.requester_id = auth.uid() and f.addressee_id = owner_id)
                or (f.addressee_id = auth.uid() and f.requester_id = owner_id)
              )
          )
        )
      )
    )
  order by p.created_at desc
  offset greatest(p_page, 0) * greatest(p_page_size, 1)
  limit greatest(p_page_size, 1);
$$;

grant execute on function public.get_memories_posts(uuid, int, int) to authenticated;

-- Returns true when current user can access a post in shared Memories context
-- (own post, or accepted-friend post regardless of age).
create or replace function public.can_access_memory_post(
  p_post_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.posts p
    where p.id = p_post_id
      and (
        p.user_id = auth.uid()
        or exists (
          select 1
          from public.friendships f
          where f.status = 'accepted'
            and (
              (f.requester_id = auth.uid() and f.addressee_id = p.user_id)
              or (f.addressee_id = auth.uid() and f.requester_id = p.user_id)
            )
        )
      )
  );
$$;

grant execute on function public.can_access_memory_post(uuid) to authenticated;

-- 4) RLS
alter table public.profiles     enable row level security;
alter table public.friendships  enable row level security;
alter table public.posts        enable row level security;
alter table public.user_blocks  enable row level security;
alter table public.user_reports enable row level security;
alter table public.post_reactions enable row level security;
alter table public.post_reports enable row level security;

-- Profiles
drop policy if exists "profiles_select_authenticated" on public.profiles;
create policy "profiles_select_authenticated"
on public.profiles for select
using (auth.role() = 'authenticated');

drop policy if exists "profiles_insert_self" on public.profiles;
create policy "profiles_insert_self"
on public.profiles for insert
with check (auth.uid() = id);

drop policy if exists "profiles_update_self" on public.profiles;
create policy "profiles_update_self"
on public.profiles for update
using (auth.uid() = id)
with check (auth.uid() = id);

-- Friendships
drop policy if exists "friendships_select_own" on public.friendships;
create policy "friendships_select_own"
on public.friendships for select
using (auth.uid() = requester_id or auth.uid() = addressee_id);

drop policy if exists "friendships_insert_requester" on public.friendships;
create policy "friendships_insert_requester"
on public.friendships for insert
with check (auth.uid() = requester_id);

drop policy if exists "friendships_update_participants" on public.friendships;
drop policy if exists "friendships_update_addressee_decision" on public.friendships;
create policy "friendships_update_addressee_decision"
on public.friendships for update
using (auth.uid() = addressee_id and status = 'pending')
with check (auth.uid() = addressee_id and status in ('accepted', 'rejected'));

drop policy if exists "friendships_delete_requester_pending" on public.friendships;
create policy "friendships_delete_requester_pending"
on public.friendships for delete
using (auth.uid() = requester_id and status = 'pending');

drop policy if exists "friendships_delete_accepted_participants" on public.friendships;
create policy "friendships_delete_accepted_participants"
on public.friendships for delete
using (
  status = 'accepted'
  and (auth.uid() = requester_id or auth.uid() = addressee_id)
);

-- Posts: owner always; accepted friends after 3 days (anonymous until then)
drop policy if exists "posts_select_own" on public.posts;
drop policy if exists "posts_select_own_or_accepted_friends" on public.posts;
create policy "posts_select_own_or_accepted_friends"
on public.posts for select
using (
  auth.uid() = user_id
  or exists (
    select 1
    from public.friendships f
    where f.status = 'accepted'
      and posts.created_at <= now() - interval '3 days'
      and (
        (f.requester_id = auth.uid() and f.addressee_id = posts.user_id)
        or (f.addressee_id = auth.uid() and f.requester_id = posts.user_id)
      )
  )
);

drop policy if exists "posts_insert_own" on public.posts;
create policy "posts_insert_own"
on public.posts for insert
with check (auth.uid() = user_id);

drop policy if exists "posts_update_own" on public.posts;
create policy "posts_update_own"
on public.posts for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "posts_delete_own" on public.posts;
create policy "posts_delete_own"
on public.posts for delete
using (auth.uid() = user_id);

-- User blocks
drop policy if exists "blocks_select_own" on public.user_blocks;
create policy "blocks_select_own"
on public.user_blocks for select
using (auth.uid() = blocker_id);

drop policy if exists "blocks_insert_own" on public.user_blocks;
create policy "blocks_insert_own"
on public.user_blocks for insert
with check (auth.uid() = blocker_id and auth.uid() != blocked_id);

drop policy if exists "blocks_delete_own" on public.user_blocks;
create policy "blocks_delete_own"
on public.user_blocks for delete
using (auth.uid() = blocker_id);

-- User reports: write-only for reporters; reads reserved for admins
drop policy if exists "reports_insert_own" on public.user_reports;
create policy "reports_insert_own"
on public.user_reports for insert
with check (auth.uid() = reporter_id and auth.uid() != reported_id);

-- Post reactions: authenticated viewers can react once per post.
drop policy if exists "post_reactions_select_visible" on public.post_reactions;
create policy "post_reactions_select_visible"
on public.post_reactions for select
using (
  auth.role() = 'authenticated'
  and public.can_access_memory_post(post_reactions.post_id)
);

drop policy if exists "post_reactions_insert_own_visible" on public.post_reactions;
create policy "post_reactions_insert_own_visible"
on public.post_reactions for insert
with check (
  auth.uid() = user_id
  and public.can_access_memory_post(post_reactions.post_id)
);

drop policy if exists "post_reactions_update_own_visible" on public.post_reactions;
create policy "post_reactions_update_own_visible"
on public.post_reactions for update
using (auth.uid() = user_id)
with check (
  auth.uid() = user_id
  and public.can_access_memory_post(post_reactions.post_id)
);

drop policy if exists "post_reactions_delete_own" on public.post_reactions;
create policy "post_reactions_delete_own"
on public.post_reactions for delete
using (auth.uid() = user_id);

-- Post reports: viewers can report posts they do not own; reads reserved for admins.
drop policy if exists "post_reports_insert_visible_not_own" on public.post_reports;
create policy "post_reports_insert_visible_not_own"
on public.post_reports for insert
with check (
  auth.uid() = reporter_id
  and exists (
    select 1 from public.posts p
    where p.id = post_reports.post_id
      and p.user_id != auth.uid()
  )
);

-- 5) Storage buckets
insert into storage.buckets (id, name, public)
values ('post_images', 'post_images', true)
on conflict (id) do update
set name = excluded.name, public = excluded.public;

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update
set name = excluded.name, public = excluded.public;

drop policy if exists "storage_post_images_insert_own" on storage.objects;
create policy "storage_post_images_insert_own"
on storage.objects for insert
with check (
  bucket_id = 'post_images'
  and auth.role() = 'authenticated'
  and split_part(name, '/', 1) = auth.uid()::text
);

drop policy if exists "storage_post_images_delete_own" on storage.objects;
create policy "storage_post_images_delete_own"
on storage.objects for delete
using (
  bucket_id = 'post_images'
  and auth.role() = 'authenticated'
  and split_part(name, '/', 1) = auth.uid()::text
);

drop policy if exists "storage_avatars_insert_own" on storage.objects;
create policy "storage_avatars_insert_own"
on storage.objects for insert
with check (
  bucket_id = 'avatars'
  and auth.role() = 'authenticated'
  and split_part(name, '/', 1) = auth.uid()::text
);

drop policy if exists "storage_avatars_update_own" on storage.objects;
create policy "storage_avatars_update_own"
on storage.objects for update
using (
  bucket_id = 'avatars'
  and auth.role() = 'authenticated'
  and split_part(name, '/', 1) = auth.uid()::text
);

-- 6) Quick checks
select table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in ('profiles', 'friendships', 'posts', 'post_reactions', 'post_reports', 'user_blocks', 'user_reports')
order by table_name;

select tablename, rowsecurity
from pg_tables
where schemaname = 'public'
  and tablename in ('profiles', 'friendships', 'posts', 'post_reactions', 'post_reports', 'user_blocks', 'user_reports')
order by tablename;
