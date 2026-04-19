-- Reveal reminder worker + queue + RPC
-- Purpose: day-based 3-day reminder to reveal or keep anonymous.
-- Example: post at 18:00 on 15/04 => reminder becomes eligible from 00:00 on 18/04 (Asia/Ho_Chi_Minh).
-- Run this in Supabase SQL Editor.

create extension if not exists pg_cron;

create table if not exists public.reveal_reminders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  post_id uuid not null references public.posts(id) on delete cascade,
  due_at timestamptz not null,
  status text not null default 'pending' check (status in ('pending', 'revealed', 'skipped')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  unique (post_id)
);

create index if not exists idx_reveal_reminders_user_status_due
  on public.reveal_reminders (user_id, status, due_at);

alter table public.reveal_reminders enable row level security;

drop policy if exists "reveal_reminders_select_own" on public.reveal_reminders;
create policy "reveal_reminders_select_own"
on public.reveal_reminders for select
using (auth.uid() = user_id);

drop policy if exists "reveal_reminders_update_own_pending" on public.reveal_reminders;
create policy "reveal_reminders_update_own_pending"
on public.reveal_reminders for update
using (auth.uid() = user_id and status = 'pending')
with check (auth.uid() = user_id and status in ('revealed', 'skipped'));

create or replace function public.enqueue_reveal_reminders()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  inserted_count integer := 0;
begin
  -- Keep pending due_at aligned with day-based logic.
  update public.reveal_reminders r
  set due_at = (
    ((p.created_at at time zone 'Asia/Ho_Chi_Minh')::date + 3)::timestamp
    at time zone 'Asia/Ho_Chi_Minh'
  )
  from public.posts p
  where r.post_id = p.id
    and r.status = 'pending';

  insert into public.reveal_reminders (user_id, post_id, due_at)
  select
    p.user_id,
    p.id,
    ((p.created_at at time zone 'Asia/Ho_Chi_Minh')::date + 3)::timestamp
      at time zone 'Asia/Ho_Chi_Minh'
  from public.posts p
  where p.is_revealed = false
    and (
      ((p.created_at at time zone 'Asia/Ho_Chi_Minh')::date + 3)::timestamp
        at time zone 'Asia/Ho_Chi_Minh'
    ) <= now()
    and not exists (
      select 1
      from public.reveal_reminders r
      where r.post_id = p.id
    );

  get diagnostics inserted_count = row_count;
  return inserted_count;
end;
$$;

create or replace function public.get_pending_reveal_reminders()
returns table(
  reminder_id uuid,
  post_id uuid,
  image_path text,
  caption text,
  created_at timestamptz,
  due_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    r.id as reminder_id,
    p.id as post_id,
    p.image_path,
    p.caption,
    p.created_at,
    r.due_at
  from public.reveal_reminders r
  join public.posts p on p.id = r.post_id
  where r.user_id = auth.uid()
    and r.status = 'pending'
    and r.due_at <= now()
    and p.is_revealed = false
  order by r.due_at asc
  limit 10;
$$;

grant execute on function public.get_pending_reveal_reminders() to authenticated;

create or replace function public.resolve_reveal_reminder(
  p_reminder_id uuid,
  p_reveal boolean
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_post_id uuid;
begin
  select post_id
  into v_post_id
  from public.reveal_reminders
  where id = p_reminder_id
    and user_id = auth.uid()
    and status = 'pending'
  limit 1;

  if v_post_id is null then
    return false;
  end if;

  if p_reveal then
    update public.posts
    set is_revealed = true
    where id = v_post_id
      and user_id = auth.uid();
  end if;

  update public.reveal_reminders
  set
    status = case when p_reveal then 'revealed' else 'skipped' end,
    resolved_at = now()
  where id = p_reminder_id
    and user_id = auth.uid()
    and status = 'pending';

  return true;
end;
$$;

grant execute on function public.resolve_reveal_reminder(uuid, boolean) to authenticated;

-- Backfill reminders now for already-due posts.
select public.enqueue_reveal_reminders();

-- Schedule worker every 15 minutes (idempotent registration).
do $$
begin
  if exists (
    select 1
    from pg_namespace
    where nspname = 'cron'
  ) then
    if not exists (
      select 1
      from cron.job
      where jobname = 'enqueue_reveal_reminders_every_15m'
    ) then
      perform cron.schedule(
        'enqueue_reveal_reminders_every_15m',
        '*/15 * * * *',
        $job$select public.enqueue_reveal_reminders();$job$
      );
    end if;
  end if;
end;
$$;
