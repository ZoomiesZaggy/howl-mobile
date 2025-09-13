-- Enable UUID generator
create extension if not exists "pgcrypto";

-- ===== Tables =====
create table if not exists public.users_profile (
  user_id uuid primary key references auth.users(id) on delete cascade,
  handle text unique,
  age_verified boolean default false,
  created_at timestamptz default now()
);

create table if not exists public.event (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  starts_at timestamptz not null,
  city text,
  address text,
  sfw boolean default true,
  created_at timestamptz default now()
);

create table if not exists public.post (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users_profile(user_id) on delete cascade,
  text text not null check (char_length(text) <= 500),
  media_urls text[] default '{}',
  hashtags text[] default '{}',
  nsfw boolean default false,
  created_at timestamptz default now()
);

-- ===== Auto-create a profile row on new auth user =====
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.users_profile (user_id) values (new.id)
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- ===== Enable Row Level Security =====
alter table public.users_profile enable row level security;
alter table public.event        enable row level security;
alter table public.post         enable row level security;

-- ===== Policies (drop-then-create; safe to re-run) =====
-- events: anyone can read
drop policy if exists "read events" on public.event;
create policy "read events" on public.event
  for select using (true);

-- posts: anyone can read SFW; owner can always read their own
drop policy if exists "read posts (sfw or owner)" on public.post;
create policy "read posts (sfw or owner)" on public.post
  for select using (nsfw = false or auth.uid() = user_id);

-- posts: only logged-in users can create their own
drop policy if exists "write own posts" on public.post;
create policy "write own posts" on public.post
  for insert to authenticated
  with check (auth.uid() = user_id);

-- profile: user manages their own profile row
drop policy if exists "insert own profile" on public.users_profile;
create policy "insert own profile" on public.users_profile
  for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "update own profile" on public.users_profile;
create policy "update own profile" on public.users_profile
  for update to authenticated
  using (auth.uid() = user_id);

