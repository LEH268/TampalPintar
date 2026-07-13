<div align="center">
    <img src="website\assets\icon\app_icon.png" alt="Logo TampalPintar" width="200" height="200"/>
    <h1>TampalPintar</h1>
    <h3><em>Pelaporan Lubang Jalan untuk Selangor.</em></h3>
</div>

<p align="center">
    <strong>Projek pelaporan lubang jalan untuk Selangor, Malaysia.</strong>
</p>

Projek ini terdiri daripada empat bahagian yang berkongsi satu backend Supabase:

- **`app/`** — Aplikasi Android Flutter untuk rakyat: laporan foto, serta
  laporan suara bebas tangan yang dicetuskan oleh kata bangkit ("wake word")
  khas "Tampal Pintar".
- **`website/`** — Papan pemuka Flutter Web untuk empat peranan pihak
  berkuasa kerajaan (berjalan dalam Chrome).
- **`firmware/tampal_pintar_cam/`** — Lakaran Arduino dashcam ESP32-CAM
  (papan AI-Thinker) yang menstrim foto ke Supabase Storage.
- **`supabase/`** — migrasi pangkalan data (skema, RLS, RPC, storan, pencetus
  webhook) dan Deno Edge Functions (`analyze-report`, `dashcam-cleanup`) yang
  memanggil Gemini untuk pemarkahan risiko AI.

## Susun atur repo

| Laluan | Apa |
|---|---|
| `app/` | Aplikasi Android untuk rakyat |
| `website/` | Papan pemuka Flutter Web kerajaan (Chrome) |
| `firmware/tampal_pintar_cam/` | Lakaran Arduino ESP32-CAM |
| `supabase/` | Migrasi + Edge Functions (diurus melalui CLI, tanpa Docker) |
| `shared/map/map.html` | Halaman peta 3D kanonik (salinan serupa berada dalam kedua-dua aplikasi) |
| `tools/seed/` | Pengisi data demo |
| `tools/backend_tests/` | Suite ujian integrasi backend |
| `tools/wakeword_check/` | Semakan pariti Python untuk saluran kata bangkit |

---

## Isi kandungan

