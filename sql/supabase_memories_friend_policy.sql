-- Enable two-tier Memories visibility.
-- 1) Shared Memories (owner_id is null): own + accepted-friend posts immediately.
-- 2) Owner Memories (owner_id is set):
--    - self: all own posts
--    - friend: only revealed posts after 3 days.
-- Run once in Supabase SQL editor.

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
