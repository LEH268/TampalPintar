<div align="center">
    <img src="website/assets/icon/app_icon.png" alt="TampalPintar Logo" width="200" height="200"/>
    <h1>TampalPintar</h1>
    <h3><em>Pothole Reporting for Selangor.</em></h3>
</div>

<p align="center">
    <strong>A pothole reporting project for Selangor, Malaysia.</strong>
</p>

<p align="center">
    <a href="README.md">Malay</a> · <strong>English</strong>
</p>

<p align="center">
    <img src="https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white" alt="Flutter"/>
    <img src="https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white" alt="Dart"/>
    <img src="https://img.shields.io/badge/Supabase-3ECF8E?style=flat&logo=supabase&logoColor=white" alt="Supabase"/>
    <img src="https://img.shields.io/badge/PostgreSQL-4169E1?style=flat&logo=postgresql&logoColor=white" alt="PostgreSQL"/>
    <img src="https://img.shields.io/badge/Deno-000000?style=flat&logo=deno&logoColor=white" alt="Deno"/>
    <img src="https://img.shields.io/badge/Gemini-8E75B2?style=flat&logo=googlegemini&logoColor=white" alt="Gemini"/>
    <img src="https://img.shields.io/badge/Google_Maps-4285F4?style=flat&logo=googlemaps&logoColor=white" alt="Google Maps"/>
    <img src="https://img.shields.io/badge/Arduino-00979D?style=flat&logo=arduino&logoColor=white" alt="Arduino"/>
    <img src="https://img.shields.io/badge/ESP32-E7352C?style=flat&logo=espressif&logoColor=white" alt="ESP32"/>
</p>

This project consists of four parts sharing a single Supabase backend:

- **`app/`** - Flutter Android app for citizens: photo reports, plus
  hands-free voice reports triggered by a custom wake word,
  "Tampal Pintar".
- **`website/`** - Flutter Web dashboard for four government authority
  roles (runs in Chrome).
- **`firmware/tampal_pintar_cam/`** - ESP32-CAM dashcam Arduino sketch
  (AI-Thinker board) that streams photos to Supabase Storage.
- **`supabase/`** - database migrations (schema, RLS, RPC, storage, webhook
  trigger) and Deno Edge Functions (`analyze-report`, `dashcam-cleanup`)
  that call Gemini for AI risk scoring.

## App
<div align="center">
  <table>
    <tr valign="top">
      <th>Map</th>
      <th>Pending</th>
      <th>Ranking</th>
      <th>Rewards</th>
      <th>Settings</th>
    </tr>
    <tr valign="top">
      <td align="center"><img src="assets/Peta.png" alt="map" width="170" /></td>
      <td align="center"><img src="assets/Menunggu.png" alt="pending" width="170" /></td>
      <td align="center"><img src="assets/Ranking.png" alt="ranking" width="170" /></td>
      <td align="center"><img src="assets/Ganjaran.png" alt="rewards" width="170" /></td>
      <td align="center"><img src="assets/Tetapan.png" alt="settings" width="170" /></td>
    </tr>
  </table>
</div>

## Website
| Dashboard |
|-----------|
| ![dashboard](assets/Website.png) |

## Dashcam
<div align="center">
  <table>
    <tr>
      <th>Dashcam</th>
    </tr>
    <tr>
      <td align="center"><img src="assets/Dashcam.png" alt="dashcam" style="width:240px;height:auto;" /></td>
    </tr>
  </table>
</div>

## Repo layout

| Path | What |
|---|---|
| `app/` | Android app for citizens |
| `website/` | Government Flutter Web dashboard (Chrome) |
| `firmware/tampal_pintar_cam/` | ESP32-CAM Arduino sketch |
| `supabase/` | Migrations + Edge Functions (managed via CLI, no Docker) |
| `shared/map/map.html` | Canonical 3D map page (identical copies live in both apps) |
| `tools/seed/` | Demo data seeder |
| `tools/backend_tests/` | Backend integration test suite |
| `tools/wakeword_check/` | Python parity check for the wake word pipeline |

---

## Table of contents

