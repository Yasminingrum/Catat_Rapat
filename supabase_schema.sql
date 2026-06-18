-- ============================================================
-- CatatRapat — Supabase PostgreSQL Schema (Consolidated)
-- Versi: 2026-06-18
--
-- Aman dijalankan berulang kali di Supabase SQL Editor.
-- Mencakup seluruh tabel, RLS, trigger, storage, dan migrasi.
-- ============================================================

-- ── Extensions ──────────────────────────────────────────────
create extension if not exists "uuid-ossp";


-- ════════════════════════════════════════════════════════════
-- TABEL: profiles
-- ════════════════════════════════════════════════════════════
create table if not exists profiles (
  id          uuid primary key,
  name        text not null default '',
  email       text,
  avatar_url  text,
  plan        text not null default 'free',
  token_used  integer not null default 0,
  deleted_at  timestamptz,
  created_at  timestamptz default now()
);

-- ── Migrasi profiles ────────────────────────────────────────
-- Hapus FK lama ke auth.users agar soft-delete tidak di-cascade
-- saat admin.deleteUser() dipanggil dari Edge Function.
alter table profiles drop constraint if exists profiles_id_fkey;
alter table profiles drop constraint if exists profiles_pkey cascade;
alter table profiles add primary key (id);

alter table profiles drop column if exists token_total;
alter table profiles add column if not exists deleted_at timestamptz;

-- ── Constraint plan ─────────────────────────────────────────
alter table profiles drop constraint if exists profiles_plan_check;
alter table profiles
  add constraint profiles_plan_check
  check (plan in ('free','pro','platinum'));

-- ── Index untuk migrasi profil dihapus (lookup by email) ────
create index if not exists profiles_email_idx on profiles(email);

-- ── RLS & Policies profiles ─────────────────────────────────
alter table profiles enable row level security;

drop policy if exists "Users can view own profile" on profiles;
create policy "Users can view own profile" on profiles
  for select using (auth.uid() = id);

drop policy if exists "Users can update own profile" on profiles;
create policy "Users can update own profile" on profiles
  for update using (auth.uid() = id);

-- Select profil lama berdasarkan email (untuk migrasi plan
-- saat daftar ulang). Hanya baris yang sudah di-soft-delete.
drop policy if exists "Users can view deleted profiles by email" on profiles;
create policy "Users can view deleted profiles by email" on profiles
  for select using (deleted_at is not null);

