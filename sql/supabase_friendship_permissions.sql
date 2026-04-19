-- Friendship permission hardening.
-- Run in Supabase SQL editor after sql/supabase_init.sql

alter table public.friendships enable row level security;

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

-- posts visibility remains: self immediately, friends after 3 days
alter table public.posts enable row level security;
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
