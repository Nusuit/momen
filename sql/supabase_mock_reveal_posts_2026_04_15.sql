-- Mock posts for reveal reminder testing
-- Target account: huykien283@gmail.com
-- Run after sql/supabase_reveal_reminder_worker.sql

do $$
declare
  v_user_id uuid;
begin
  select id
  into v_user_id
  from auth.users
  where lower(email) = lower('huykien283@gmail.com')
  limit 1;

  if v_user_id is null then
    raise exception 'User huykien283@gmail.com not found in auth.users';
  end if;

  insert into public.posts (
    user_id,
    image_path,
    caption,
    amount_vnd,
    is_revealed,
    created_at
  )
  values
    (
      v_user_id,
      'https://picsum.photos/seed/momen-reveal-1/900/1200',
      'Mock post A - waiting reveal reminder',
      120000,
      false,
      timestamptz '2026-04-15 09:10:00+07'
    ),
    (
      v_user_id,
      'https://picsum.photos/seed/momen-reveal-2/900/1200',
      'Mock post B - waiting reveal reminder',
      85000,
      false,
      timestamptz '2026-04-15 12:45:00+07'
    ),
    (
      v_user_id,
      'https://picsum.photos/seed/momen-reveal-3/900/1200',
      'Mock post C - waiting reveal reminder',
      230000,
      false,
      timestamptz '2026-04-15 18:00:00+07'
    );

  perform public.enqueue_reveal_reminders();
end;
$$;
