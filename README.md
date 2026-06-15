
# CatatRapat

**CatatRapat** adalah aplikasi mobile (Flutter) untuk pencatatan rapat otomatis berbasis AI,
dalam Bahasa Indonesia. Pengguna dapat merekam rapat secara live atau mengunggah file audio,
lalu AI akan mentranskripsi pembicaraan, mendeteksi pembicara, dan menyusun **notula**
(ringkasan, keputusan, serta tindak lanjut beserta PIC & tenggat waktu) yang siap diedit,
diekspor ke PDF, dan dibagikan.


---

## ✨ Fitur Utama

### Onboarding & Autentikasi
- 3 layar onboarding (Rekam Otomatis, AI Susun Notula, Ekspor & Bagikan)
- Daftar & login dengan email/password (Supabase Auth)
- Login dengan akun Google (SSO)

### Dashboard & Manajemen Rapat
- Dashboard berisi statistik (total rapat, rapat berjalan, notula dibuat) & rapat terbaru
- Daftar semua rapat dengan pencarian dan filter status

### Rekam & Pemrosesan AI
- Mulai rapat baru: judul, agenda opsional, pilih mode **Live** atau **Upload**
- Upload file audio (MP3/M4A/WAV/OGG, maks 500 MB)
- Rekam suara live dengan timer, indikator kualitas audio, dan waveform animasi
- Pause / Resume / Done untuk mengontrol sesi rekaman
- Live transcription real-time saat merekam (via OpenAI Realtime API)
- Layar processing dengan progress 4 tahap: Upload → Analisis → Deteksi Speaker → Transkripsi
- Assign Speaker: melabeli setiap suara (Suara 1/2/3) dengan nama peserta rapat

### Notula & Distribusi
- Lihat notula final: ringkasan, daftar keputusan, dan action item (PIC & tenggat)
- Edit notula: ubah ringkasan, tambah/hapus keputusan & tindak lanjut
- Ekspor notula ke PDF (via share sheet OS)
- Bagikan notula (WhatsApp, Email, dll) sebagai teks terformat
- Audio player terintegrasi untuk memutar rekaman rapat

### Profil, Pengaturan & Token
- Lihat sisa token AI bulan ini (1 token = 1 menit audio yang diproses)
- Halaman upgrade plan: perbandingan fitur & harga Free → Pro → Business
- Pengaturan akun dasar: ganti nama, ganti email, dan logout

---

## 🛠️ Tech Stack

| Kategori | Library |
|---|---|
| Framework | Flutter (Dart >= 3.3) |
| State management | flutter_riverpod |
| Navigasi | go_router |
| Backend | Supabase (Auth, Postgres, Storage) |
| AI | OpenAI Whisper (transkripsi) + GPT-4o-mini (notula) + Realtime API (live transcription) |
| Audio | record, just_audio, audio_waveforms |
| PDF & Share | pdf, printing, share_plus |
| Lainnya | dio, file_picker, shared_preferences, flutter_secure_storage |

---

## 📂 Struktur Proyek

```
lib/
├── main.dart                          # Entry point, init Supabase, ProviderScope
├── core/
│   ├── constants/                     # Warna, spacing, text styles
│   ├── models/                        # AppUser, Meeting, Notula, TranscriptLine, dll
│   ├── providers/                     # auth_provider, meeting_provider (Riverpod)
│   ├── router/                        # app_router.dart (go_router + auth guard)
│   ├── services/
│   │   ├── supabase_service.dart      # Wrapper Auth, DB, Storage
│   │   ├── ai_service.dart            # Whisper + GPT (transkripsi & notula)
│   │   ├── realtime_transcription_service.dart  # Live transcription via WebSocket
│   │   └── pdf_service.dart           # Generate & bagikan PDF notula
│   ├── theme/                         # Material3 ThemeData
│   ├── utils/                         # Formatter, validator, snackbar, env config
│   └── widgets/                       # AppButton, AppTextField, BottomNav, dll
└── features/
    ├── onboarding/screens/            # 3 slide onboarding
    ├── auth/                          # Login, Register, Forgot Password, Google SSO
    ├── home/screens/                  # Dashboard & daftar rapat (riwayat)
    ├── meeting/screens/                # Mulai rapat baru (form + mode rekam)
    ├── recording/screens/             # Rekam, processing, assign speaker
    ├── notula/screens/                # Notula, edit, transkrip, audio player
    └── profil/screens/                # Profil, token, upgrade plan, akun
```

Skema database lengkap ada di [`supabase_schema.sql`](./supabase_schema.sql).

---

## 🚀 Memulai

### Prasyarat
- Flutter SDK (Dart >= 3.3)
- Akun [Supabase](https://supabase.com)
- (Opsional, untuk fitur AI) API key [OpenAI](https://platform.openai.com)

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Setup Supabase

1. Buat project baru di [supabase.com](https://supabase.com)
2. Buka **SQL Editor**, jalankan isi `supabase_schema.sql` untuk membuat tabel
   (`profiles`, `meetings`, `participants`, `transcript_lines`, `notulas`) beserta
   RLS policy dan storage bucket privat `recordings`
3. Salin **Project URL** dan **anon/public key** dari **Settings → API**

### 3. Konfigurasi Environment

Salin `.env.example` menjadi `.env` dan isi dengan nilai project Supabase &
OpenAI kamu sendiri (`.env` sudah di-`.gitignore`, jangan pernah di-commit).

`.env` tidak dibaca otomatis oleh Flutter — semua variabel diteruskan via
`--dart-define-from-file`:

```bash
flutter run --dart-define-from-file=.env
```

Atau secara manual per-variabel dengan `--dart-define`:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJxxxxx \
  --dart-define=OPENAI_API_KEY=sk-xxxxx
```

| Variabel | Wajib | Keterangan |
|---|---|---|
| `SUPABASE_URL` | Ya | URL project Supabase |
| `SUPABASE_ANON_KEY` | Ya | Anon/public key Supabase |
| `OPENAI_API_KEY` | Untuk fitur AI | Whisper (transkripsi), GPT-4o-mini (notula), Realtime API (live transcription) |

Tanpa `SUPABASE_URL`/`SUPABASE_ANON_KEY`, inisialisasi Supabase akan gagal saat
start. Tanpa `OPENAI_API_KEY`, fitur transkripsi & penyusunan notula otomatis
akan dilewati (notula dibuat kosong dan bisa diisi manual lewat layar Edit Notula).

### 4. Jalankan aplikasi

```bash
flutter run --dart-define-from-file=.env
```

---

## ✅ Status Pengembangan

| Epic | Cakupan | Status |
|---|---|---|
| Onboarding & Autentikasi (PBI01-04) | Onboarding, register, login, Google SSO | ✅ |
| Dashboard & Manajemen Rapat (PBI05-08) | Dashboard, daftar rapat, mulai rapat, upload audio | ✅ |
| Sesi Rekam & Pemrosesan AI (PBI09-13) | Rekam live, pause/done, live transcription, processing, assign speaker | ✅ |
| Notula & Distribusi (PBI14-18) | View/edit notula, ekspor PDF, share, audio player | ✅ |
| Profil, Pengaturan & Token (PBI19-21) | Sisa token, upgrade plan, pengaturan akun | ✅ |

---

## 🧹 Quality Check

```bash
flutter analyze
```
