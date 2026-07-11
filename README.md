# TampalPintar — Pothole Reporting for Selangor

A pothole-reporting prototype for Selangor, Malaysia, made of four parts that
share one Supabase backend:

- **`app/`** — Flutter Android app for citizens: photo reports, plus
  hands-free voice reports triggered by a custom "Tampal Pintar" wake word.
- **`website/`** — Flutter Web dashboard for four government authority roles
  (runs in Chrome).
- **`firmware/tampal_pintar_cam/`** — ESP32-CAM (AI-Thinker board) Arduino
  dashcam sketch that streams photos into Supabase Storage.
- **`supabase/`** — database migrations (schema, RLS, RPCs, storage, webhook
  trigger) and Deno Edge Functions (`analyze-report`, `dashcam-cleanup`) that
  call Gemini for AI risk scoring.

This README assumes you are starting from **nothing**: no Supabase project,
no API keys, no Arduino IDE. Follow the sections in order — later steps
depend on values you generate in earlier ones.

## Repo layout

| Path | What |
|---|---|
| `app/` | Citizen Android app |
| `website/` | Government Flutter Web dashboard (Chrome) |
| `firmware/tampal_pintar_cam/` | ESP32-CAM Arduino sketch |
| `supabase/` | Migrations + Edge Functions (CLI-managed, no Docker) |
| `shared/map/map.html` | Canonical 3D map page (identical copies live in both apps) |
| `tools/seed/` | Demo data seeder |
| `tools/backend_tests/` | Backend integration test suite |
| `tools/wakeword_check/` | Python parity check for the wake-word pipeline |

---

## Table of contents