1. [What you need](#1-what-you-need)
2. [Get the code](#2-get-the-code)
3. [Create your Supabase project](#3-create-your-supabase-project)
4. [Get a Gemini API key](#4-get-a-gemini-api-key)
5. [Get a Google Maps API key](#5-get-a-google-maps-api-key)
6. [Deploy the backend - with or without the Supabase CLI](#6-deploy-the-backend---with-or-without-the-supabase-cli)
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

## 1. What you need

Accounts (the free tier is enough for everything):

- A **Supabase** account - [supabase.com](https://supabase.com)
- A **Google account** - used for Google AI Studio (Gemini) and Google
  Cloud Console (Maps)

Software to install on your machine (links and steps are in the relevant
sections below, this is just a checklist):

- [ ] Git
- [ ] [Flutter SDK](https://docs.flutter.dev/get-started/install) (this repo
      is built against the Dart SDK constraint `^3.9.2`, i.e. the current
      stable Flutter release)
- [ ] Android Studio (for the Android SDK/emulator + USB drivers) - only
      needed for `app/`
- [ ] Google Chrome - used to run `website/`
- [ ] [Supabase CLI](https://supabase.com/docs/guides/cli/getting-started) -
      optional; section 6 also documents a Dashboard-only path without the CLI
- [ ] [Arduino IDE](https://www.arduino.cc/en/software) - only needed if you
      have physical ESP32-CAM hardware
- [ ] An Android phone with USB debugging enabled, or an Android emulator -
      only strictly needed for the wake word/microphone/GPS parts; the app
      can also be built as an APK

---

## 2. Get the code

```
git clone <url-of-this-repo>
cd TampalPintar
```

---

## 3. Create your Supabase project

1. Go to [supabase.com](https://supabase.com) and sign in (or sign up -
   GitHub login is the fastest option).
2. Click **New project** (top right of the dashboard, or from an
   organisation's project list).
3. Fill in:
   - **Name**: anything, e.g. `tampal-pintar`.
   - **Database Password**: generate a strong one and **store it somewhere
     safe** - you need it once in step 6 and rarely after that. This is
     different from any API key.
   - **Region**: pick the closest to you (e.g. Singapore for Southeast Asia).
4. Click **Create new project** and wait 1-2 minutes for provisioning.
5. Once the project is ready, collect these four values - you will paste
   them into files later, so leave this page open or copy the values into a
   temporary text file for now:

   | Value | Where to find it |
   |---|---|
   | **Project URL** | Project → **Settings** (gear icon, bottom left) → **Data API**. Looks like `https://abcdefghijklmnop.supabase.co`. |
   | **Project Reference** | The subdomain part of the Project URL above, e.g. `abcdefghijklmnop`. Also shown at **Settings → General**. |
   | **anon / public key** | **Settings → API Keys**. Labelled `anon` `public`. A long string starting with `eyJ...`. Safe to use in client apps (that is what RLS is for). |
   | **service_role key** | Same page, **API Keys**, labelled `service_role`. ⚠️ Full admin access, bypasses RLS - never put it in `app/`, `website/`, or firmware code. Only used server-side (seeder script, backend tests). |

6. You also need a **personal access token** for the Supabase CLI (different
   from the project API keys):
   - Click your avatar (top right) → **Account preferences** → **Access
     Tokens** → **Generate new token**.
   - Name it anything (e.g. `tampal-pintar-cli`), copy the displayed value
     (`sbp_...`) - it is shown only once.

Keep all five values (Project URL, project ref, anon key, service_role key,
personal access token) along with the database password - the rest of this
guide refers back to them as **"your project ref"**, **"your anon key"**,
and so on.

---

## 4. Get a Gemini API key

The `analyze-report` Edge Function calls Gemini once per report (risk
scoring from photo + weather + road context).

1. Go to [Google AI Studio](https://aistudio.google.com/apikey).
2. Sign in with your Google account.
3. Click **Create API key** (choose "Create API key in new project" if you
   do not already have a Google Cloud project selected).
4. Copy the key (starts with `AIza...`).

This key is only set as a **Supabase Edge Function secret** (step 6) - it
never appears in `app/`, `website/`, or firmware code, and should not be
committed anywhere.

---

## 5. Get a Google Maps API key

The 3D map page (`shared/map/map.html`) uses the **Maps JavaScript API**
(alpha channel, for the photorealistic 3D `maps3d` library). Pick one of the
two options below - both produce the same kind of `AIza...` key, and it goes
in the same place
([step 7.4](#74-3d-map-page---line-77-in-3-identical-copies)).

### Option A - Free demo key (fastest, no billing/credit card required)

Google Maps Platform publishes a free **demo key** intended precisely for
prototyping/evaluation like this project:

1. Go to [mapsplatform.google.com/maps-demo-key](https://mapsplatform.google.com/maps-demo-key/).
2. Click **Try for free**. This opens the Google Cloud console and
   provisions a demo key for you - it only requires a Google account, no
   credit card and no billing setup.
3. Copy the key shown (starts with `AIza...`).

Important note: the demo key covers a fixed set of APIs that includes
**3D Maps** (exactly what this project's map page uses), plus Dynamic Maps,
Geocoding, Places, Routes, and Weather. It has a **daily usage cap per API** -
when you exceed it for the day, the map simply stops responding until the
next day; you are not charged. It is explicitly scoped for **development and
testing, not production**.

### Option B - Your own key via Google Cloud Console (recommended if you want your own quota, no daily cap, or need it long term)

1. Go to [Google Cloud Console](https://console.cloud.google.com/).
2. Create a new project (or reuse the one AI Studio created in step 4) -
   project dropdown at top left → **New Project**.
3. Enable the API: go to **APIs & Services → Library**, search for **"Maps
   JavaScript API"**, click it, click **Enable**.
4. Create the key: **APIs & Services → Credentials → + Create Credentials →
   API key**. Copy the key (starts with `AIza...`).
5. (Recommended, not required for local testing) Click **Restrict key** and
   limit it to the **Maps JavaScript API**, and if you like, to your app
   package name / website referrer once you know them. An unrestricted key
   works fine for local development but should not be left that way in a
   public repo's live config - this repo ships only placeholder values, so
   everyone's key is theirs to restrict.
6. Make sure billing is enabled on that Cloud project. The Maps JavaScript
   API requires an active billing account, but Google's monthly free credit
   is more than enough for demo/development use. (Skip this whole option and
   use Option A above if you would rather not set up billing at all.)

---

## 6. Deploy the backend - with or without the Supabase CLI

Two ways to install the schema, RLS, RPC, storage policies, webhook trigger,
and both Edge Functions into your project. **Option A is faster** and is what
the rest of this README assumes when it mentions CLI commands in passing;
**Option B requires no installation at all** - just your browser and the
Supabase Dashboard. Pick one; you do not need both.

### Option A - Using the Supabase CLI (recommended, faster)

Install the CLI (pick one):

```
scoop install supabase        # Windows, via Scoop
npm i -g supabase             # any OS with Node.js
winget install Supabase.CLI   # Windows, via winget
brew install supabase/tap/supabase   # macOS/Linux, via Homebrew
```

Docker is not required - every command below talks directly to your hosted
project (`--use-api` / linked mode).

From the repo root:

```
$env:SUPABASE_ACCESS_TOKEN = "<your personal access token from step 3, sbp_...>"
$env:SUPABASE_DB_PASSWORD  = "<your database password from step 3>"
supabase link --project-ref <your project ref>
```

(On macOS/Linux use `export SUPABASE_ACCESS_TOKEN=...` and similar instead
of the PowerShell `$env:` syntax.)

**Before pushing migrations**, make one mandatory manual edit described in
the next section (step 7.3) - one migration file needs your own project URL
and anon key embedded in it. Do that now, then come back here and run:

```
supabase db push --include-all
```

`--include-all` is mandatory - a plain `supabase db push` will silently skip
some migrations in this project.

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

`FAKE_EXTERNALS=1` makes the backend test suite deterministic - it fakes
Gemini/Weather/Geocoding instead of calling the real services. Leave it set
for now - [section 13](#13-demo-day-switch-fake_externals) explains when to
unset it.

If you used Option A, skip straight to
[section 7](#7-configure-the-codebase-with-your-keys).

### Option B - Without the Supabase CLI (Dashboard only)

Everything the CLI does above can be done by hand in the Supabase Dashboard.
It is more copy-pasting, but there is nothing to install and no access
token/linking step.

**B.1 - Run the database migrations via the SQL Editor**

`supabase/migrations/` contains 10 plain `.sql` files that must be run **in
exactly this order** (each builds on the previous - tables before RLS
policies before RPC, and so on):

```
20260709000001_schema.sql
20260709000002_policies.sql
20260709000003_submit_report.sql
20260709000004_mark_fixed.sql
20260709000005_redeem.sql
20260709000006_leaderboards.sql
20260709000007_storage.sql
20260709000008_analyze_webhook.sql   <- edit this file first, see step 7.3 below
20260709000009_redeem_code_hardening.sql
20260709000010_column_grants.sql
```

For each file, in order:

1. Open the file locally in a text editor and copy its entire contents.
   **Specifically for `20260709000008_analyze_webhook.sql`**, first make the
   edit described in step 7.3 below (section 7) - replace the placeholder URL
   and Bearer token with your real project ref and anon key - *then* copy the
   edited contents.
2. In the Supabase Dashboard, open your project → **SQL Editor** (left
   sidebar) → **New query**.
3. Paste the file contents into the editor and click **Run** (or
   Ctrl+Enter / Cmd+Enter).
4. Make sure you see a success message with no red error banner before
   moving to the next file. Repeat for all 10 files, strictly in order.

If `20260709000008_analyze_webhook.sql` errors on
`create extension if not exists pg_net;` with a permission message, go to
**Database → Extensions** (left sidebar), find **pg_net**, enable it, then
re-run the file.

**B.2 - Deploy the Edge Functions via the Dashboard's built-in editor**

Both functions in this repo are a single file each, so the browser editor is
enough - no zip upload or multi-file bundling needed:

1. Go to **Edge Functions** (left sidebar) → **Deploy a new function** →
   **Via editor**.
2. Name it exactly `analyze-report`.
3. Select all the placeholder template code in the editor and replace it
   with the full contents of `supabase/functions/analyze-report/index.ts`
   from this repo.
4. Click **Deploy**.
5. Repeat steps 1-4 for the second function named exactly
   `dashcam-cleanup`, pasting the contents of
   `supabase/functions/dashcam-cleanup/index.ts`.

**B.3 - Set the Edge Function secrets via the Dashboard**

1. Still under **Edge Functions**, open the **Secrets** tab (some Dashboard
   versions label it **Manage secrets**).
2. Add three secrets:

   | Name | Value |
   |---|---|
   | `GEMINI_API_KEY` | your Gemini key from step 4 |
   | `GOOGLE_MAPS_KEY` | your Google Maps key from step 5 |
   | `FAKE_EXTERNALS` | `1` |

3. Save. Then, whenever this README tells you to run
   `supabase secrets set FAKE_EXTERNALS=1` or
   `supabase secrets unset FAKE_EXTERNALS` ([section 13](#13-demo-day-switch-fake_externals)),
   do the equivalent here: edit or delete the `FAKE_EXTERNALS` row in this
   same Secrets tab.

Everything from [section 7](#7-configure-the-codebase-with-your-keys)
onwards (seeding, running the app/website, tests) works identically no
matter which option you used here - none of it talks to the CLI, only to
your project's public URL and keys.

---

## 7. Configure the codebase with your keys

Six tracked files in this repo ship with **placeholder** values. Replace each
placeholder below with the real value you collected in step 3 (and step 5 for
the Maps key). None of these files are git-ignored, so do not commit real
secrets into them if this repo is public - that is exactly what this README
helps you avoid, by keeping the *real* secrets only in your local
git-ignored `API Key Configuration.md` / environment variables / CLI secrets.

### 7.1 `app/lib/config.dart` - lines 2-3

```dart
const kSupabaseUrl = 'https://YOUR_PROJECT_REF.supabase.co';    // line 2
const kSupabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';               // line 3
```

Replace `YOUR_PROJECT_REF` with your project ref and
`YOUR_SUPABASE_ANON_KEY` with your anon key (both from step 3).

### 7.2 `website/lib/config.dart` - lines 2-3

The same two constants, same values, same line numbers:

```dart
const kSupabaseUrl = 'https://YOUR_PROJECT_REF.supabase.co';    // line 2
const kSupabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';               // line 3
```

### 7.3 `supabase/migrations/20260709000008_analyze_webhook.sql` - lines 11 and 14, do this **before** `supabase db push`

This migration installs a Postgres trigger that calls the `analyze-report`
Edge Function via `pg_net` every time a report is inserted. Postgres cannot
read Supabase Edge Function secrets, so the anon key has to be embedded
directly into this SQL file:

```sql
perform net.http_post(
  url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/analyze-report',   -- line 11
  headers := jsonb_build_object(
    'Content-Type', 'application/json',
    'Authorization', 'Bearer YOUR_SUPABASE_ANON_KEY'                           -- line 14
  ),
  ...
```

Replace both placeholders (the URL on line 11, the Bearer token on line 14)
with your project ref and anon key, save the file, **then** run
`supabase db push --include-all` (step 6). If you push the migrations before
editing this file, the trigger will fail silently (it will POST to a
non-existent host) - re-run `supabase db push --include-all` after fixing it;
the migrations here are idempotent.

### 7.4 3D map page - line 77 in 3 identical copies

The map page is duplicated on purpose (see the
[architecture note](#architecture-note-no-sharing) below): edit the
**canonical** file, then copy it over the other two so all three stay
byte-for-byte identical.

1. Edit `shared/map/map.html`, **line 77**:
   ```js
   key: "YOUR_GOOGLE_MAPS_API_KEY",
   ```
   and replace it with your Google Maps key from step 5. (The same line, 77,
   also holds the placeholder in the two copies below - once you copy this
   file over them, they all line up automatically.)
2. Copy the file over the other two locations:
   ```
   copy shared\map\map.html app\assets\map\map.html
   copy shared\map\map.html website\web\map.html
   ```
   (macOS/Linux: `cp shared/map/map.html app/assets/map/map.html && cp shared/map/map.html website/web/map.html`)

### 7.5 Firmware config block - lines 18-19, only if you have ESP32-CAM hardware

Covered fully in
[section 11](#11-set-up-arduino-ide-and-flash-the-esp32-cam); the same two
Supabase values go into
`firmware/tampal_pintar_cam/tampal_pintar_cam.ino`, lines 18-19:

```cpp
const char* SUPABASE_URL = "https://YOUR_PROJECT_REF.supabase.co";  // line 18
const char* SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_KEY";           // line 19
```

---

## 8. Seed demo data

Idempotent - safe to re-run at any time.

```
cd tools\seed
dart pub get
$env:SEED_URL = "https://YOUR_PROJECT_REF.supabase.co"
$env:SEED_SERVICE_ROLE_KEY = "<your service_role key from step 3>"
dart run bin/seed.dart
cd ..\..
```

This creates the demo accounts (password for all of them:
`TampalPintar#2026`):

| Account | Role |
|---|---|
| `aisyah@tampalpintar.demo` | Citizen (dashcam `DEMO-CAM-01`, Car vehicle) |
| `weiming@ / kumar@ / siti@tampalpintar.demo` | Citizen |
| `jkr.malaysia@tampalpintar.demo` | JKR Malaysia (Federal Routes) |
| `jkr.selangor@tampalpintar.demo` | JKR Selangor (State Routes) |
| `local.council@tampalpintar.demo` | Local Council (Municipal/Local) |
| `highway@tampalpintar.demo` | Highway Concession (Expressways) |

These are fixed demo credentials embedded in the seeder script itself
(`tools/seed/bin/seed.dart`) - they only exist in **your own** Supabase
project once you run the seeder, so there is no shared/public account here.

---

## 9. Set up Flutter and run the Android app

### 9.1 Install Flutter

1. Follow the official install guide for your OS:
   [docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install).
   On Windows this is usually: download the Flutter SDK zip, extract it
   (e.g. to `C:\src\flutter`), add `C:\src\flutter\bin` to your `PATH`.
2. Install **Android Studio** ([developer.android.com/studio](https://developer.android.com/studio))
   - needed for the Android SDK, platform tools (`adb`), and the emulator if
   you do not have a physical phone.
3. Verify everything:
   ```
   flutter doctor
   ```
   Resolve any ✗ items it reports (accept the Android licences with
   `flutter doctor --android-licenses`, install missing SDK components from
   Android Studio's SDK Manager, etc.) until the Android toolchain item is ✓.

### 9.2 Get a device

**Option A - physical Android phone (required for the wake
word/microphone features and live GPS to actually work):**

1. On the phone: **Settings → About phone** → tap **Build number** 7 times
   to enable Developer Options.
2. **Settings → Developer options** → enable **USB debugging**.
3. Connect the phone to your computer via USB, accept the "Allow USB
   debugging?" prompt on the phone.
4. Verify it is detected: `flutter devices` should list it.

**Option B - Android emulator (fine for testing UI/map/photo reports; the
microphone wake word will have no real audio source):**

1. In Android Studio: **Tools → Device Manager → Create device**, pick any
   modern phone profile, a system image with **API 26+** (this app's
   `minSdk` is 26), download the image if prompted, finish.
2. Start the emulator from Device Manager, or
   `flutter emulators --launch <id>`.

### 9.3 Run the app

```
cd app
flutter pub get
flutter run
```

If multiple devices/emulators are connected, `flutter run` will ask you to
pick one, or pass `-d <device-id>` directly (`flutter devices` lists the IDs).

### 9.4 Or build an installable APK

```
cd app
flutter pub get
flutter build apk --release
```

The APK is written to
`app\build\app\outputs\flutter-apk\app-release.apk`. Copy it to the phone
and install it directly (you will need to allow "install from unknown
sources" for whatever app you use to transfer it).

### 9.5 Run the app tests

```
cd app
flutter test --concurrency=1        # --concurrency=1 is mandatory
flutter analyze
```

---

## 10. Run the government website

```
cd website
flutter pub get
flutter run -d chrome
flutter test
flutter analyze
```

`flutter test` covers the login screen's client-side validation and error
handling. Everything beyond that is verified manually (see the
[demo checklist](#14-manual-end-to-end-demo-checklist) below).

---

## 11. Set up Arduino IDE and flash the ESP32-CAM

Only needed if you have a physical **AI-Thinker ESP32-CAM** board (and,
typically, a separate FTDI/USB-serial adapter to program it - most ESP32-CAM
boards have no built-in USB port).

### 11.1 Install Arduino IDE

1. Download and install Arduino IDE (2.x) from
   [arduino.cc/en/software](https://www.arduino.cc/en/software).

### 11.2 Add ESP32 board support

1. Open Arduino IDE → **File → Preferences**.
2. In **Additional boards manager URLs**, add:
   ```
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
3. **Tools → Board → Boards Manager**, search for **"esp32"**, install the
   package published by **Espressif Systems**.

That one package supplies everything the sketch needs - `WiFi.h`,
`WiFiClientSecure.h`, `HTTPClient.h`, `esp_camera.h`, and `time.h` are all
part of the ESP32 core/camera driver. No separate Library Manager installs
are needed for this project.

### 11.3 Configure the sketch

Open `firmware/tampal_pintar_cam/tampal_pintar_cam.ino` in the Arduino IDE
and edit the `CONFIG (edit these)` block near the top:

```cpp
const char* WIFI_SSID   = "TampalPintar";        // your phone's hotspot name
const char* WIFI_PASS   = "potholes123";         // your phone's hotspot password
const char* DASHCAM_ID  = "DEMO-CAM-01";         // must match the profile's dashcam_id
const char* SUPABASE_URL = "https://YOUR_PROJECT_REF.supabase.co";
const char* SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_KEY";
```

- `WIFI_SSID` / `WIFI_PASS`: set these to match the mobile hotspot you will
  turn on from the phone running the citizen app - the ESP32-CAM joins that
  hotspot, it does not need your home Wi-Fi.
- `DASHCAM_ID`: must match the `dashcam_id` on a citizen profile (the seeder
  sets `aisyah@tampalpintar.demo`'s to `DEMO-CAM-01`, matching the default
  here - change both together if you use a different profile).
- `SUPABASE_URL` / `SUPABASE_ANON_KEY`: your project ref and anon key from
  step 3, the same values as everywhere else in this section.

### 11.4 Power supply and programmer - pick one

The AI-Thinker ESP32-CAM has no built-in USB port and no built-in voltage
regulator good enough to run the camera stably from some 5V sources, so it
needs a separate board to supply power and expose a USB-serial connection
for flashing. Two options:

**Option A - ESP32-CAM Mother Board / programmer board (recommended)**

A small breakout board (commonly sold as "ESP32-CAM-MB" or "ESP32-CAM
Programmer") that the ESP32-CAM plugs straight into. It supplies power over
USB and handles the UART wiring + auto-reset for you - no jumper wires, no
separate power supply, no manually toggling IO0.

1. Seat the ESP32-CAM onto the mother board's pin headers (orientation
   matters - match the silkscreen markers on your specific board; the camera
   usually faces away from the USB connector).
2. Connect the mother board to your computer with a Micro-USB cable. This
   powers the board and exposes it as a serial port at the same time.
3. Windows needs a USB-to-serial driver for the chip your mother board uses
   (usually CH340 or CP2102) - Windows Update normally installs it
   automatically the first time you plug it in; if the board does not appear
   under **Tools → Port**, search for "<CH340 or CP2102> driver" for your OS.
4. Most mother boards auto-reset into bootloader mode when you click
   **Upload** (no button press needed). If the upload times out on
   "Connecting...", check your specific board's markings for a **RESET** or
   **BOOT** button and hold it briefly as the IDE starts uploading.
5. No separate power adapter is needed - the USB port supplies it, both for
   flashing and for normal operation as long as it stays plugged into a USB
   power source (a phone charger + cable works fine once you are done
   flashing and just want it running as a dashcam).

**Option B - external power + FTDI/USB-TTL adapter**

If you do not have a mother board, wire a regular FTDI/USB-TTL adapter
directly to the ESP32-CAM pins (the board is 5V logic tolerant, or use a
3.3V adapter):

| ESP32-CAM | Adapter |
|---|---|
| 5V | 5V (or the 3.3V pin if using a 3.3V adapter to the board's 3.3V rail - check your specific board's documentation) |
| GND | GND |
| U0R (RX) | TX |
| U0T (TX) | RX |
| IO0 | GND (**only while flashing** - this puts the chip into bootloader mode) |

To flash: connect IO0 to GND, press the board's **RESET** button (or power
cycle it), then upload from the IDE. After a successful upload, disconnect
IO0 from GND and reset again to run the sketch normally. To run it afterwards
(not just flash) you also need a separate stable 5V power source to the same
5V/GND pins, since the adapter alone typically cannot supply enough current
for the camera long term.

### 11.5 Select the board and port, then compile/upload

1. **Tools → Board → esp32 → AI Thinker ESP32-CAM**.
2. **Tools → Port** → select the COM port your mother board or adapter
   shows up as.
3. **Tools → Partition Scheme** → pick one with enough app space, e.g.
   *"Huge APP (3MB No OTA/1MB SPIFFS)"* - the default scheme is sometimes
   too small for the camera + TLS stack.
4. Click **Upload** (or **Verify** first to just check that it compiles).

Or, headless, using the CLI:

```
arduino-cli core install esp32:esp32
arduino-cli compile --fqbn esp32:esp32:esp32cam firmware/tampal_pintar_cam
arduino-cli upload -p <COM_PORT> --fqbn esp32:esp32:esp32cam firmware/tampal_pintar_cam
```

### 11.6 First boot

Open the IDE's **Serial Monitor** (baud 115200) after a normal boot/reset
(not while held in bootloader mode - if you used Option B's IO0-to-GND
trick, disconnect it first). You should see it join the hotspot, sync NTP
time, clean up any leftover photos from a previous run, then start streaming
`Streaming photos to Supabase Storage...`. In the citizen app, starting a
drive should show *"Dashcam disambungkan"* (dashcam connected) as soon as
the ESP32 is uploading.

---

## 12. Running the tests

### 12.1 Backend integration tests ("Seam 1")

These run against **your live hosted Supabase project** with the demo data
seeded - they are integration tests, not isolated/mocked unit tests.

1. Create `tools/backend_tests/test_config.json` (git-ignored - you create
   this file yourself, it does not ship with the repo):
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
   dart test                                  # the whole suite
   dart test test/submit_report_test.dart     # a single file
   ```

### 12.2 App logic tests ("Seam 2")

```
cd app
flutter test --concurrency=1
```

### 12.3 Wake word maths parity check

Verifies that the Dart reimplementation of the wake word ONNX pipeline
agrees with the reference Python chain.

```
pip install onnxruntime numpy
cd tools\wakeword_check
python check.py            # synthetic audio
python check.py drive.wav  # or a real recording of the phrase, 16 kHz mono 16-bit
```

---

## 13. Demo-day switch: `FAKE_EXTERNALS`

The backend test suite (12.1) needs **fake** externals - deterministic
stand-ins for Gemini/Weather/Geocoding, so the tests are not flaky and do not
hit rate limits. An actual live demo (or just seeing real Gemini risk scores)
needs the **real** integrations. Only one can be true at a time:

```
supabase secrets unset FAKE_EXTERNALS     # before a live demo
supabase secrets set FAKE_EXTERNALS=1     # before running the test suite again
```

Leaving it in the wrong state breaks whichever use case you are not doing, so
toggle it deliberately each time you switch context.

---

## 14. Manual end-to-end demo checklist

Once the backend is deployed, data seeded, `FAKE_EXTERNALS` unset, and both
the app and website configured with your keys:

1. The 3D map of Selangor renders with the seeded red pins (app + website);
   tapping a pin opens details with a Risk Score, road type · authority, and
   an "Open for" duration ticking live.
2. A pedestrian photo report submits instantly; a second report within 10 m
   of it is rejected with a clear duplicate report message.
3. On the app: **Start Driving** → background/close the app → say
   **"Tampal Pintar"** (detection threshold 0.28, recall ≈ 57%, so repeat the
   phrase if it misses the first time) → a **"Lubang Jalan Direkodkan!"**
   (pothole recorded) notification appears.
4. With the ESP32-CAM powered on and joined to the phone's hotspot: the app
   shows *Dashcam disambungkan*; the wake word retains 7 photos (the
   "instant" photo is framed in red in the draft preview); power-cycling the
   ESP32 only deletes its own `live/` leftovers, never saved report photos.
5. In **Pending**: the preview strip, three skippable one-tap follow-up
   questions (Vehicle pre-selected from *My Vehicles*), then **Submit** → the
   pin appears on the map and gets an AI score (all 7 photos are sent to
   Gemini; a score ≥ 80 auto-assigns it to the authority).
6. On the website, each government role sees only its own pins; the pin
   slideshow feels like dashcam footage; **Assign** (one-way - the dialog
   names the authority) → **Resolve** turns it green → confirmation makes the
   pin disappear everywhere; the reporter's points jump by the Risk Score;
   both leaderboards update.
7. **Rewards**: redeem a voucher (server-verified), the code lands in *My
   Vouchers*; Top Reporter standings are unaffected by spending points.

---

## 15. Troubleshooting

- **`supabase db push` appears to skip migrations** - you almost certainly
  forgot `--include-all`. Re-run with it.
- **Reports never get a risk score / stuck on `risk_score IS NULL`** - you
  most likely pushed the migrations before editing
  `supabase/migrations/20260709000008_analyze_webhook.sql` (step 7.3). Edit it
  with your real project ref + anon key and run
  `supabase db push --include-all` again.
- **The map renders blank / JS errors in the browser console** - an invalid
  or unrestricted-but-unbilled Google Maps key fails **silently** in this
  page's alpha `maps3d` loader. Double-check: the key is pasted correctly in
  all three copies of `map.html` (7.4), the Maps JavaScript API is enabled on
  that Cloud project, and billing is enabled on that Cloud project.
- **Backend tests fail with auth/network errors** - check the
  `tools/backend_tests/test_config.json` values against your project's
  current API keys (Settings → API Keys can rotate), and verify
  `FAKE_EXTERNALS=1` is set as a secret.
- **`flutter doctor` complains about Android licences** - run
  `flutter doctor --android-licenses` and accept them.
- **The ESP32-CAM will not flash** - if using Option B (FTDI adapter),
  verify IO0 is tied to GND *only* during upload; if using Option A (mother
  board), try holding its RESET/BOOT button while the IDE shows
  "Connecting...". Either way, confirm you picked the right COM port and the
  *AI Thinker ESP32-CAM* board variant specifically (other ESP32-CAM variants
  have different pin maps).

---

## Architecture note: no sharing

There is no shared Dart package between `app/` and `website/` - the model
definitions are duplicated between them on purpose (a deliberate product
decision, not an oversight). Keep both sides consistent separately rather
than trying to extract a shared package.
