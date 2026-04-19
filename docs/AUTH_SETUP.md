# Auth Setup (Supabase + Firebase)

This project now includes end-to-end auth flows in app code:
- Sign in / Sign up (email + password)
- Forgot Password / Reset Password
- OTP verification (email + phone)
- Google OAuth sign-in
- Refresh token call

Use this document to configure backend services before running these flows.

## 1. Supabase Project Setup

1. Create a Supabase project.
2. In Supabase Dashboard, get:
- Project URL
- Anon key
3. Run app with dart-define:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

### Optional: Run Flutter Web with fixed port from `.env`

If you keep local runtime values in `.env` (for example `FLUTTER_WEB_PORT=1708`), you can start web with one command:

```bash
set -a
source .env
set +a

flutter run -d chrome \
  --web-port "$FLUTTER_WEB_PORT" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
```

Use `http://localhost:1708` in Google OAuth Authorized JavaScript origins when testing web locally.

## 2. Supabase Auth Configuration

In Supabase Dashboard -> Authentication -> Providers:

1. Email:
- Enable Email provider.
- Enable "Confirm email" if you want OTP/verification before full activation.

2. Phone:
- Enable Phone provider.
- Configure SMS provider (Twilio/MessageBird/etc.) in Supabase.

3. Google OAuth:
- Enable Google provider.
- Add Google client ID/secret.
- Set redirect URL(s):
  - `https://YOUR_PROJECT.supabase.co/auth/v1/callback`
  - Add app deep-link redirect if using mobile deep links.
  - For this project default mobile callback: `momen://auth-callback`

4. URL Configuration:
- Site URL: your app/web URL.
- Additional Redirect URLs: include callback/deep-link URLs used by app.
  - Local web (example): `http://localhost:1708`
  - Mobile OAuth callback: `momen://auth-callback`
  - Mobile reset callback: `momen://reset-password`

Google Cloud Console OAuth Web client values:
- Authorized JavaScript origins:
  - `https://YOUR_PROJECT.supabase.co`
  - `http://localhost:1708` (if testing local web)
- Authorized redirect URIs:
  - `https://YOUR_PROJECT.supabase.co/auth/v1/callback`

## 3. Database Schema (Run in Supabase SQL Editor)

Run this SQL once to create minimum tables used by current app features.

```sql
-- profiles table for auth/profile/friend search
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  display_name text,
  phone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- keep updated_at fresh
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

-- create profile automatically after signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    coalesce(new.raw_user_meta_data ->> 'phone', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- friendships used by friend search/request
create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references auth.users(id) on delete cascade,
  addressee_id uuid not null references auth.users(id) on delete cascade,
  status text not null check (status in ('pending', 'accepted', 'rejected')),
  created_at timestamptz not null default now(),
  unique(requester_id, addressee_id)
);

-- posts used by camera/memories/dashboard
create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  image_path text not null,
  caption text,
  amount_vnd integer,
  created_at timestamptz not null default now()
);

create index if not exists idx_posts_user_created_at
  on public.posts (user_id, created_at desc);

create index if not exists idx_profiles_username
  on public.profiles (username);
```

## 4. Row Level Security Policies (Run in SQL Editor)

```sql
alter table public.profiles enable row level security;
alter table public.friendships enable row level security;
alter table public.posts enable row level security;

-- profiles
create policy if not exists "profiles_select_authenticated"
on public.profiles for select
using (auth.role() = 'authenticated');

create policy if not exists "profiles_insert_self"
on public.profiles for insert
with check (auth.uid() = id);

create policy if not exists "profiles_update_self"
on public.profiles for update
using (auth.uid() = id)
with check (auth.uid() = id);

-- friendships
create policy if not exists "friendships_select_own"
on public.friendships for select
using (auth.uid() = requester_id or auth.uid() = addressee_id);

create policy if not exists "friendships_insert_requester"
on public.friendships for insert
with check (auth.uid() = requester_id);

create policy if not exists "friendships_update_participants"
on public.friendships for update
using (auth.uid() = requester_id or auth.uid() = addressee_id)
with check (auth.uid() = requester_id or auth.uid() = addressee_id);

-- posts
create policy if not exists "posts_select_own"
on public.posts for select
using (auth.uid() = user_id);

create policy if not exists "posts_insert_own"
on public.posts for insert
with check (auth.uid() = user_id);

create policy if not exists "posts_update_own"
on public.posts for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy if not exists "posts_delete_own"
on public.posts for delete
using (auth.uid() = user_id);
```

## 5. Storage Bucket Setup (post_images)

In Supabase -> Storage:
1. Create bucket: `post_images`
2. Set bucket to Public (because current code uses `getPublicUrl`).

Optional policies for write/delete ownership by path prefix user_id:

```sql
-- storage.objects policies (Supabase SQL)
create policy if not exists "storage_post_images_insert_own"
on storage.objects for insert
with check (
  bucket_id = 'post_images'
  and auth.role() = 'authenticated'
  and split_part(name, '/', 1) = auth.uid()::text
);

create policy if not exists "storage_post_images_delete_own"
on storage.objects for delete
using (
  bucket_id = 'post_images'
  and auth.role() = 'authenticated'
  and split_part(name, '/', 1) = auth.uid()::text
);
```

## 6. Firebase Crashlytics Setup

If you want Crashlytics enabled:

1. Create Firebase project.
2. Add Android/iOS app with your final package IDs.
3. Install FlutterFire CLI and configure:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

4. Run app with flag:

```bash
flutter run --dart-define=ENABLE_FIREBASE_CRASHLYTICS=true \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

## 7. Auth Flow Notes

1. Email sign-up may require OTP/email confirmation depending on Supabase Email settings.
2. Reset password flow in app expects recovery OTP + new password.
3. Google OAuth on mobile needs deep-link redirect setup in platform configs.
4. Phone login needs working SMS provider in Supabase.

## 8. Quick Verification Checklist

1. Sign up with email/password.
2. Verify OTP if confirmation enabled.
3. Sign in with email/password.
4. Request and verify phone OTP login.
5. Trigger forgot/reset password flow.
6. Start Google OAuth login and verify callback completes.
7. Confirm `profiles`, `posts`, and `friendships` records are readable under RLS.