1. [What you'll need](#1-what-youll-need)
2. [Get the code](#2-get-the-code)
3. [Create your Supabase project](#3-create-your-supabase-project)
4. [Get a Gemini API key](#4-get-a-gemini-api-key)
5. [Get a Google Maps API key](#5-get-a-google-maps-api-key)
6. [Deploy the backend — with or without the Supabase CLI](#6-deploy-the-backend--with-or-without-the-supabase-cli)
7. [Configure the codebase with your keys](#7-configure-the-codebase-with-your-keys)
8. [Seed demo data](#8-seed-demo-data)
9. [Set up Flutter and run the Android app](#9-set-up-flutter-and-run-the-android-app)
10. [Run the government website](#10-run-the-government-website)
11. [Set up Arduino IDE and flash the ESP32-CAM](#11-set-up-arduino-ide-and-flash-the-esp32-cam)
12. [Running the tests](#12-running-the-tests)
13. [Demo-day switch: FAKE_EXTERNALS](#13-demo-day-switch-fake_externals)
14. [Manual end-to-end demo checklist](#14-manual-end-to-end-demo-checklist)
15. [Troubleshooting](#15-troubleshooting)

---

## 1. What you'll need

Accounts (all free tier is enough):

- A **Supabase** account — [supabase.com](https://supabase.com)
- A **Google account** — used for both Google AI Studio (Gemini) and Google
  Cloud Console (Maps)

Software to install on your machine (links and steps are in the relevant
sections below, this is just the checklist):

- [ ] Git
- [ ] [Flutter SDK](https://docs.flutter.dev/get-started/install) (this repo
      was built against the Dart SDK constraint `^3.9.2`, i.e. a recent
      Flutter stable release)
- [ ] Android Studio (for the Android SDK/emulator + USB drivers) — only
      needed for the `app/`
- [ ] Google Chrome — used to run `website/`
- [ ] [Supabase CLI](https://supabase.com/docs/guides/cli/getting-started) —
      optional; section 6 also documents a Dashboard-only path with no CLI
- [ ] [Arduino IDE](https://www.arduino.cc/en/software) — only needed if you
      have physical ESP32-CAM hardware
- [ ] An Android phone with USB debugging enabled, or an Android emulator —
      only strictly needed for the wake-word/mic/GPS parts; the app can also
      be built as an APK

---

## 2. Get the code

```
git clone <this-repo-url>
cd TampalPintar
```

---

## 3. Create your Supabase project

1. Go to [supabase.com](https://supabase.com) and sign in (or sign up — GitHub
   login is the fastest option).
2. Click **New project** (top right of the dashboard, or from an
   organization's project list).
3. Fill in:
   - **Name**: anything, e.g. `tampal-pintar`.
   - **Database Password**: generate a strong one and **save it somewhere
     safe** — you'll need it once in step 6 and rarely again. This is
     different from any API key.
   - **Region**: pick whatever is closest to you (e.g. Singapore for
     Southeast Asia).
4. Click **Create new project** and wait 1–2 minutes for provisioning.
5. Once the project is ready, collect the following four values — you'll
   paste them into files later, so keep this page open or copy them into a
   scratch text file for now:

   | Value | Where to find it |
   |---|---|
   | **Project URL** | Project → **Settings** (gear icon, bottom left) → **Data API**. Looks like `https://abcdefghijklmnop.supabase.co`. |
   | **Project Reference** | The subdomain part of the Project URL above, e.g. `abcdefghijklmnop`. Also shown at **Settings → General**. |
   | **anon / public key** | **Settings → API Keys**. Labeled `anon` `public`. A long string starting with `eyJ...`. Safe to use in client apps (that's what RLS is for). |
   | **service_role key** | Same page, **API Keys**, labeled `service_role`. ⚠️ Full admin access, bypasses RLS — never put this in `app/`, `website/`, or firmware code. Only used server-side (seed script, backend tests). |

6. You also need a **personal access token** for the Supabase CLI (different
   from the project's API keys):
   - Click your avatar (top right) → **Account preferences** → **Access
     Tokens** → **Generate new token**.
   - Name it anything (e.g. `tampal-pintar-cli`), copy the value shown
     (`sbp_...`) — it's shown only once.

Keep all five values (Project URL, project ref, anon key, service_role key,
personal access token) plus the database password handy — the rest of this
guide refers back to them as **"your project ref"**, **"your anon key"**,
etc.

---

## 4. Get a Gemini API key

The `analyze-report` Edge Function calls Gemini once per report (risk
scoring from photos + weather + road context).

1. Go to [Google AI Studio](https://aistudio.google.com/apikey).
2. Sign in with your Google account.
3. Click **Create API key** (choose "Create API key in new project" if you
   don't already have a Google Cloud project picked).
4. Copy the key (starts with `AIza...`).

This key is only ever set as a **Supabase Edge Function secret** (step 6) —
it never appears in `app/`, `website/`, or firmware code, and should never be
committed anywhere.

---

## 5. Get a Google Maps API key

The 3D map page (`shared/map/map.html`) uses the **Maps JavaScript API**
(alpha channel, for the photorealistic 3D `maps3d` library). Pick one of the
two options below — either produces the same kind of `AIza...` key, and it
goes in the same place ([step 7.4](#74-the-3d-map-page--line-77-in-3-identical-copies)).

### Option A — Free demo key (fastest, no billing/credit card required)

Google Maps Platform publishes a no-cost **demo key** meant exactly for
prototyping/evaluation like this project:

1. Go to [mapsplatform.google.com/maps-demo-key](https://mapsplatform.google.com/maps-demo-key/).
2. Click **Try for free**. This opens the Google Cloud console and
   provisions a demo key for you — just needs a Google account, no credit
   card and no billing setup.
3. Copy the key it shows you (starts with `AIza...`).

Fine print: the demo key covers a fixed bundle of APIs that includes **3D
Maps** (exactly what this project's map page uses), plus Dynamic Maps,
Geocoding, Places, Routes, and Weather. It has a **daily usage cap per API**
— once you exceed it for the day, the map simply stops responding until the
next day; you are not charged. It's explicitly scoped to **development and
testing, not production**.

### Option B — Your own key via Google Cloud Console (recommended if you want your own quota, no daily cap, or need it long-term)

1. Go to the [Google Cloud Console](https://console.cloud.google.com/).
2. Create a new project (or reuse the one AI Studio created in step 4) —
   top left project dropdown → **New Project**.
3. Enable the API: go to **APIs & Services → Library**, search for **"Maps
   JavaScript API"**, click it, click **Enable**.
4. Create a key: **APIs & Services → Credentials → + Create Credentials →
   API key**. Copy the key (starts with `AIza...`).
5. (Recommended, not required for local testing) Click **Restrict key** and
   restrict it to the **Maps JavaScript API**, and optionally to your app's
   package name / website referrer once you know them. An unrestricted key
   works fine for local development but shouldn't be left that way in a
   public repo's live config — this repo only ever ships placeholders, so
   each person's own key is theirs to restrict.
6. Make sure billing is enabled on the Cloud project. Maps JavaScript API
   requires an active billing account, but Google's free monthly credit
   comfortably covers demo/dev usage. (Skip this whole option and use Option
   A above if you'd rather not set up billing at all.)

---

## 6. Deploy the backend — with or without the Supabase CLI

Two ways to get the schema, RLS, RPCs, storage policies, webhook trigger,
and the two Edge Functions onto your project. **Option A is faster** and is
what the rest of this README assumes when it mentions CLI commands in
passing; **Option B needs nothing installed** — just your browser and the
Supabase Dashboard. Pick one; you don't need both.

### Option A — Using the Supabase CLI (recommended, faster)

Install the CLI (pick one):

```
scoop install supabase        # Windows, via Scoop
npm i -g supabase             # any OS with Node.js
winget install Supabase.CLI   # Windows, via winget
brew install supabase/tap/supabase   # macOS/Linux, via Homebrew
```

No Docker is required — every command below talks to your hosted project
directly (`--use-api` / linked mode).

From the repo root:

```
$env:SUPABASE_ACCESS_TOKEN = "<your personal access token from step 3, sbp_...>"
$env:SUPABASE_DB_PASSWORD  = "<your database password from step 3>"
supabase link --project-ref <your project ref>
```

(On macOS/Linux use `export SUPABASE_ACCESS_TOKEN=...` etc. instead of the
PowerShell `$env:` syntax.)

**Before pushing migrations**, do the one required manual edit described in
the next section (step 7.3) — one migration file needs your project's own
URL and anon key baked in. Do that now, then come back here and run:

```
supabase db push --include-all
```

`--include-all` is required — a plain `supabase db push` silently skips some
migrations in this project.

Deploy the Edge Functions:

```
supabase functions deploy analyze-report dashcam-cleanup --use-api
```

Set the Edge Function secrets:

```
supabase secrets set GEMINI_API_KEY=<your Gemini key from step 4>
supabase secrets set GOOGLE_MAPS_KEY=<your Google Maps key from step 5>
supabase secrets set FAKE_EXTERNALS=1
```

`FAKE_EXTERNALS=1` makes the backend test suite deterministic (fakes
Gemini/Weather/Geocoding instead of calling them for real). Leave it set for
now — [section 13](#13-demo-day-switch-fake_externals) explains when to
unset it.

If you used Option A, skip straight to [section 7](#7-configure-the-codebase-with-your-keys).

### Option B — Without the Supabase CLI (Dashboard only)

Everything the CLI did above can be done by hand in the Supabase Dashboard.
It's more copy-pasting, but there's nothing to install and no access
token/linking step.

**B.1 — Run the database migrations via the SQL Editor**

`supabase/migrations/` contains 10 plain `.sql` files that must be run **in
this exact order** (each one builds on the last — tables before RLS
policies before RPCs, and so on):

```
20260709000001_schema.sql
20260709000002_policies.sql
20260709000003_submit_report.sql
20260709000004_mark_fixed.sql
20260709000005_redeem.sql
20260709000006_leaderboards.sql
20260709000007_storage.sql
20260709000008_analyze_webhook.sql   <- edit this one first, see step 7.3 below
20260709000009_redeem_code_hardening.sql
20260709000010_column_grants.sql
```

For each file, in order:

1. Open the file locally in a text editor and copy its entire contents.
   **For `20260709000008_analyze_webhook.sql` specifically**, first make the
   edit described in step 7.3 below (section 7) — replace the URL and
   Bearer-token placeholders with your real
   project ref and anon key — *then* copy the edited contents.
2. In the Supabase Dashboard, open your project → **SQL Editor** (left
   sidebar) → **New query**.
3. Paste the file's contents into the editor and click **Run** (or
   Ctrl+Enter / Cmd+Enter).
4. Confirm you see a success message with no red error banner before moving
   on to the next file. Repeat for all 10 files, strictly in order.

If `20260709000008_analyze_webhook.sql` errors on
`create extension if not exists pg_net;` with a permissions message, go to
**Database → Extensions** (left sidebar), search for **pg_net**, toggle it
on, then re-run that file.

**B.2 — Deploy the Edge Functions via the Dashboard's built-in editor**

Both functions in this repo are a single file each, so the browser editor
is enough — no zip upload or multi-file bundling needed:

1. Go to **Edge Functions** (left sidebar) → **Deploy a new function** →
   **Via editor**.
2. Name it exactly `analyze-report`.
3. Select all the placeholder template code in the editor and replace it
   with the full contents of `supabase/functions/analyze-report/index.ts`
   from this repo.
4. Click **Deploy**.
5. Repeat steps 1–4 for a second function named exactly `dashcam-cleanup`,
   pasting the contents of `supabase/functions/dashcam-cleanup/index.ts`.

**B.3 — Set Edge Function secrets via the Dashboard**

1. Still under **Edge Functions**, open the **Secrets** tab (some Dashboard
   versions label it **Manage secrets**).
2. Add three secrets:

   | Name | Value |
   |---|---|
   | `GEMINI_API_KEY` | your Gemini key from step 4 |
   | `GOOGLE_MAPS_KEY` | your Google Maps key from step 5 |
   | `FAKE_EXTERNALS` | `1` |

3. Save. Later, whenever this README says to run
   `supabase secrets set FAKE_EXTERNALS=1` or
   `supabase secrets unset FAKE_EXTERNALS` ([section 13](#13-demo-day-switch-fake_externals)),
   do the equivalent here instead: edit or delete the `FAKE_EXTERNALS` row
   in this same Secrets tab.

Everything from [section 7](#7-configure-the-codebase-with-your-keys) onward
(seeding, running the app/website, tests) works identically no matter which
option you used here — none of it talks to the CLI, only to your project's
public URL and keys.

---

## 7. Configure the codebase with your keys

Six tracked files in this repo ship with **placeholder** values. Replace
every placeholder below with the real values you collected in step 3 (and
step 5 for the Maps key). None of these files are git-ignored, so don't
commit real secrets into them if this repo is public — that's exactly what
this README is helping you avoid by keeping the *real* secrets only in your
local, git-ignored `API Key Configuration.md` / environment variables / CLI
secrets.

### 7.1 `app/lib/config.dart` — lines 2–3

```dart
const kSupabaseUrl = 'https://YOUR_PROJECT_REF.supabase.co';    // line 2
const kSupabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';               // line 3
```

Replace `YOUR_PROJECT_REF` with your project ref and `YOUR_SUPABASE_ANON_KEY`
with your anon key (both from step 3).

### 7.2 `website/lib/config.dart` — lines 2–3

Same two constants, same values, same line numbers:

```dart
const kSupabaseUrl = 'https://YOUR_PROJECT_REF.supabase.co';    // line 2
const kSupabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';               // line 3
```

### 7.3 `supabase/migrations/20260709000008_analyze_webhook.sql` — lines 11 and 14, do this **before** `supabase db push`

This migration installs a Postgres trigger that calls the `analyze-report`
Edge Function via `pg_net` whenever a report is inserted. Postgres can't read
Supabase's Edge Function secrets, so the anon key has to be baked directly
into this SQL file:

```sql
perform net.http_post(
  url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/analyze-report',   -- line 11
  headers := jsonb_build_object(
    'Content-Type', 'application/json',
    'Authorization', 'Bearer YOUR_SUPABASE_ANON_KEY'                           -- line 14
  ),
  ...
```

Replace both placeholders (line 11's URL, line 14's Bearer token) with your
project ref and anon key, save the file,
**then** run `supabase db push --include-all` (step 6). If you push before
editing this file, the trigger will silently fail (it'll POST to a
nonexistent host) — re-run `supabase db push --include-all` again after
fixing it, migrations are idempotent here.

### 7.4 The 3D map page — line 77 in 3 identical copies

The map page is duplicated on purpose (see [Architecture note](#architecture-note-non-sharing)
below): edit the **canonical** file, then copy it over both others so all
three stay byte-identical.

1. Edit `shared/map/map.html`, **line 77**:
   ```js
   key: "YOUR_GOOGLE_MAPS_API_KEY",
   ```
   and replace with your Google Maps key from step 5. (The same line, 77,
   also holds the placeholder in the two copies below — once you copy the
   file over them it'll line up automatically.)
2. Copy the file over both other locations:
   ```
   copy shared\map\map.html app\assets\map\map.html
   copy shared\map\map.html website\web\map.html
   ```
   (macOS/Linux: `cp shared/map/map.html app/assets/map/map.html && cp shared/map/map.html website/web/map.html`)

### 7.5 Firmware config block — lines 18–19, only if you have ESP32-CAM hardware

Covered in full in [section 11](#11-set-up-arduino-ide-and-flash-the-esp32-cam);
the same two Supabase values go into
`firmware/tampal_pintar_cam/tampal_pintar_cam.ino`, lines 18–19:

```cpp
const char* SUPABASE_URL = "https://YOUR_PROJECT_REF.supabase.co";  // line 18
const char* SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_KEY";           // line 19
```

---

## 8. Seed demo data

Idempotent — safe to re-run any time.

```
cd tools\seed
dart pub get
$env:SEED_URL = "https://YOUR_PROJECT_REF.supabase.co"
$env:SEED_SERVICE_ROLE_KEY = "<your service_role key from step 3>"
dart run bin/seed.dart
cd ..\..
```

This creates demo accounts (password for all: `TampalPintar#2026`):

| Account | Role |
|---|---|
| `aisyah@tampalpintar.demo` | Citizen (dashcam `DEMO-CAM-01`, vehicle Car) |
| `weiming@ / kumar@ / siti@tampalpintar.demo` | Citizens |
| `jkr.malaysia@tampalpintar.demo` | JKR Malaysia (Federal Routes) |
| `jkr.selangor@tampalpintar.demo` | JKR Selangor (State Routes) |
| `local.council@tampalpintar.demo` | Local Council (Municipal/Local) |
| `highway@tampalpintar.demo` | Highway Concessionaire (Expressways) |

These are fixed demo credentials baked into the seed script itself
(`tools/seed/bin/seed.dart`) — they only exist in **your own** Supabase
project once you run the seeder, so there's no shared/public account here.

---

## 9. Set up Flutter and run the Android app

### 9.1 Install Flutter

1. Follow the official install guide for your OS:
   [docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install).
   On Windows this is usually: download the Flutter SDK zip, extract it
   (e.g. to `C:\src\flutter`), add `C:\src\flutter\bin` to your `PATH`.
2. Install **Android Studio** ([developer.android.com/studio](https://developer.android.com/studio))
   — needed for the Android SDK, platform tools (`adb`), and an emulator if
   you don't have a physical phone.
3. Verify everything:
   ```
   flutter doctor
   ```
   Resolve any ✗ items it reports (accept Android licenses with
   `flutter doctor --android-licenses`, install missing SDK components from
   Android Studio's SDK Manager, etc.) until Android toolchain items are ✓.

### 9.2 Get a device

**Option A — physical Android phone (required for the mic/wake-word and
live GPS features to actually work):**

1. On the phone: **Settings → About phone** → tap **Build number** 7 times
   to enable Developer Options.
2. **Settings → Developer options** → enable **USB debugging**.
3. Plug the phone into your computer via USB, accept the "Allow USB
   debugging?" prompt on the phone.
4. Confirm it's detected: `flutter devices` should list it.

**Option B — Android emulator (fine for UI/map/photo-report testing; mic
wake-word won't have a real audio source):**

1. In Android Studio: **Tools → Device Manager → Create device**, pick any
   modern phone profile, a system image with **API 26+** (this app's
   `minSdk` is 26), download the image if prompted, finish.
2. Start the emulator from Device Manager, or `flutter emulators --launch <id>`.

### 9.3 Run the app

```
cd app
flutter pub get
flutter run
```

If multiple devices/emulators are attached, `flutter run` will prompt you to
pick one, or pass `-d <device-id>` directly (`flutter devices` lists IDs).

### 9.4 Build an installable APK instead

```
cd app
flutter pub get
flutter build apk --release
```

The APK is written to `app\build\app\outputs\flutter-apk\app-release.apk`.
Copy it to a phone and install it directly (you'll need to allow "install
from unknown sources" for whichever app you transfer it with).

### 9.5 Run the app's tests

```
cd app
flutter test --concurrency=1        # --concurrency=1 is required
flutter analyze
```

---

## 10. Run the government website

```
cd website
flutter pub get
flutter run -d chrome
flutter analyze
```

There are no automated website tests — the project's verification is manual
(see the [demo checklist](#14-manual-end-to-end-demo-checklist) below).

---

## 11. Set up Arduino IDE and flash the ESP32-CAM

Only needed if you have a physical **AI-Thinker ESP32-CAM** board (and,
usually, a separate FTDI/USB-serial adapter to program it — most ESP32-CAM
boards have no onboard USB port).

### 11.1 Install Arduino IDE

1. Download and install the Arduino IDE (2.x) from
   [arduino.cc/en/software](https://www.arduino.cc/en/software).

### 11.2 Add ESP32 board support

1. Open Arduino IDE → **File → Preferences**.
2. In **Additional boards manager URLs**, add:
   ```
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
3. **Tools → Board → Boards Manager**, search **"esp32"**, install the
   package published by **Espressif Systems**.

This one package provides everything the sketch needs — `WiFi.h`,
`WiFiClientSecure.h`, `HTTPClient.h`, `esp_camera.h`, and `time.h` are all
part of the ESP32 core/camera driver. No separate Library Manager installs
are required for this project.

### 11.3 Configure the sketch

Open `firmware/tampal_pintar_cam/tampal_pintar_cam.ino` in the Arduino IDE
and edit the `CONFIG (edit these)` block near the top:

```cpp
const char* WIFI_SSID   = "TampalPintar";        // your phone hotspot name
const char* WIFI_PASS   = "potholes123";         // your phone hotspot password
const char* DASHCAM_ID  = "DEMO-CAM-01";         // must match the profile's dashcam_id
const char* SUPABASE_URL = "https://YOUR_PROJECT_REF.supabase.co";
const char* SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_KEY";
```

- `WIFI_SSID` / `WIFI_PASS`: set these to match a mobile hotspot you'll turn
  on from the phone running the citizen app — the ESP32-CAM joins that
  hotspot, it doesn't need your home Wi-Fi.
- `DASHCAM_ID`: must match the `dashcam_id` on a citizen profile (the seed
  script sets `aisyah@tampalpintar.demo`'s to `DEMO-CAM-01`, matching the
  default here — change both together if you use a different profile).
- `SUPABASE_URL` / `SUPABASE_ANON_KEY`: your project ref and anon key from
  step 3, same values as everywhere else in this section.

### 11.4 Power supply and programmer — choose one

The AI-Thinker ESP32-CAM has no onboard USB port and no onboard voltage
regulator good enough to run the camera reliably off some 5V sources, so it
needs a separate board to both power it and expose a USB-serial connection
for flashing. Two options:

**Option A — ESP32-CAM Mother Board / programmer board (recommended)**

A small breakout board (commonly sold as "ESP32-CAM-MB" or "ESP32-CAM
Programmer") that the ESP32-CAM plugs directly into. It supplies power over
USB and handles the UART + auto-reset wiring for you — no jumper wires, no
separate power supply, no manually toggling IO0.

1. Plug the ESP32-CAM onto the mother board's header (orientation matters —
   match the silkscreen markings on your specific board; the camera
   typically faces away from the USB connector).
2. Connect the mother board to your computer with a Micro-USB cable. This
   both powers the board and exposes it as a serial port.
3. Windows needs the USB-to-serial driver for whichever chip your mother
   board uses (commonly CH340 or CP2102) — Windows Update usually installs
   it automatically the first time you plug in; if the board doesn't show up
   under **Tools → Port**, search "<CH340 or CP2102> driver" for your OS.
4. Most mother boards auto-reset into bootloader mode when you click
   **Upload** (no button press needed). If an upload times out at
   "Connecting...", check your specific board's markings for a **RESET** or
   **BOOT** button and hold it briefly when the IDE starts uploading.
5. No separate power adapter is needed — the USB port supplies it, both for
   flashing and for normal operation as long as it stays plugged into a USB
   power source (a phone charger + cable works fine once you're done
   flashing and just want it running as a dashcam).

**Option B — external power + FTDI/USB-TTL adapter**

If you don't have a mother board, wire a plain FTDI/USB-TTL adapter directly
to the ESP32-CAM's pins (5V logic-tolerant boards, or use a 3.3V adapter):

| ESP32-CAM | Adapter |
|---|---|
| 5V | 5V (or 3.3V pin if using a 3.3V adapter into the board's 3.3V rail — check your specific board's docs) |
| GND | GND |
| U0R (RX) | TX |
| U0T (TX) | RX |
| IO0 | GND (**only while flashing** — this puts the chip into bootloader mode) |

To flash: connect IO0 to GND, press the board's **RESET** button (or
power-cycle it), then upload from the IDE. After a successful upload,
disconnect IO0 from GND and reset again to run the sketch normally. For
running it afterward (not just flashing) you'll also need a separate stable
5V power source into the same 5V/GND pins, since the adapter alone usually
can't supply enough current for the camera long-term.

### 11.5 Select board and port, then compile/upload

1. **Tools → Board → esp32 → AI Thinker ESP32-CAM**.
2. **Tools → Port** → select the COM port your mother board or adapter shows
   up as.
3. **Tools → Partition Scheme** → pick one with enough app space, e.g.
   *"Huge APP (3MB No OTA/1MB SPIFFS)"* — the default scheme is sometimes too
   small for the camera + TLS stack.
4. Click **Upload** (or **Verify** first to just compile-check).

Or, headless, using the CLI:

```
arduino-cli core install esp32:esp32
arduino-cli compile --fqbn esp32:esp32:esp32cam firmware/tampal_pintar_cam
arduino-cli upload -p <COM_PORT> --fqbn esp32:esp32:esp32cam firmware/tampal_pintar_cam
```

### 11.6 First boot

Open the IDE's **Serial Monitor** (115200 baud) after a normal boot/reset
(not while held in bootloader mode — if you used Option B's IO0-to-GND
trick, disconnect that first). You should see it join the hotspot, sync NTP
time, clean up any leftover photos from a previous run, then start
streaming `Streaming photos to Supabase Storage...`. In the citizen app,
starting a drive should show *"Dashcam Connected"* once the ESP32 is
uploading.

---

## 12. Running the tests

### 12.1 Backend integration tests ("Seam 1")

These run against your **live hosted Supabase project** with the seeded
demo data — they are integration tests, not isolated/mocked unit tests.

1. Create `tools/backend_tests/test_config.json` (git-ignored — you create
   this file yourself, it doesn't ship with the repo):
   ```json
   {
     "url":            "https://YOUR_PROJECT_REF.supabase.co",
     "anonKey":        "YOUR_SUPABASE_ANON_KEY",
     "serviceRoleKey": "YOUR_SUPABASE_SERVICE_ROLE_KEY",
     "functionsUrl":   "https://YOUR_PROJECT_REF.supabase.co/functions/v1"
   }
   ```
2. Make sure the `FAKE_EXTERNALS` secret is set (see step 6):
   ```
   supabase secrets set FAKE_EXTERNALS=1
   ```
3. Run:
   ```
   cd tools\backend_tests
   dart pub get
   dart test                                  # whole suite
   dart test test/submit_report_test.dart     # single file
   ```

### 12.2 App logic tests ("Seam 2")

```
cd app
flutter test --concurrency=1
```

### 12.3 Wake-word math parity check

Verifies the Dart reimplementation of the wake-word ONNX pipeline agrees
with a reference Python chain.

```
pip install onnxruntime numpy
cd tools\wakeword_check
python check.py            # synthetic audio
python check.py drive.wav  # or a real 16 kHz mono 16-bit recording of the phrase
```

---

## 13. Demo-day switch: `FAKE_EXTERNALS`

The backend test suite (12.1) needs **fake** externals — deterministic
stand-ins for Gemini/Weather/Geocoding, so tests aren't flaky or rate-limited.
A real, live demo (or just to see actual Gemini risk scores) needs the
**real** integrations. Only one can be true at a time:

```
supabase secrets unset FAKE_EXTERNALS     # before a live demo
supabase secrets set FAKE_EXTERNALS=1     # before running the test suite again
```

Leaving it in the wrong state breaks whichever use case you're not currently
doing, so flip it deliberately each time you switch contexts.

---

## 14. Manual end-to-end demo checklist

Once the backend is deployed, seeded, `FAKE_EXTERNALS` is unset, and both
the app and website are configured with your keys:

1. The 3D Selangor map renders with seeded red pins (app + website); tapping
   a pin opens details with Risk Score, road type · authority, and a live
   ticking "Open for" duration.
2. A pedestrian photo report submits instantly; a second report within 10 m
   of it is rejected with a clear duplicate-report message.
3. On the app: **Start Driving** → background/quit the app → say **"Tampal
   Pintar"** (detection threshold 0.28, recall ≈ 57%, so repeat the phrase if
   it's missed the first time) → a **"Pothole Recorded!"** notification
   appears.
4. With the ESP32-CAM powered on and joined to the phone's hotspot: the app
   shows *Dashcam Connected*; the wake word secures 7 photos (the "immediate"
   one framed red in the draft preview); power-cycling the ESP32 only wipes
   its own `live/` leftovers, never kept report photos.
5. In **Pending Reports**: a preview strip, three skippable one-tap
   follow-up questions (Vehicle prefilled from *My Vehicle*), then **Submit**
   → the pin appears on the map and gets AI-scored (all 7 photos sent to
   Gemini; a score ≥ 80 auto-assigns it to an authority).
6. On the website, each government role sees only its own pins; the pin
   slideshow reads like dashcam footage; **Assign** (one-way — dialog names
   the authority) → **Complete** turns it green → confirming makes the pin
   vanish everywhere; the reporter's points jump by the Risk Score; both
   leaderboards update.
7. **Rewards**: redeem a voucher (server-validated), the code lands in *My
   Vouchers*; the Top Reporters rank is unaffected by spending points.

---

## 15. Troubleshooting

- **`supabase db push` seems to skip migrations** — you almost certainly
  forgot `--include-all`. Re-run with it.
- **Reports never get a risk score / stay stuck at `risk_score IS NULL`** —
  you likely pushed migrations before editing
  `supabase/migrations/20260709000008_analyze_webhook.sql` (step 7.3). Edit
  it with your real project ref + anon key and run
  `supabase db push --include-all` again.
- **Map renders blank / a JS error in the browser console** — an invalid or
  unrestricted-but-unbilled Google Maps key fails **silently** in this
  page's alpha `maps3d` loader. Double check: the key is pasted correctly
  in all three `map.html` copies (7.4), the Maps JavaScript API is enabled
  on that Cloud project, and billing is enabled on the Cloud project.
- **Backend tests fail with auth/network errors** — check
  `tools/backend_tests/test_config.json` values against your project's
  current API keys (Settings → API Keys can rotate), and confirm
  `FAKE_EXTERNALS=1` is set as a secret.
- **`flutter doctor` complains about Android licenses** — run
  `flutter doctor --android-licenses` and accept them.
- **ESP32-CAM won't flash** — if using Option B (FTDI adapter), confirm IO0
  is tied to GND *only* during the upload; if using Option A (mother board),
  try holding its RESET/BOOT button while the IDE says "Connecting...".
  Either way, confirm you picked the right COM port and the *AI Thinker
  ESP32-CAM* board variant specifically (other ESP32-CAM variants have
  different pin maps).

---

## Architecture note: non-sharing

There is no shared Dart package between `app/` and `website/` — model
definitions are duplicated between them on purpose (a deliberate product
decision, not an oversight). Keep both sides independently consistent
instead of trying to extract a shared package.
