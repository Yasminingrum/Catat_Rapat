-- CatatRapat — Supabase PostgreSQL Schema
-- Jalankan di Supabase SQL Editor

-- ── Extensions ──────────────────────────────────────────────
create extension if not exists "uuid-ossp";

-- ── Profiles (extends auth.users) ───────────────────────────
create table profiles (
  id          uuid references auth.users on delete cascade primary key,
  name        text not null default '',
  email       text,
  avatar_url  text,
  plan        text not null default 'free' check (plan in ('free','pro','business')),
  token_used  integer not null default 0,
  token_total integer not null default 5000,
  created_at  timestamptz default now()
);
alter table profiles enable row level security;
create policy "Users can view own profile" on profiles for select using (auth.uid() = id);
create policy "Users can update own profile" on profiles for update using (auth.uid() = id);

-- Auto-create profile on signup
create or replace function handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, name, email)
  values (new.id, coalesce(new.raw_user_meta_data->>'name',''), new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function handle_new_user();

-- ── Meetings ────────────────────────────────────────────────
create table meetings (
  id              uuid default uuid_generate_v4() primary key,
  user_id         uuid references profiles(id) on delete cascade not null,
  title           text not null,
  agenda          text,
  date            text not null,
  time            text not null,
  duration        text default '0m',
  status          text default 'draft' check (status in ('draft','final_')),
  has_transcript  boolean default false,
  has_notula      boolean default false,
  has_audio       boolean default false,
  is_starred      boolean default false,
  audio_path      text,
  created_at      timestamptz default now(),
  updated_at      timestamptz default now()
);
alter table meetings enable row level security;
create policy "Users can CRUD own meetings" on meetings for all using (auth.uid() = user_id);
create index meetings_user_id_idx on meetings(user_id);
create index meetings_created_at_idx on meetings(created_at desc);

-- ── Participants ─────────────────────────────────────────────
create table participants (
  id          uuid default uuid_generate_v4() primary key,
  meeting_id  uuid references meetings(id) on delete cascade not null,
  speaker_id  text not null,  -- "S1", "S2"
  label       text not null,  -- "Suara 1"
  name        text default '',
  created_at  timestamptz default now()
);
alter table participants enable row level security;
create policy "Users can CRUD own participants" on participants for all
  using (exists (select 1 from meetings m where m.id = meeting_id and m.user_id = auth.uid()));

-- ── Transcripts ──────────────────────────────────────────────
create table transcript_lines (
  id          uuid default uuid_generate_v4() primary key,
  meeting_id  uuid references meetings(id) on delete cascade not null,
  timestamp   text not null,
  speaker_id  text not null,
  speaker     text not null,
  text        text not null,
  seq         integer not null default 0,
  created_at  timestamptz default now()
);
alter table transcript_lines enable row level security;
create policy "Users can CRUD own transcripts" on transcript_lines for all
  using (exists (select 1 from meetings m where m.id = meeting_id and m.user_id = auth.uid()));
create index transcript_meeting_idx on transcript_lines(meeting_id, seq);

-- ── Notulas ──────────────────────────────────────────────────
create table notulas (
  id          uuid default uuid_generate_v4() primary key,
  meeting_id  uuid references meetings(id) on delete cascade not null unique,
  ringkasan   text not null default '',
  keputusan   jsonb not null default '[]',
  action_items jsonb not null default '[]',
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);
alter table notulas enable row level security;
create policy "Users can CRUD own notulas" on notulas for all
  using (exists (select 1 from meetings m where m.id = meeting_id and m.user_id = auth.uid()));

-- ── Storage Bucket ───────────────────────────────────────────
insert into storage.buckets (id, name, public) values ('recordings', 'recordings', false);
create policy "Authenticated users can upload recordings" on storage.objects for insert
  to authenticated with check (bucket_id = 'recordings' and auth.uid()::text = (storage.foldername(name))[2]);
create policy "Users can view own recordings" on storage.objects for select
  to authenticated using (bucket_id = 'recordings' and auth.uid()::text = (storage.foldername(name))[2]);
