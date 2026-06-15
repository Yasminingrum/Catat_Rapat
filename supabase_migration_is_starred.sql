-- Migration: tambah kolom is_starred ke tabel meetings (untuk fitur "Berbintang" di Riwayat Rapat)
-- Jalankan di Supabase SQL Editor jika tabel `meetings` sudah ada sebelumnya.

alter table meetings add column if not exists is_starred boolean default false;
