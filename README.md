# TampalPintar

**Hands-free pothole reporting for Selangor, Malaysia** — citizens report road
potholes in one action (photo, or voice while driving), a backend AI scores
each one 0–100 and routes it to the correct road authority, and government
officials dispatch and close repairs on a shared live 3D map.

> **Status:** Feature Zero — one thin, end-to-end, demo-able slice of the full
> product is built and running against a live Supabase project. The voice /
> Driving Mode reporting, dashcam video, points & rewards, leaderboards, and
> post-drive follow-up questions from the full PRD are **deliberately deferred**
> (see [Scope](#scope--whats-in-feature-zero) below and the scope-cuts log in
> [`HACKATHON.md`](HACKATHON.md)).

---

## Why

Potholes in Selangor go unrepaired because reporting them is genuinely hard:

- **Drivers can't safely stop** on high-speed or narrow roads, so by the time
  it's safe to pull over, the exact coordinates are lost.
- **Nobody knows who owns the road.** Selangor roads are split across four
  different authorities (Federal JKR, State JKR, local councils, and expressway
  concessionaires) — a citizen has no way to know which one to report to, and a
  misrouted complaint stalls.
- **Officials get unstructured complaints** with no severity signal, making
  prioritization guesswork.

TampalPintar removes both blockers: the pin drops the instant a report is made,
and routing to the correct authority is fully automatic from the road type.

---

## Scope — what's in Feature Zero

The **core loop, end to end**, and nothing more:

| Included ✅ | Deferred ⏳ (see `HACKATHON.md`) |
|---|---|
| Citizen email/password auth | Voice / Driving Mode wake-word reporting |
| Photo report with auto-attached GPS | Dashcam (ESP32-CAM) video streaming |
| 10 m duplicate-report rejection | Post-drive follow-up questions |
| AI risk scoring (photo depth + rainfall + night) | Points, rewards & voucher redemption |
| AI road-type classification → authority routing | Leaderboards (Top Reporters, Dept Response) |
| Auto-assign when Risk Score ≥ 80 | "My Vehicle" profile setting |
| Shared 3D Selangor map, live-updating red pins | |
| Pin detail with live "Open for" timer | |
| Role-gated government dashboard (4 roles) | |
| One-way `Not Assigned → Assigned → Fixed` workflow | |

---

## Architecture

```
┌─────────────────────┐         ┌────────────────────────┐
│  mobile/  (Android) │         │   web/  (Flutter Web)  │
│  Citizen app        │         │  Government dashboard  │
│  • auth, camera+GPS │         │  • role-gated login    │
│  • 3D map (WebView) │         │  • 3D map (HtmlElement)│
│  • report → pin     │         │  • Assign / Complete   │
└──────────┬──────────┘         └───────────┬────────────┘
           │                                │
           │   supabase_flutter (auth, Realtime, RPC, Functions)
           │                                │
           └───────────────┬────────────────┘
                           ▼
              ┌──────────────────────────────┐
              │        Supabase              │
              │  • Postgres + RLS            │
              │  • Realtime (Postgres CDC)   │
              │  • Storage (pothole photos)  │
              │  • Edge Function:            │
              │    report-pothole ───────────┼──▶ Gemini (vision)
              │                              │──▶ Google Geocoding v4
              │                              │──▶ Google Weather API
              └──────────────────────────────┘
```

**Key design decisions** (rationale in
[`.claude/plans/…`](HACKATHON.md) / migration comments):

- **The Edge Function *is* the submission endpoint**, not a post-insert DB hook.
  The client sends `{photo, lat, lng}`; the function does the duplicate check,
  photo upload, AI scoring, and the `INSERT` itself — so a failure at any step
  leaves nothing half-written, and there's never an "unscored" pin on the map.
- **Single `potholes` table, no separate reports/history table.** A fixed pothole
  simply stops matching the active-pins filter; a later report at the same spot
  is a brand-new row. This makes "a fixed location becomes reportable again"
  fall out for free.
- **3D map is one shared HTML/JS approach on both platforms** — Google's
  `<gmp-map-3d>` web component, embedded in an Android `WebView` and a Flutter
  Web `HtmlElementView`. (The native Android Maps 3D SDK is rejected — it isn't
  compatible with the Maps Demo Key.)
- **Two independent Flutter projects, not a shared package.** Some model code is
  duplicated between `mobile/` and `web/` by design, per the PRD's project
  layout — not worth a shared package at this size.

---

## Repository layout

```
TampalPintar/
├── README.md                 ← you are here
├── HACKATHON.md              ← angle, phase plan, scope-cuts log
├── docs/
│   └── TampalPintar_Guide.md ← full PRD: 88 user stories + API reference
├── mobile/                   ← Flutter citizen app (Android only)
│   └── lib/
│       ├── main.dart               auth gate
│       ├── supabase_config.dart    project URL + publishable key + Maps key
│       ├── models/pothole.dart
│       ├── map/
│       │   ├── map_html.dart        gmp-map-3d bootstrap + marker bridge
│       │   └── js_map_webview.dart  WebView wrapper + FlutterBridge channel
│       └── screens/                 login, map, pothole detail sheet
├── web/                      ← Flutter government dashboard (Flutter Web)
│   └── lib/
│       ├── main.dart
│       ├── map/js_map_web.dart      HtmlElementView + dart:js_interop bridge
│       └── screens/                 login (role-gated), dashboard, detail panel
│   └── web/index.html               map bootstrap + global pin JS lives here
└── supabase/
    ├── migrations/           ← 0001–0009, schema/RLS/triggers/RPCs
    ├── functions/
    │   └── report-pothole/index.ts   AI scoring + routing + insert
    ├── seed.sql              ← 4 gov accounts + 1 citizen + 10 potholes
    └── smoke_test.sql        ← asserts the 10m + status guards (rolls back)
```

---

## Data model

**`profiles`** — one row per auth user, created by a trigger on signup.

| column | type | notes |
|---|---|---|
| `id` | uuid PK | → `auth.users` |
| `role` | `user_role` enum | `citizen` \| `jkr_malaysia` \| `jkr_selangor` \| `local_council` \| `highway_concessionaire` |

**`potholes`** — every AI-derived column is `NOT NULL` because the Edge
Function computes them before the row is inserted.

| column | type | notes |
|---|---|---|
| `id` | uuid PK | |
| `reporter_id` | uuid | → `profiles` |
| `photo_url` | text | public Storage URL |
| `lat`, `lng` | double | |
| `status` | `pothole_status` | `not_assigned` → `assigned` → `fixed` |
| `risk_score` | smallint | 0–100 |
| `risk_rationale` | text | one-line AI justification |
| `road_type` | `road_type` | `highway_expressway` \| `federal_route` \| `state_route` \| `municipal_local` |
| `assigned_role` | `user_role` | 1:1 from `road_type` |
| `reported_at` / `assigned_at` / `fixed_at` | timestamptz | powers the "Open for" timer |

**Road type → authority mapping** (1:1, enforced in both the Edge Function and
the DB):

| Road type | Authority |
|---|---|
| Expressway | Highway Concessionaire (PLUS, PROLINTAS, LITRAK…) |
| Federal Route | JKR Malaysia |
| State Route | JKR Selangor |
| Municipal / Local | Local Council (MBSA, MBPJ…) — also the fallback for unrecognized roads |

### Server-side guarantees (RLS, triggers, RPCs)

- **Row-Level Security**: a citizen sees all active potholes; an official sees
  only potholes routed to their role. Inserts happen *only* via the Edge
  Function's service-role client; status transitions *only* via the two RPCs.
- **10 m duplicate rule**: enforced by a `BEFORE INSERT` trigger
  (`earthdistance`), so no insert path can bypass it. The Edge Function also
  pre-checks it to fail fast before spending a Gemini call.
- **`assign_pothole(id)`** / **`mark_pothole_fixed(id)`**: `SECURITY DEFINER`
  RPCs that lock the row, re-check the caller's role and current status
  server-side, and perform the one-way transition atomically. `mark_pothole_fixed`
  rejects any pothole that isn't currently `assigned` — so completion can't skip
  dispatch and can't run twice.

---

## Risk scoring

The full PRD scores on up to 8 factors. Feature Zero is photo-only (no driver
telemetry), so it uses the 3 factors realistically available and computes the
score **deterministically in TypeScript** (the LLM only estimates depth and
classifies the road — it never does the arithmetic):

```
risk_score = round( 0.60 × depth      (Gemini vision, 0–100)
                  + 0.25 × rainfall    (Google Weather precip probability %)
                  + 0.15 × night )     (server clock vs. fixed MYT day window)
```

If Gemini or the weather API errors or times out, the report is **not lost** — it
falls back to `risk_score = 50` with a rationale noting AI was unavailable.

---

## Setup

### Prerequisites

- Flutter 3.44+ / Dart 3.12+
- A Supabase project (one already exists for this build — ref
  `wtwxrsegjnbtsazdwsje`)
- Node / `npx` (for the Supabase CLI; no global install needed)
- A fresh **Gemini API key** (Google AI Studio) and the **Google Maps Demo Key**

### 1. Backend

The 9 migrations and seed data are already applied to the hosted project. To
reproduce on a fresh project:

```bash
npx supabase login
npx supabase link --project-ref <your-project-ref>
npx supabase db push                       # applies migrations/0001–0009
psql "<your-db-connection-string>" -f supabase/seed.sql
npx supabase functions deploy report-pothole
```

**Set the Edge Function secrets** (⚠️ required — the function returns the AI
fallback until these exist; generate a *new* Gemini key, the one in the PRD is
flagged leaked):

```bash
npx supabase secrets set \
  GEMINI_API_KEY=<your-fresh-gemini-key> \
  GOOGLE_MAPS_API_KEY=AIzaSyAWRhrGlvOUJoWT3tmp1BJxRYwON5t-UIA
```

### 2. Mobile app (citizen)

```bash
cd mobile
flutter pub get
flutter run -d <android-device-or-emulator>
```

The Google Maps Demo Key is read from `android/local.properties`
(`MAPS_API_KEY=…`, gitignored) via the secrets-gradle-plugin. On an emulator,
set a mock GPS location in the extended controls — a report needs real
coordinates.

### 3. Government dashboard

```bash
cd web
flutter pub get
flutter run -d chrome
```

Log in with a seeded role account (all share password **`Demo1234!`**):

| Email | Role |
|---|---|
| `jkr-malaysia@tampalpintar.demo` | JKR Malaysia |
| `jkr-selangor@tampalpintar.demo` | JKR Selangor |
| `local-council@tampalpintar.demo` | Local Council |
| `highway-concessionaire@tampalpintar.demo` | Highway Concessionaire |
| `demo-citizen@tampalpintar.demo` | Citizen (rejected at the dashboard login) |

---

## Verifying it works

**DB guard smoke test** (asserts the 10 m rule and the completion guard, then
rolls back — leaves no rows behind):

```bash
psql "<your-db-connection-string>" -f supabase/smoke_test.sql
# expect two "PASS:" notices
```

**Flutter checks**:

```bash
cd mobile && flutter analyze && flutter test
cd web    && flutter analyze && flutter test && flutter build web
```

**Golden path (manual, ~2 min)**: sign up a citizen on mobile → Report → capture
a photo → a new red pin appears live → tap it, confirm the ticking "Open for"
timer / Risk Score / rationale / road type / authority → report again within
10 m → confirm the "already reported" message → log into the web dashboard as
the matching role → confirm the pin shows there and is absent for a different
role → Assign → Complete → the pin disappears from **both** apps in the same
live session.

---

## Demo accounts & seed data

The seed provisions 4 government accounts + 1 demo citizen, and 10 potholes
spread across Shah Alam, Petaling Jaya, Klang, Kajang, a federal route and an
expressway stretch — with varied risk scores, all 4 road types, a couple
already auto-assigned (Risk ≥ 80), and a couple already fixed (so the
"disappears from the map" behavior is visible without a live click).

---

## Tech stack

| Layer | Choice |
|---|---|
| Mobile & Web | Flutter (Android + Web) |
| Client SDK | `supabase_flutter` (auth, Realtime, Storage, Functions) |
| Camera / GPS | `image_picker`, `geolocator` |
| Map | Google Maps JS API `<gmp-map-3d>` via `webview_flutter` (Android) / `HtmlElementView` + `dart:js_interop` (Web) |
| Backend | Supabase — Postgres + RLS + Realtime + Storage + Edge Functions (Deno) |
| AI | Gemini (`gemini-2.5-flash`, vision) via an Edge Function |
| Geo/Weather | Google Geocoding v4 + Weather API (server-side, Demo Key) |

---

## Roadmap (post–Feature Zero)

Restore the deferred layers, cutting from the top only if behind schedule:

1. Voice / Driving Mode wake-word reporting (Porcupine, offline draft queue)
2. Dashcam (ESP32-CAM) frame streaming over Supabase Realtime Broadcast
3. Points & rewards ledger (adds one row to the existing `mark_pothole_fixed`
   RPC — it's still one atomic operation)
4. Leaderboards (Top Reporters, Department Response times)
5. Post-drive follow-up questions → richer 8-factor risk score