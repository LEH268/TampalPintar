# HACKATHON.md: TampalPintar (Selangor pothole reporting)

<!-- Backfilled from the already-approved PRD in docs/TampalPintar_Guide.md
     (approved 2026-07-05, amended 2026-07-06). No judging rubric was given,
     so this skips rubric-weighted angle scoring and keeps to angle, phase
     plan, and scope cuts. Keep current if the team pivots or cuts scope. -->

## The one-liner

Citizens report potholes hands-free (photo, or voice while driving) with
GPS auto-attached; a backend AI scores each one 0-100 and routes it to the
correct Selangor road authority (JKR Malaysia, JKR Selangor, local council,
or highway concessionaire), who dispatch and close it out on a live map.

## Urgency hook

Drivers can't safely stop on high-speed or narrow Selangor roads to report a
pothole, so by the time it's safe to pull over the exact spot is already
lost — and even when a report reaches an official, they can't tell which of
four authorities owns that stretch of road, so it stalls. TampalPintar
removes both blockers: the pin drops the instant the driver says the wake
word, and routing to the correct authority is automatic.

## Judging rubric

Not provided. No rubric-weighted angle scoring below — the angle is already
locked in from the approved PRD, not being chosen against judging criteria.

## Angle decision

Single angle, already approved by the product owner (see
[docs/TampalPintar_Guide.md](docs/TampalPintar_Guide.md)) — no alternatives
were scored. Core loop: citizen reports (photo or voice) → AI scores risk
and assigns authority → official dispatches and closes → citizen earns
points. Gamification (points, leaderboards) and dashcam video are layered on
top of that core loop, not the loop itself — see Scope cuts.

## Phase plan (back-solved from submission 2026-07-15, 5-min pitch)

Dates instead of T+Nh: exact kickoff time-of-day and pitch slot on the 15th
weren't given.

| Checkpoint | Target date | Deliverable | Skill / command | Owner |
|---|---|---|---|---|
| Kickoff | 2026-07-08 | This file (spec already done pre-kickoff) | `/hackathon-kickoff` (backfilled) | all |
| Spec | done | Approved PRD, 88 user stories | docs/TampalPintar_Guide.md | product owner |
| **Feature Zero** | 2026-07-10 | One thin end-to-end slice: photo report → pin on map → AI risk score → official marks Assigned/Complete. Mock/seed data fine. Deployed. | | TBD |
| Core build | 2026-07-13 | Voice/Driving Mode, dashcam broadcast, follow-up questions, points/rewards, leaderboards | | TBD |
| QA + polish | 2026-07-14 (AM) | Bug pass across both apps; spacing/hierarchy pass | gstack `/qa`, `/design-review` | TBD |
| Deck | 2026-07-14 (PM) | Slides + narration script | `beautiful-hackathon-slides` or `pptx` | TBD |
| Pitch script | 2026-07-14 (PM) | `PITCH.md`, 5-min budget across 6 speakers | `/pitch-timebox` | TBD |
| Rehearsal x2 | 2026-07-15 (AM) | Both runs under 5:00 | | all |
| **Submission** | 2026-07-15 | Repo + deck + demo | | TBD |

## Team

6 members — names/roles not given yet, fill in before Core build starts.

| Name | Strengths | Owns (build) | Pitch section |
|---|---|---|---|
| TBD | | | |
| TBD | | | |
| TBD | | | |
| TBD | | | |
| TBD | | | |
| TBD | | | |

## Scope cuts (running log)

Ordered by what the PRD marks as extra layers on top of the core loop —
cut from the top first if behind at a checkpoint.

1. Dashcam video (ESP32-CAM streaming, clip slideshow) — core loop works on
   photo/GPS alone; dashcam is an enrichment.
2. Leaderboards (Top Reporters, Department Response) — cosmetic, no
   dependency from the rest of the app.
3. Points & rewards / voucher redemption — same, layered on top of the
   fix-completion flow, not required for it to work.
4. Post-drive follow-up questions (vehicle type, lane position, impact
   severity) — Risk Score already works from the 5 backend-only factors
   without them.
5. Voice/Driving Mode wake-word reporting — photo reporting alone proves
   the full loop (report → score → route → dispatch → complete); voice is
   the harder-to-demo-live half.