1. [Apa yang anda perlukan](#1-apa-yang-anda-perlukan)
2. [Dapatkan kod](#2-dapatkan-kod)
3. [Cipta projek Supabase anda](#3-cipta-projek-supabase-anda)
4. [Dapatkan kunci API Gemini](#4-dapatkan-kunci-api-gemini)
5. [Dapatkan kunci API Google Maps](#5-dapatkan-kunci-api-google-maps)
6. [Deploy backend — dengan atau tanpa Supabase CLI](#6-deploy-backend--dengan-atau-tanpa-supabase-cli)
7. [Konfigurasikan pangkalan kod dengan kunci anda](#7-konfigurasikan-pangkalan-kod-dengan-kunci-anda)
8. [Isikan data demo](#8-isikan-data-demo)
9. [Sediakan Flutter dan jalankan aplikasi Android](#9-sediakan-flutter-dan-jalankan-aplikasi-android)
10. [Jalankan laman web kerajaan](#10-jalankan-laman-web-kerajaan)
11. [Sediakan Arduino IDE dan flash ESP32-CAM](#11-sediakan-arduino-ide-dan-flash-esp32-cam)
12. [Menjalankan ujian](#12-menjalankan-ujian)
13. [Suis hari demo: FAKE_EXTERNALS](#13-suis-hari-demo-fake_externals)
14. [Senarai semak demo hujung-ke-hujung secara manual](#14-senarai-semak-demo-hujung-ke-hujung-secara-manual)
15. [Penyelesaian masalah](#15-penyelesaian-masalah)

---

## 1. Apa yang anda perlukan

Akaun (peringkat percuma sudah memadai untuk semuanya):

- Akaun **Supabase** — [supabase.com](https://supabase.com)
- **Akaun Google** — digunakan untuk Google AI Studio (Gemini) dan Google
  Cloud Console (Maps)

Perisian untuk dipasang pada komputer anda (pautan dan langkah ada dalam
bahagian berkaitan di bawah, ini sekadar senarai semak):

- [ ] Git
- [ ] [Flutter SDK](https://docs.flutter.dev/get-started/install) (repo ini
      dibina dengan kekangan Dart SDK `^3.9.2`, iaitu keluaran stabil
      Flutter yang terkini)
- [ ] Android Studio (untuk Android SDK/emulator + pemacu USB) — hanya
      diperlukan untuk `app/`
- [ ] Google Chrome — digunakan untuk menjalankan `website/`
- [ ] [Supabase CLI](https://supabase.com/docs/guides/cli/getting-started) —
      pilihan; bahagian 6 juga mendokumenkan laluan Dashboard-sahaja tanpa CLI
- [ ] [Arduino IDE](https://www.arduino.cc/en/software) — hanya diperlukan
      jika anda mempunyai perkakasan fizikal ESP32-CAM
- [ ] Telefon Android dengan penyahpepijatan USB (USB debugging) diaktifkan,
      atau emulator Android — hanya benar-benar diperlukan untuk bahagian
      kata bangkit/mikrofon/GPS; aplikasi juga boleh dibina sebagai APK

---

## 2. Dapatkan kod

```
git clone <url-repo-ini>
cd TampalPintar
```

---

## 3. Cipta projek Supabase anda

1. Pergi ke [supabase.com](https://supabase.com) dan log masuk (atau daftar —
   log masuk GitHub adalah pilihan terpantas).
2. Klik **New project** (di penjuru kanan atas papan pemuka, atau daripada
   senarai projek sesebuah organisasi).
3. Isikan:
   - **Name**: apa-apa sahaja, cth. `tampal-pintar`.
   - **Database Password**: jana yang kukuh dan **simpan di tempat yang
     selamat** — anda memerlukannya sekali dalam langkah 6 dan jarang-jarang
     selepas itu. Ini berbeza daripada mana-mana kunci API.
   - **Region**: pilih yang paling hampir dengan anda (cth. Singapura untuk
     Asia Tenggara).
4. Klik **Create new project** dan tunggu 1–2 minit untuk penyediaan.
5. Setelah projek sedia, kumpulkan empat nilai berikut — anda akan
   menampalnya ke dalam fail kemudian, jadi biarkan halaman ini terbuka atau
   salin nilai-nilai itu ke dalam fail teks sementara buat masa ini:

   | Nilai | Di mana untuk mencarinya |
   |---|---|
   | **Project URL** | Projek → **Settings** (ikon gear, kiri bawah) → **Data API**. Kelihatan seperti `https://abcdefghijklmnop.supabase.co`. |
   | **Project Reference** | Bahagian subdomain Project URL di atas, cth. `abcdefghijklmnop`. Turut dipaparkan di **Settings → General**. |
   | **Kunci anon / public** | **Settings → API Keys**. Berlabel `anon` `public`. Rentetan panjang yang bermula dengan `eyJ...`. Selamat digunakan dalam aplikasi klien (itulah gunanya RLS). |
   | **Kunci service_role** | Halaman yang sama, **API Keys**, berlabel `service_role`. ⚠️ Akses pentadbir penuh, memintas RLS — jangan sesekali letakkannya dalam kod `app/`, `website/`, atau firmware. Hanya digunakan di sisi pelayan (skrip pengisi data, ujian backend). |

6. Anda juga memerlukan **token akses peribadi** untuk Supabase CLI (berbeza
   daripada kunci API projek):
   - Klik avatar anda (kanan atas) → **Account preferences** → **Access
     Tokens** → **Generate new token**.
   - Namakannya apa-apa sahaja (cth. `tampal-pintar-cli`), salin nilai yang
     dipaparkan (`sbp_...`) — ia hanya dipaparkan sekali sahaja.

Simpan kelima-lima nilai itu (Project URL, project ref, kunci anon, kunci
service_role, token akses peribadi) berserta kata laluan pangkalan data —
panduan seterusnya akan merujuk semula kepadanya sebagai **"project ref
anda"**, **"kunci anon anda"**, dan sebagainya.

---

## 4. Dapatkan kunci API Gemini

Edge Function `analyze-report` memanggil Gemini sekali bagi setiap laporan
(pemarkahan risiko daripada foto + cuaca + konteks jalan).

1. Pergi ke [Google AI Studio](https://aistudio.google.com/apikey).
2. Log masuk dengan akaun Google anda.
3. Klik **Create API key** (pilih "Create API key in new project" jika anda
   belum mempunyai projek Google Cloud yang dipilih).
4. Salin kunci itu (bermula dengan `AIza...`).

Kunci ini hanya ditetapkan sebagai **rahsia Supabase Edge Function**
(langkah 6) — ia tidak pernah muncul dalam kod `app/`, `website/`, atau
firmware, dan tidak sepatutnya dikomit ke mana-mana.

---

## 5. Dapatkan kunci API Google Maps

Halaman peta 3D (`shared/map/map.html`) menggunakan **Maps JavaScript API**
(saluran alpha, untuk perpustakaan `maps3d` 3D fotorealistik). Pilih satu
daripada dua pilihan di bawah — kedua-duanya menghasilkan kunci `AIza...`
yang sama jenis, dan ia diletakkan di tempat yang sama
([langkah 7.4](#74-halaman-peta-3d--baris-77-dalam-3-salinan-serupa)).

### Pilihan A — Kunci demo percuma (terpantas, tiada pengebilan/kad kredit diperlukan)

Google Maps Platform menerbitkan **kunci demo** tanpa kos yang memang
bertujuan untuk pemprototaipan/penilaian seperti projek ini:

1. Pergi ke [mapsplatform.google.com/maps-demo-key](https://mapsplatform.google.com/maps-demo-key/).
2. Klik **Try for free**. Ini membuka konsol Google Cloud dan menyediakan
   kunci demo untuk anda — hanya memerlukan akaun Google, tiada kad kredit
   dan tiada penyediaan pengebilan.
3. Salin kunci yang dipaparkan (bermula dengan `AIza...`).

Nota penting: kunci demo merangkumi satu himpunan API tetap yang termasuk
**3D Maps** (tepat seperti yang digunakan oleh halaman peta projek ini),
serta Dynamic Maps, Geocoding, Places, Routes, dan Weather. Ia mempunyai
**had penggunaan harian bagi setiap API** — apabila anda melebihinya untuk
hari itu, peta hanya berhenti memberi respons sehingga hari berikutnya;
anda tidak dikenakan bayaran. Ia secara jelas berskop untuk **pembangunan
dan pengujian, bukan produksi**.

### Pilihan B — Kunci anda sendiri melalui Google Cloud Console (disyorkan jika anda mahu kuota sendiri, tiada had harian, atau memerlukannya untuk jangka panjang)

1. Pergi ke [Google Cloud Console](https://console.cloud.google.com/).
2. Cipta projek baharu (atau guna semula projek yang dicipta AI Studio dalam
   langkah 4) — menu lungsur projek di kiri atas → **New Project**.
3. Aktifkan API: pergi ke **APIs & Services → Library**, cari **"Maps
   JavaScript API"**, klik padanya, klik **Enable**.
4. Cipta kunci: **APIs & Services → Credentials → + Create Credentials →
   API key**. Salin kunci itu (bermula dengan `AIza...`).
5. (Disyorkan, tidak wajib untuk pengujian setempat) Klik **Restrict key**
   dan hadkannya kepada **Maps JavaScript API**, dan jika mahu, kepada nama
   pakej aplikasi / perujuk laman web anda setelah anda mengetahuinya. Kunci
   tanpa sekatan berfungsi baik untuk pembangunan setempat tetapi tidak
   sepatutnya dibiarkan begitu dalam konfigurasi langsung repo awam — repo
   ini hanya membekalkan nilai penempat (placeholder), jadi kunci setiap
   orang adalah hak masing-masing untuk disekat.
6. Pastikan pengebilan diaktifkan pada projek Cloud itu. Maps JavaScript API
   memerlukan akaun pengebilan aktif, tetapi kredit percuma bulanan Google
   lebih daripada mencukupi untuk penggunaan demo/pembangunan. (Langkau
   keseluruhan pilihan ini dan gunakan Pilihan A di atas jika anda tidak
   mahu menyediakan pengebilan langsung.)

---

## 6. Deploy backend — dengan atau tanpa Supabase CLI

Dua cara untuk memasang skema, RLS, RPC, polisi storan, pencetus webhook,
dan kedua-dua Edge Functions ke projek anda. **Pilihan A lebih pantas** dan
itulah yang diandaikan oleh seluruh README ini apabila ia menyebut arahan
CLI secara sepintas lalu; **Pilihan B tidak memerlukan apa-apa pemasangan**
— hanya pelayar anda dan Supabase Dashboard. Pilih satu; anda tidak
memerlukan kedua-duanya.

### Pilihan A — Menggunakan Supabase CLI (disyorkan, lebih pantas)

Pasang CLI (pilih satu):

```
scoop install supabase        # Windows, melalui Scoop
npm i -g supabase             # mana-mana OS dengan Node.js
winget install Supabase.CLI   # Windows, melalui winget
brew install supabase/tap/supabase   # macOS/Linux, melalui Homebrew
```

Docker tidak diperlukan — setiap arahan di bawah berkomunikasi terus dengan
projek terhos anda (`--use-api` / mod terpaut).

Dari akar repo:

```
$env:SUPABASE_ACCESS_TOKEN = "<token akses peribadi anda dari langkah 3, sbp_...>"
$env:SUPABASE_DB_PASSWORD  = "<kata laluan pangkalan data anda dari langkah 3>"
supabase link --project-ref <project ref anda>
```

(Pada macOS/Linux gunakan `export SUPABASE_ACCESS_TOKEN=...` dan seumpamanya
sebagai ganti sintaks PowerShell `$env:`.)

**Sebelum menolak migrasi**, lakukan satu suntingan manual wajib yang
diterangkan dalam bahagian seterusnya (langkah 7.3) — satu fail migrasi
memerlukan URL dan kunci anon projek anda sendiri dibenamkan ke dalamnya.
Lakukannya sekarang, kemudian kembali ke sini dan jalankan:

```
supabase db push --include-all
```

`--include-all` adalah wajib — `supabase db push` biasa akan melangkau
sesetengah migrasi dalam projek ini secara senyap.

Deploy Edge Functions:

```
supabase functions deploy analyze-report dashcam-cleanup --use-api
```

Tetapkan rahsia Edge Function:

```
supabase secrets set GEMINI_API_KEY=<kunci Gemini anda dari langkah 4>
supabase secrets set GOOGLE_MAPS_KEY=<kunci Google Maps anda dari langkah 5>
supabase secrets set FAKE_EXTERNALS=1
```

`FAKE_EXTERNALS=1` menjadikan suite ujian backend berkelakuan tentu
(deterministik) — ia memalsukan Gemini/Weather/Geocoding dan bukannya
memanggil perkhidmatan sebenar. Biarkan ia ditetapkan buat masa ini —
[bahagian 13](#13-suis-hari-demo-fake_externals) menerangkan bila untuk
menyahtetapkannya.

Jika anda menggunakan Pilihan A, langkau terus ke
[bahagian 7](#7-konfigurasikan-pangkalan-kod-dengan-kunci-anda).

### Pilihan B — Tanpa Supabase CLI (Dashboard sahaja)

Semua yang dilakukan CLI di atas boleh dilakukan secara manual dalam
Supabase Dashboard. Ia lebih banyak salin-tampal, tetapi tiada apa-apa yang
perlu dipasang dan tiada langkah token akses/pemautan.

**B.1 — Jalankan migrasi pangkalan data melalui SQL Editor**

`supabase/migrations/` mengandungi 10 fail `.sql` biasa yang mesti
dijalankan **dalam susunan tepat ini** (setiap satu dibina di atas yang
sebelumnya — jadual sebelum polisi RLS sebelum RPC, dan seterusnya):

```
20260709000001_schema.sql
20260709000002_policies.sql
20260709000003_submit_report.sql
20260709000004_mark_fixed.sql
20260709000005_redeem.sql
20260709000006_leaderboards.sql
20260709000007_storage.sql
20260709000008_analyze_webhook.sql   <- sunting fail ini dahulu, lihat langkah 7.3 di bawah
20260709000009_redeem_code_hardening.sql
20260709000010_column_grants.sql
```

Bagi setiap fail, mengikut susunan:

1. Buka fail itu secara setempat dalam penyunting teks dan salin
   keseluruhan kandungannya. **Khusus untuk
   `20260709000008_analyze_webhook.sql`**, lakukan dahulu suntingan yang
   diterangkan dalam langkah 7.3 di bawah (bahagian 7) — gantikan nilai
   penempat URL dan token Bearer dengan project ref dan kunci anon sebenar
   anda — *kemudian* barulah salin kandungan yang telah disunting.
2. Dalam Supabase Dashboard, buka projek anda → **SQL Editor** (bar sisi
   kiri) → **New query**.
3. Tampal kandungan fail ke dalam penyunting dan klik **Run** (atau
   Ctrl+Enter / Cmd+Enter).
4. Pastikan anda melihat mesej berjaya tanpa sebarang sepanduk ralat merah
   sebelum beralih ke fail seterusnya. Ulang untuk kesemua 10 fail, mengikut
   susunan dengan ketat.

Jika `20260709000008_analyze_webhook.sql` menghasilkan ralat pada
`create extension if not exists pg_net;` dengan mesej kebenaran, pergi ke
**Database → Extensions** (bar sisi kiri), cari **pg_net**, aktifkannya,
kemudian jalankan semula fail itu.

**B.2 — Deploy Edge Functions melalui penyunting terbina dalam Dashboard**

Kedua-dua fungsi dalam repo ini hanyalah satu fail setiap satu, jadi
penyunting pelayar sudah memadai — tiada muat naik zip atau penggabungan
berbilang fail diperlukan:

1. Pergi ke **Edge Functions** (bar sisi kiri) → **Deploy a new function** →
   **Via editor**.
2. Namakannya tepat sebagai `analyze-report`.
3. Pilih semua kod templat penempat dalam penyunting dan gantikannya dengan
   kandungan penuh `supabase/functions/analyze-report/index.ts` daripada
   repo ini.
4. Klik **Deploy**.
5. Ulang langkah 1–4 untuk fungsi kedua yang dinamakan tepat sebagai
   `dashcam-cleanup`, dengan menampal kandungan
   `supabase/functions/dashcam-cleanup/index.ts`.

**B.3 — Tetapkan rahsia Edge Function melalui Dashboard**

1. Masih di bawah **Edge Functions**, buka tab **Secrets** (sesetengah versi
   Dashboard melabelkannya **Manage secrets**).
2. Tambah tiga rahsia:

   | Nama | Nilai |
   |---|---|
   | `GEMINI_API_KEY` | kunci Gemini anda dari langkah 4 |
   | `GOOGLE_MAPS_KEY` | kunci Google Maps anda dari langkah 5 |
   | `FAKE_EXTERNALS` | `1` |

3. Simpan. Kemudian, setiap kali README ini menyuruh anda menjalankan
   `supabase secrets set FAKE_EXTERNALS=1` atau
   `supabase secrets unset FAKE_EXTERNALS` ([bahagian 13](#13-suis-hari-demo-fake_externals)),
   lakukan yang setara di sini: sunting atau padamkan baris `FAKE_EXTERNALS`
   dalam tab Secrets yang sama ini.

Semua dari [bahagian 7](#7-konfigurasikan-pangkalan-kod-dengan-kunci-anda)
dan seterusnya (pengisian data, menjalankan aplikasi/laman web, ujian)
berfungsi sama sahaja tidak kira pilihan mana yang anda gunakan di sini —
tiada satu pun daripadanya berkomunikasi dengan CLI, hanya dengan URL awam
dan kunci projek anda.

---

## 7. Konfigurasikan pangkalan kod dengan kunci anda

Enam fail terjejak dalam repo ini dibekalkan dengan nilai **penempat**
(placeholder). Gantikan setiap penempat di bawah dengan nilai sebenar yang
anda kumpulkan dalam langkah 3 (dan langkah 5 untuk kunci Maps). Tiada satu
pun fail ini diabaikan git (git-ignored), jadi jangan komit rahsia sebenar
ke dalamnya jika repo ini bersifat awam — itulah tepatnya yang README ini
bantu anda elakkan dengan menyimpan rahsia *sebenar* hanya dalam fail
setempat anda yang diabaikan git `API Key Configuration.md` / pemboleh ubah
persekitaran / rahsia CLI.

### 7.1 `app/lib/config.dart` — baris 2–3

```dart
const kSupabaseUrl = 'https://YOUR_PROJECT_REF.supabase.co';    // baris 2
const kSupabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';               // baris 3
```

Gantikan `YOUR_PROJECT_REF` dengan project ref anda dan
`YOUR_SUPABASE_ANON_KEY` dengan kunci anon anda (kedua-duanya dari
langkah 3).

### 7.2 `website/lib/config.dart` — baris 2–3

Dua pemalar yang sama, nilai yang sama, nombor baris yang sama:

```dart
const kSupabaseUrl = 'https://YOUR_PROJECT_REF.supabase.co';    // baris 2
const kSupabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';               // baris 3
```

### 7.3 `supabase/migrations/20260709000008_analyze_webhook.sql` — baris 11 dan 14, lakukan ini **sebelum** `supabase db push`

Migrasi ini memasang pencetus Postgres yang memanggil Edge Function
`analyze-report` melalui `pg_net` setiap kali laporan dimasukkan. Postgres
tidak boleh membaca rahsia Edge Function Supabase, jadi kunci anon terpaksa
dibenamkan terus ke dalam fail SQL ini:

```sql
perform net.http_post(
  url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/analyze-report',   -- baris 11
  headers := jsonb_build_object(
    'Content-Type', 'application/json',
    'Authorization', 'Bearer YOUR_SUPABASE_ANON_KEY'                           -- baris 14
  ),
  ...
```

Gantikan kedua-dua penempat (URL di baris 11, token Bearer di baris 14)
dengan project ref dan kunci anon anda, simpan fail itu, **kemudian**
jalankan `supabase db push --include-all` (langkah 6). Jika anda menolak
migrasi sebelum menyunting fail ini, pencetus itu akan gagal secara senyap
(ia akan membuat POST ke hos yang tidak wujud) — jalankan semula
`supabase db push --include-all` selepas membetulkannya; migrasi di sini
bersifat idempoten.

### 7.4 Halaman peta 3D — baris 77 dalam 3 salinan serupa

Halaman peta sengaja diduplikasi (lihat
[nota seni bina](#nota-seni-bina-tiada-perkongsian) di bawah): sunting fail
**kanonik**, kemudian salin ke atas kedua-dua fail lain supaya ketiga-tiganya
kekal serupa bait demi bait.

1. Sunting `shared/map/map.html`, **baris 77**:
   ```js
   key: "YOUR_GOOGLE_MAPS_API_KEY",
   ```
   dan gantikan dengan kunci Google Maps anda dari langkah 5. (Baris yang
   sama, 77, juga memegang penempat dalam dua salinan di bawah — sebaik
   sahaja anda menyalin fail ini ke atasnya, semuanya akan sejajar secara
   automatik.)
2. Salin fail itu ke atas kedua-dua lokasi lain:
   ```
   copy shared\map\map.html app\assets\map\map.html
   copy shared\map\map.html website\web\map.html
   ```
   (macOS/Linux: `cp shared/map/map.html app/assets/map/map.html && cp shared/map/map.html website/web/map.html`)

### 7.5 Blok konfigurasi firmware — baris 18–19, hanya jika anda mempunyai perkakasan ESP32-CAM

Diliputi sepenuhnya dalam
[bahagian 11](#11-sediakan-arduino-ide-dan-flash-esp32-cam); dua nilai
Supabase yang sama dimasukkan ke dalam
`firmware/tampal_pintar_cam/tampal_pintar_cam.ino`, baris 18–19:

```cpp
const char* SUPABASE_URL = "https://YOUR_PROJECT_REF.supabase.co";  // baris 18
const char* SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_KEY";           // baris 19
```

---

## 8. Isikan data demo

Idempoten — selamat dijalankan semula pada bila-bila masa.

```
cd tools\seed
dart pub get
$env:SEED_URL = "https://YOUR_PROJECT_REF.supabase.co"
$env:SEED_SERVICE_ROLE_KEY = "<kunci service_role anda dari langkah 3>"
dart run bin/seed.dart
cd ..\..
```

Ini mencipta akaun demo (kata laluan untuk semua: `TampalPintar#2026`):

| Akaun | Peranan |
|---|---|
| `aisyah@tampalpintar.demo` | Rakyat (dashcam `DEMO-CAM-01`, kenderaan Kereta) |
| `weiming@ / kumar@ / siti@tampalpintar.demo` | Rakyat |
| `jkr.malaysia@tampalpintar.demo` | JKR Malaysia (Laluan Persekutuan) |
| `jkr.selangor@tampalpintar.demo` | JKR Selangor (Laluan Negeri) |
| `local.council@tampalpintar.demo` | Majlis Tempatan (Perbandaran/Tempatan) |
| `highway@tampalpintar.demo` | Konsesi Lebuh Raya (Lebuh Raya Ekspres) |

Ini ialah kelayakan demo tetap yang dibenamkan dalam skrip pengisi data itu
sendiri (`tools/seed/bin/seed.dart`) — ia hanya wujud dalam projek Supabase
**anda sendiri** setelah anda menjalankan pengisi data, jadi tiada akaun
kongsi/awam di sini.

---

## 9. Sediakan Flutter dan jalankan aplikasi Android

### 9.1 Pasang Flutter

1. Ikut panduan pemasangan rasmi untuk OS anda:
   [docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install).
   Pada Windows ini biasanya: muat turun zip Flutter SDK, ekstrak (cth. ke
   `C:\src\flutter`), tambah `C:\src\flutter\bin` ke `PATH` anda.
2. Pasang **Android Studio** ([developer.android.com/studio](https://developer.android.com/studio))
   — diperlukan untuk Android SDK, alatan platform (`adb`), dan emulator
   jika anda tidak mempunyai telefon fizikal.
3. Sahkan semuanya:
   ```
   flutter doctor
   ```
   Selesaikan sebarang item ✗ yang dilaporkannya (terima lesen Android
   dengan `flutter doctor --android-licenses`, pasang komponen SDK yang
   hilang daripada SDK Manager Android Studio, dll.) sehingga item rantaian
   alat Android menjadi ✓.

### 9.2 Dapatkan peranti

**Pilihan A — telefon Android fizikal (wajib untuk ciri kata
bangkit/mikrofon dan GPS langsung benar-benar berfungsi):**

1. Pada telefon: **Settings → About phone** → ketik **Build number**
   7 kali untuk mengaktifkan Developer Options.
2. **Settings → Developer options** → aktifkan **USB debugging**.
3. Sambungkan telefon ke komputer anda melalui USB, terima gesaan "Allow
   USB debugging?" pada telefon.
4. Sahkan ia dikesan: `flutter devices` sepatutnya menyenaraikannya.

**Pilihan B — emulator Android (memadai untuk pengujian UI/peta/laporan
foto; kata bangkit mikrofon tidak akan mempunyai sumber audio sebenar):**

1. Dalam Android Studio: **Tools → Device Manager → Create device**, pilih
   mana-mana profil telefon moden, imej sistem dengan **API 26+** (`minSdk`
   aplikasi ini ialah 26), muat turun imej jika diminta, selesai.
2. Mulakan emulator daripada Device Manager, atau
   `flutter emulators --launch <id>`.

### 9.3 Jalankan aplikasi

```
cd app
flutter pub get
flutter run
```

Jika berbilang peranti/emulator disambungkan, `flutter run` akan meminta
anda memilih satu, atau berikan `-d <id-peranti>` secara terus
(`flutter devices` menyenaraikan ID).

### 9.4 Atau bina APK yang boleh dipasang

```
cd app
flutter pub get
flutter build apk --release
```

APK ditulis ke `app\build\app\outputs\flutter-apk\app-release.apk`.
Salinkannya ke telefon dan pasang terus (anda perlu membenarkan "pasang
daripada sumber tidak diketahui" untuk aplikasi yang anda gunakan untuk
memindahkannya).

### 9.5 Jalankan ujian aplikasi

```
cd app
flutter test --concurrency=1        # --concurrency=1 adalah wajib
flutter analyze
```

---

## 10. Jalankan laman web kerajaan

```
cd website
flutter pub get
flutter run -d chrome
flutter analyze
```

Tiada ujian laman web automatik — pengesahan projek ini adalah manual
(lihat [senarai semak demo](#14-senarai-semak-demo-hujung-ke-hujung-secara-manual)
di bawah).

---

## 11. Sediakan Arduino IDE dan flash ESP32-CAM

Hanya diperlukan jika anda mempunyai papan fizikal **AI-Thinker ESP32-CAM**
(dan, kebiasaannya, penyesuai FTDI/USB-serial berasingan untuk
memprogramnya — kebanyakan papan ESP32-CAM tiada port USB terbina).

### 11.1 Pasang Arduino IDE

1. Muat turun dan pasang Arduino IDE (2.x) daripada
   [arduino.cc/en/software](https://www.arduino.cc/en/software).

### 11.2 Tambah sokongan papan ESP32

1. Buka Arduino IDE → **File → Preferences**.
2. Dalam **Additional boards manager URLs**, tambah:
   ```
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
3. **Tools → Board → Boards Manager**, cari **"esp32"**, pasang pakej yang
   diterbitkan oleh **Espressif Systems**.

Satu pakej ini membekalkan semua yang diperlukan lakaran — `WiFi.h`,
`WiFiClientSecure.h`, `HTTPClient.h`, `esp_camera.h`, dan `time.h`
semuanya sebahagian daripada teras ESP32/pemacu kamera. Tiada pemasangan
Library Manager berasingan diperlukan untuk projek ini.

### 11.3 Konfigurasikan lakaran

Buka `firmware/tampal_pintar_cam/tampal_pintar_cam.ino` dalam Arduino IDE
dan sunting blok `CONFIG (edit these)` berhampiran bahagian atas:

```cpp
const char* WIFI_SSID   = "TampalPintar";        // nama hotspot telefon anda
const char* WIFI_PASS   = "potholes123";         // kata laluan hotspot telefon anda
const char* DASHCAM_ID  = "DEMO-CAM-01";         // mesti sepadan dengan dashcam_id profil
const char* SUPABASE_URL = "https://YOUR_PROJECT_REF.supabase.co";
const char* SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_KEY";
```

- `WIFI_SSID` / `WIFI_PASS`: tetapkan supaya sepadan dengan hotspot mudah
  alih yang akan anda hidupkan daripada telefon yang menjalankan aplikasi
  rakyat — ESP32-CAM menyertai hotspot itu, ia tidak memerlukan Wi-Fi rumah
  anda.
- `DASHCAM_ID`: mesti sepadan dengan `dashcam_id` pada profil rakyat (skrip
  pengisi data menetapkan milik `aisyah@tampalpintar.demo` kepada
  `DEMO-CAM-01`, sepadan dengan nilai lalai di sini — ubah kedua-duanya
  serentak jika anda menggunakan profil lain).
- `SUPABASE_URL` / `SUPABASE_ANON_KEY`: project ref dan kunci anon anda dari
  langkah 3, nilai yang sama seperti di tempat lain dalam bahagian ini.

### 11.4 Bekalan kuasa dan pengaturcara — pilih satu

AI-Thinker ESP32-CAM tiada port USB terbina dan tiada pengatur voltan
terbina yang cukup baik untuk menjalankan kamera dengan stabil daripada
sesetengah sumber 5V, jadi ia memerlukan papan berasingan untuk membekalkan
kuasa dan mendedahkan sambungan USB-serial untuk flash. Dua pilihan:

**Pilihan A — ESP32-CAM Mother Board / papan pengaturcara (disyorkan)**

Papan pecahan kecil (biasa dijual sebagai "ESP32-CAM-MB" atau "ESP32-CAM
Programmer") yang ESP32-CAM boleh dipasang terus padanya. Ia membekalkan
kuasa melalui USB dan menguruskan pendawaian UART + auto-reset untuk anda —
tiada wayar pelompat, tiada bekalan kuasa berasingan, tiada perlu menogol
IO0 secara manual.

1. Pasang ESP32-CAM pada kepala pin mother board itu (orientasi penting —
   padankan penanda cetakan sutera pada papan khusus anda; kamera biasanya
   menghadap menjauhi penyambung USB).
2. Sambungkan mother board ke komputer anda dengan kabel Micro-USB. Ini
   membekalkan kuasa kepada papan sekaligus mendedahkannya sebagai port
   bersiri.
3. Windows memerlukan pemacu USB-ke-serial untuk cip yang digunakan mother
   board anda (biasanya CH340 atau CP2102) — Windows Update kebiasaannya
   memasangnya secara automatik kali pertama anda menyambungkannya; jika
   papan tidak muncul di bawah **Tools → Port**, cari "pemacu <CH340 atau
   CP2102>" untuk OS anda.
4. Kebanyakan mother board auto-reset ke mod pemuat but (bootloader) apabila
   anda klik **Upload** (tiada tekanan butang diperlukan). Jika muat naik
   tamat masa pada "Connecting...", periksa penanda papan khusus anda untuk
   butang **RESET** atau **BOOT** dan tahan seketika apabila IDE mula memuat
   naik.
5. Tiada penyesuai kuasa berasingan diperlukan — port USB membekalkannya,
   untuk flash mahupun operasi biasa selagi ia kekal dipalamkan ke sumber
   kuasa USB (pengecas telefon + kabel berfungsi baik setelah anda selesai
   flash dan hanya mahu ia berjalan sebagai dashcam).

**Pilihan B — kuasa luaran + penyesuai FTDI/USB-TTL**

Jika anda tiada mother board, dawaikan penyesuai FTDI/USB-TTL biasa terus
ke pin ESP32-CAM (papan bertoleransi logik 5V, atau gunakan penyesuai 3.3V):

| ESP32-CAM | Penyesuai |
|---|---|
| 5V | 5V (atau pin 3.3V jika menggunakan penyesuai 3.3V ke rel 3.3V papan — semak dokumentasi papan khusus anda) |
| GND | GND |
| U0R (RX) | TX |
| U0T (TX) | RX |
| IO0 | GND (**hanya semasa flash** — ini meletakkan cip ke dalam mod pemuat but) |

Untuk flash: sambungkan IO0 ke GND, tekan butang **RESET** papan (atau
kitar kuasanya), kemudian muat naik daripada IDE. Selepas muat naik
berjaya, putuskan IO0 daripada GND dan reset sekali lagi untuk menjalankan
lakaran seperti biasa. Untuk menjalankannya selepas itu (bukan sekadar
flash) anda juga memerlukan sumber kuasa 5V stabil berasingan ke pin
5V/GND yang sama, kerana penyesuai sahaja kebiasaannya tidak mampu
membekalkan arus yang mencukupi untuk kamera dalam jangka panjang.

### 11.5 Pilih papan dan port, kemudian kompil/muat naik

1. **Tools → Board → esp32 → AI Thinker ESP32-CAM**.
2. **Tools → Port** → pilih port COM yang dipaparkan oleh mother board atau
   penyesuai anda.
3. **Tools → Partition Scheme** → pilih satu dengan ruang aplikasi yang
   mencukupi, cth. *"Huge APP (3MB No OTA/1MB SPIFFS)"* — skema lalai
   kadangkala terlalu kecil untuk kamera + tindanan TLS.
4. Klik **Upload** (atau **Verify** dahulu untuk sekadar menyemak
   kompilasi).

Atau, tanpa antara muka, menggunakan CLI:

```
arduino-cli core install esp32:esp32
arduino-cli compile --fqbn esp32:esp32:esp32cam firmware/tampal_pintar_cam
arduino-cli upload -p <PORT_COM> --fqbn esp32:esp32:esp32cam firmware/tampal_pintar_cam
```

### 11.6 But pertama

Buka **Serial Monitor** IDE (baud 115200) selepas but/reset biasa (bukan
semasa ditahan dalam mod pemuat but — jika anda menggunakan helah
IO0-ke-GND Pilihan B, putuskannya dahulu). Anda sepatutnya melihatnya
menyertai hotspot, menyegerakkan masa NTP, membersihkan sebarang foto
tertinggal daripada larian sebelumnya, kemudian mula menstrim
`Streaming photos to Supabase Storage...`. Dalam aplikasi rakyat, memulakan
pemanduan sepatutnya memaparkan *"Dashcam disambungkan"* sebaik sahaja
ESP32 sedang memuat naik.

---

## 12. Menjalankan ujian

### 12.1 Ujian integrasi backend ("Seam 1")

Ujian ini berjalan terhadap **projek Supabase terhos langsung anda** dengan
data demo yang telah diisi — ia adalah ujian integrasi, bukan ujian unit
terpencil/olokan.

1. Cipta `tools/backend_tests/test_config.json` (diabaikan git — anda cipta
   fail ini sendiri, ia tidak dibekalkan bersama repo):
   ```json
   {
     "url":            "https://YOUR_PROJECT_REF.supabase.co",
     "anonKey":        "YOUR_SUPABASE_ANON_KEY",
     "serviceRoleKey": "YOUR_SUPABASE_SERVICE_ROLE_KEY",
     "functionsUrl":   "https://YOUR_PROJECT_REF.supabase.co/functions/v1"
   }
   ```
2. Pastikan rahsia `FAKE_EXTERNALS` ditetapkan (lihat langkah 6):
   ```
   supabase secrets set FAKE_EXTERNALS=1
   ```
3. Jalankan:
   ```
   cd tools\backend_tests
   dart pub get
   dart test                                  # keseluruhan suite
   dart test test/submit_report_test.dart     # satu fail
   ```

### 12.2 Ujian logik aplikasi ("Seam 2")

```
cd app
flutter test --concurrency=1
```

### 12.3 Semakan pariti matematik kata bangkit

Mengesahkan pelaksanaan semula Dart bagi saluran ONNX kata bangkit
bersetuju dengan rantaian Python rujukan.

```
pip install onnxruntime numpy
cd tools\wakeword_check
python check.py            # audio sintetik
python check.py drive.wav  # atau rakaman sebenar frasa itu, 16 kHz mono 16-bit
```

---

## 13. Suis hari demo: `FAKE_EXTERNALS`

Suite ujian backend (12.1) memerlukan external **palsu** — pengganti
deterministik untuk Gemini/Weather/Geocoding, supaya ujian tidak rapuh atau
terkena had kadar. Demo langsung sebenar (atau sekadar untuk melihat skor
risiko Gemini sebenar) memerlukan integrasi **sebenar**. Hanya satu boleh
benar pada satu-satu masa:

```
supabase secrets unset FAKE_EXTERNALS     # sebelum demo langsung
supabase secrets set FAKE_EXTERNALS=1     # sebelum menjalankan suite ujian semula
```

Membiarkannya dalam keadaan yang salah akan merosakkan kes penggunaan yang
tidak sedang anda lakukan, jadi togolkannya dengan sengaja setiap kali anda
bertukar konteks.

---

## 14. Senarai semak demo hujung-ke-hujung secara manual

Setelah backend dideploy, data diisi, `FAKE_EXTERNALS` dinyahtetapkan, dan
kedua-dua aplikasi serta laman web dikonfigurasi dengan kunci anda:

1. Peta 3D Selangor dipaparkan dengan pin merah yang telah diisi (aplikasi +
   laman web); mengetik pin membuka butiran dengan Skor Risiko, jenis jalan
   · pihak berkuasa, dan tempoh "Terbuka selama" yang berdetik secara
   langsung.
2. Laporan foto pejalan kaki dihantar serta-merta; laporan kedua dalam
   lingkungan 10 m daripadanya ditolak dengan mesej laporan pendua yang
   jelas.
3. Pada aplikasi: **Mula Memandu** → letakkan aplikasi di latar
   belakang/tutup → sebut **"Tampal Pintar"** (ambang pengesanan 0.28,
   recall ≈ 57%, jadi ulang frasa itu jika terlepas pada kali pertama) →
   pemberitahuan **"Lubang Jalan Direkodkan!"** muncul.
4. Dengan ESP32-CAM dihidupkan dan menyertai hotspot telefon: aplikasi
   memaparkan *Dashcam disambungkan*; kata bangkit mengekalkan 7 foto (foto
   "serta-merta" dibingkai merah dalam pratonton draf); mengitar kuasa
   ESP32 hanya memadamkan sisa `live/`-nya sendiri, tidak sesekali foto
   laporan yang telah disimpan.
5. Dalam **Menunggu**: jalur pratonton, tiga soalan susulan satu-ketikan
   yang boleh dilangkau (Kenderaan diprapilih daripada *Kenderaan Saya*),
   kemudian **Hantar** → pin muncul pada peta dan mendapat skor AI (kesemua
   7 foto dihantar ke Gemini; skor ≥ 80 menugaskannya secara automatik
   kepada pihak berkuasa).
6. Pada laman web, setiap peranan kerajaan hanya melihat pinnya sendiri;
   tayangan slaid pin terasa seperti rakaman dashcam; **Tugaskan** (sehala —
   dialog menamakan pihak berkuasa) → **Selesaikan** menukarkannya hijau →
   pengesahan membuatkan pin lenyap di mana-mana; mata pelapor melonjak
   sebanyak Skor Risiko; kedua-dua papan pendahulu dikemas kini.
7. **Ganjaran**: tebus baucar (disahkan pelayan), kod mendarat dalam
   *Baucar Saya*; kedudukan Pelapor Terbaik tidak terjejas oleh perbelanjaan
   mata.

---

## 15. Penyelesaian masalah

- **`supabase db push` seakan-akan melangkau migrasi** — anda hampir pasti
  terlupa `--include-all`. Jalankan semula dengannya.
- **Laporan tidak pernah mendapat skor risiko / tersekat pada
  `risk_score IS NULL`** — kemungkinan besar anda menolak migrasi sebelum
  menyunting `supabase/migrations/20260709000008_analyze_webhook.sql`
  (langkah 7.3). Suntingnya dengan project ref + kunci anon sebenar anda dan
  jalankan `supabase db push --include-all` sekali lagi.
- **Peta dipaparkan kosong / ralat JS dalam konsol pelayar** — kunci Google
  Maps yang tidak sah atau tanpa-sekatan-tetapi-tanpa-pengebilan gagal
  **secara senyap** dalam pemuat `maps3d` alpha halaman ini. Semak semula:
  kunci ditampal dengan betul dalam ketiga-tiga salinan `map.html` (7.4),
  Maps JavaScript API diaktifkan pada projek Cloud itu, dan pengebilan
  diaktifkan pada projek Cloud itu.
- **Ujian backend gagal dengan ralat auth/rangkaian** — semak nilai
  `tools/backend_tests/test_config.json` terhadap kunci API semasa projek
  anda (Settings → API Keys boleh berputar), dan sahkan `FAKE_EXTERNALS=1`
  ditetapkan sebagai rahsia.
- **`flutter doctor` merungut tentang lesen Android** — jalankan
  `flutter doctor --android-licenses` dan terimanya.
- **ESP32-CAM tidak mahu flash** — jika menggunakan Pilihan B (penyesuai
  FTDI), sahkan IO0 diikat ke GND *hanya* semasa muat naik; jika menggunakan
  Pilihan A (mother board), cuba tahan butang RESET/BOOT-nya semasa IDE
  memaparkan "Connecting...". Apa pun, sahkan anda memilih port COM yang
  betul dan varian papan *AI Thinker ESP32-CAM* secara khusus (varian
  ESP32-CAM lain mempunyai peta pin yang berbeza).

---

## Nota seni bina: tiada perkongsian

Tiada pakej Dart yang dikongsi antara `app/` dan `website/` — definisi model
diduplikasi antara kedua-duanya dengan sengaja (keputusan produk yang
disengajakan, bukan kelalaian). Kekalkan kedua-dua belah konsisten secara
berasingan dan bukannya cuba mengekstrak pakej kongsi.
