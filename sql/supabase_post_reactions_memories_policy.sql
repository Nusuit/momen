-- Fix: memories visibility + reaction access rules.
-- Rules:
-- 1) Shared Memories (owner_id is null): own + accepted-friend posts immediately (anonymous allowed).
-- 2) Owner Memories (owner_id is set):
--    - self: all own posts
--    - friend: only revealed posts after 3 days
-- 3) Reactions follow shared Memories visibility.
-- Run this in Supabase SQL Editor for existing databases.

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
      -- Shared feed: own + accepted-friend posts immediately.
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
      -- Owner-specific feed.
      owner_id is not null
      and p.user_id = owner_id
      and (
        -- Viewing self owner feed.
        owner_id = auth.uid()
        or (
          -- Viewing a friend owner feed: only revealed posts after 3 days.
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