-- ── Trigger: auto-create profile on signup ──────────────────
create or replace function handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, name, email)
  values (new.id, coalesce(new.raw_user_meta_data->>'name',''), new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();


-- ════════════════════════════════════════════════════════════
-- TABEL: meetings
-- ════════════════════════════════════════════════════════════
create table if not exists meetings (
  id              uuid default uuid_generate_v4() primary key,
  user_id         uuid not null,
  title           text not null,
  agenda          text,
  date            text not null,
  time            text not null,
  duration        text default '0m',
  status          text default 'draft',
  has_transcript  boolean default false,
  has_notula      boolean default false,
  has_audio       boolean default false,
  is_starred      boolean default false,
  audio_path      text,
  created_at      timestamptz default now(),
  updated_at      timestamptz default now()
);

-- ── Migrasi meetings ────────────────────────────────────────
alter table meetings add column if not exists is_starred boolean default false;
alter table meetings add column if not exists audio_path text;

-- Hapus FK lama ke profiles (soft-delete profiles bukan hard-delete)
alter table meetings drop constraint if exists meetings_user_id_fkey;

-- ── Constraint status ───────────────────────────────────────
alter table meetings drop constraint if exists meetings_status_check;
alter table meetings
  add constraint meetings_status_check
  check (status in ('draft','final_'));

-- ── RLS & Policies meetings ─────────────────────────────────
alter table meetings enable row level security;

drop policy if exists "Users can CRUD own meetings" on meetings;
create policy "Users can CRUD own meetings" on meetings
  for all using (auth.uid() = user_id);

create index if not exists meetings_user_id_idx on meetings(user_id);
create index if not exists meetings_created_at_idx on meetings(created_at desc);


-- ════════════════════════════════════════════════════════════
-- TABEL: participants
-- ════════════════════════════════════════════════════════════
create table if not exists participants (
  id          uuid default uuid_generate_v4() primary key,
  meeting_id  uuid references meetings(id) on delete cascade not null,
  speaker_id  text not null,
  label       text not null,
  name        text default '',
  created_at  timestamptz default now()
);

-- ── RLS & Policies participants ─────────────────────────────
alter table participants enable row level security;

drop policy if exists "Users can CRUD own participants" on participants;
create policy "Users can CRUD own participants" on participants
  for all using (
    exists (select 1 from meetings m where m.id = meeting_id and m.user_id = auth.uid())
  );


-- ════════════════════════════════════════════════════════════
-- TABEL: transcript_lines
-- ════════════════════════════════════════════════════════════
create table if not exists transcript_lines (
  id          uuid default uuid_generate_v4() primary key,
  meeting_id  uuid references meetings(id) on delete cascade not null,
  timestamp   text not null,
  speaker_id  text not null,
  speaker     text not null,
  text        text not null,
  seq         integer not null default 0,
  created_at  timestamptz default now()
);

-- ── RLS & Policies transcript_lines ────────────────────────
alter table transcript_lines enable row level security;

drop policy if exists "Users can CRUD own transcripts" on transcript_lines;
create policy "Users can CRUD own transcripts" on transcript_lines
  for all using (
    exists (select 1 from meetings m where m.id = meeting_id and m.user_id = auth.uid())
  );

create index if not exists transcript_meeting_idx on transcript_lines(meeting_id, seq);


-- ════════════════════════════════════════════════════════════
-- TABEL: notulas
-- ════════════════════════════════════════════════════════════
create table if not exists notulas (
  id           uuid default uuid_generate_v4() primary key,
  meeting_id   uuid references meetings(id) on delete cascade not null unique,
  ringkasan    text not null default '',
  keputusan    jsonb not null default '[]',
  action_items jsonb not null default '[]',
  created_at   timestamptz default now(),
  updated_at   timestamptz default now()
);

-- ── RLS & Policies notulas ──────────────────────────────────
alter table notulas enable row level security;

drop policy if exists "Users can CRUD own notulas" on notulas;
create policy "Users can CRUD own notulas" on notulas
  for all using (
    exists (select 1 from meetings m where m.id = meeting_id and m.user_id = auth.uid())
  );


-- ════════════════════════════════════════════════════════════
-- STORAGE: recordings (bucket privat)
-- ════════════════════════════════════════════════════════════
insert into storage.buckets (id, name, public)
  values ('recordings', 'recordings', false)
  on conflict (id) do nothing;

-- Upload (INSERT)
drop policy if exists "Authenticated users can upload recordings" on storage.objects;
create policy "Authenticated users can upload recordings" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'recordings' and auth.uid()::text = (storage.foldername(name))[2]);

-- View (SELECT)
drop policy if exists "Users can view own recordings" on storage.objects;
create policy "Users can view own recordings" on storage.objects
  for select to authenticated
  using (bucket_id = 'recordings' and auth.uid()::text = (storage.foldername(name))[2]);

-- Overwrite / upsert (UPDATE)
drop policy if exists "Users can update own recordings" on storage.objects;
create policy "Users can update own recordings" on storage.objects
  for update to authenticated
  using (bucket_id = 'recordings' and auth.uid()::text = (storage.foldername(name))[2]);

-- Delete (DELETE)
drop policy if exists "Users can delete own recordings" on storage.objects;
create policy "Users can delete own recordings" on storage.objects
  for delete to authenticated
  using (bucket_id = 'recordings' and auth.uid()::text = (storage.foldername(name))[2]);
