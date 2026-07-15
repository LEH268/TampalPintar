import { createClient } from "npm:@supabase/supabase-js@2";

const GEMINI_MODEL = "gemini-2.5-flash";
const ROAD_TYPES = [
  "highway_expressway",
  "federal_route",
  "state_route",
  "municipal_local",
] as const;
const AUTHORITY: Record<string, [string, string]> = {
  highway_expressway: ["highway", "LITRAK"],
  federal_route: ["jkr_malaysia", "JKR Malaysia"],
  state_route: ["jkr_selangor", "JKR Selangor"],
  municipal_local: ["local_council", "Majlis Bandaraya Shah Alam (MBSA)"],
};

const COUNCILS = `Shah Alam=Majlis Bandaraya Shah Alam (MBSA); Petaling Jaya=Majlis Bandaraya Petaling Jaya (MBPJ); Subang Jaya=Majlis Bandaraya Subang Jaya (MBSJ); Klang=Majlis Bandaraya Diraja Klang (MBDK); Ampang=Majlis Perbandaran Ampang Jaya (MPAJ); Kajang=Majlis Perbandaran Kajang (MPKj); Sepang=Majlis Perbandaran Sepang (MPSepang); Selayang=Majlis Perbandaran Selayang (MPS); Kuala Langat=Majlis Perbandaran Kuala Langat (MPKL); Kuala Selangor=Majlis Perbandaran Kuala Selangor (MPKS); Hulu Selangor=Majlis Perbandaran Hulu Selangor (MPHS); Sabak Bernam=Majlis Daerah Sabak Bernam (MDSB)`;

const CONCESSIONAIRES = `NKVE/NSE/ELITE=PLUS Malaysia Berhad; GCE/LKSA/SILK/AKLEH/DASH/SUKE=PROLINTAS; LDP=LITRAK; KESAS=KESAS Sdn Bhd; SPRINT=Sistem Penyuraian Trafik KL Barat; NPE/BESRAYA/LEKAS=IJM Toll Division; WCE=West Coast Expressway Sdn Bhd; SKVE=SKVE Holdings; LATAR=KLSEB; CKE Cheras-Kajang=Grand Saga; KL-Karak=AFA Prime Berhad; MEX=Maju Expressway Sdn Bhd; NNKSB=Projek Jalan Pintas Selat Klang Utara`;

interface Analysis {
  risk_score: number;
  rationale: string;
  road_type: string;
  authority_role: string;
  authority_name: string;
  depth_estimate?: string;
  factors: { name: string; level: string; note?: string }[];
}

function isNightInKL(): boolean {
  const kl = new Intl.DateTimeFormat("en-GB", {
    timeZone: "Asia/Kuala_Lumpur",
    hour: "numeric",
    minute: "numeric",
    hour12: false,
  }).formatToParts(new Date());
  const h = Number(kl.find((p) => p.type === "hour")!.value);
  const m = Number(kl.find((p) => p.type === "minute")!.value);
  return h > 19 || (h === 19 && m >= 30) || h < 7;
}

// deno-lint-ignore no-explicit-any
function fakeAnalysis(report: any): Analysis {
  const speed = report.speed_kmh ?? 30;
  const risk = Math.max(0, Math.min(100, Math.round(speed)));
  const idx = ((Math.round(report.lng * 10000) % 4) + 4) % 4;
  const road_type = ROAD_TYPES[idx];
  const [authority_role, authority_name] = AUTHORITY[road_type];
  const factors = [
    { name: "depth", level: "unknown" },
    { name: "speed", level: `${speed} km/h` },
    { name: "lighting", level: isNightInKL() ? "night" : "day" },
    { name: "rainfall", level: "none (fake)" },
    { name: "traffic", level: road_type },
  ];
  for (const k of ["vehicle_type", "lane_position", "impact_severity"]) {
    if (report[k] != null) factors.push({ name: k, level: String(report[k]) });
  }
  return {
    risk_score: risk,
    rationale: `FAKE: score derived from speed ${speed} km/h for testing`,
    road_type,
    authority_role,
    authority_name,
    factors,
  };
}

async function fetchWeather(lat: number, lng: number, key: string) {
  const u = new URL("https://weather.googleapis.com/v1/currentConditions:lookup");
  u.searchParams.set("key", key);
  u.searchParams.set("location.latitude", String(lat));
  u.searchParams.set("location.longitude", String(lng));
  const res = await fetch(u);
  if (!res.ok) throw new Error(`weather ${res.status}`);
  const j = await res.json();
  return {
    condition: j?.weatherCondition?.description?.text ?? "unknown",
    precipProbabilityPct: j?.precipitation?.probability?.percent ?? null,
    precipQpfMm: j?.precipitation?.qpf?.quantity ?? null,
  };
}

async function fetchRoad(lat: number, lng: number, key: string) {
  const res = await fetch(
    `https://geocode.googleapis.com/v4/geocode/location/${lat},${lng}?key=${key}`,
  );
  if (!res.ok) throw new Error(`geocode ${res.status}`);
  const j = await res.json();
  const results = j?.results ?? [];
  const routes: string[] = [];
  let locality = "";
  let formatted = "";
  for (const r of results.slice(0, 3)) {
    formatted ||= r.formattedAddress ?? "";
    for (const c of r.addressComponents ?? []) {
      const types: string[] = c.types ?? [];
      if (types.includes("route") && c.longText) routes.push(c.longText);
      if (types.includes("locality") && c.longText) locality ||= c.longText;
    }
  }
  return { routes: [...new Set(routes)], locality, formatted };
}

async function callGemini(
  apiKey: string,
  prompt: string,
  photosB64: string[],
): Promise<Analysis> {
  const parts: unknown[] = [{ text: prompt }];
  for (const b64 of photosB64) {
    parts.push({ inlineData: { mimeType: "image/jpeg", data: b64 } });
  }
  const body = {
    contents: [{ role: "user", parts }],
    generationConfig: {
      temperature: 0.2,
      responseMimeType: "application/json",
      responseSchema: {
        type: "OBJECT",
        properties: {
          depth_estimate: { type: "STRING" },
          risk_score: { type: "INTEGER" },
          rationale: { type: "STRING" },
          road_type: { type: "STRING", enum: [...ROAD_TYPES] },
          authority_role: {
            type: "STRING",
            enum: ["highway", "jkr_malaysia", "jkr_selangor", "local_council"],
          },
          authority_name: { type: "STRING" },
          factors: {
            type: "ARRAY",
            items: {
              type: "OBJECT",
              properties: {
                name: { type: "STRING" },
                level: { type: "STRING" },
                note: { type: "STRING" },
              },
              required: ["name", "level"],
            },
          },
        },
        required: [
          "risk_score", "rationale", "road_type",
          "authority_role", "authority_name", "factors",
        ],
      },
    },
  };
  let lastErr: unknown;
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      const res = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${apiKey}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(body),
        },
      );
      if (!res.ok) throw new Error(`gemini ${res.status}: ${await res.text()}`);
      const j = await res.json();
      const text = j?.candidates?.[0]?.content?.parts?.[0]?.text;
      if (!text) throw new Error("gemini returned no text");
      const parsed = JSON.parse(text) as Analysis;
      parsed.risk_score = Math.max(0, Math.min(100, Math.round(parsed.risk_score)));
      if (!ROAD_TYPES.includes(parsed.road_type as typeof ROAD_TYPES[number])) {
        parsed.road_type = "municipal_local";
      }
      // enforce the fixed 1:1 mapping regardless of what the model said
      parsed.authority_role = AUTHORITY[parsed.road_type][0];
      // federal/state names are fixed; highway/municipal keep the model's specific
      // concessionaire/council (falling back to the default only when empty)
      const FIXED_AUTHORITY_NAME: Record<string, string> = {
        federal_route: "JKR Malaysia",
        state_route: "JKR Selangor",
      };
      if (FIXED_AUTHORITY_NAME[parsed.road_type]) {
        parsed.authority_name = FIXED_AUTHORITY_NAME[parsed.road_type];
      } else if (!parsed.authority_name) {
        parsed.authority_name = AUTHORITY[parsed.road_type][1];
      }
      return parsed;
    } catch (e) {
      lastErr = e;
      await new Promise((r) => setTimeout(r, 1500 * (attempt + 1)));
    }
  }
  throw lastErr;
}

Deno.serve(async (req) => {
  let reportId: unknown;
  try {
    ({ report_id: reportId } = await req.json());
  } catch {
    return Response.json({ error: "invalid JSON" }, { status: 400 });
  }
  if (typeof reportId !== "string") {
    return Response.json({ error: "report_id required" }, { status: 400 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { data: report, error } = await supabase
    .from("reports").select("*").eq("id", reportId).single();
  if (error || !report) {
    return Response.json({ error: "report not found" }, { status: 404 });
  }
  if (report.risk_score !== null) {
    return Response.json({ ok: true, skipped: "already scored" });
  }

  const fake = Deno.env.get("FAKE_EXTERNALS") === "1";
  let analysis: Analysis;

  if (fake) {
    analysis = fakeAnalysis(report);
  } else {
    const mapsKey = Deno.env.get("GOOGLE_MAPS_KEY")!;
    const geminiKey = Deno.env.get("GEMINI_API_KEY")!;

    let weather = null;
    try { weather = await fetchWeather(report.lat, report.lng, mapsKey); } catch (_) { /* degrade */ }
    let road = null;
    try { road = await fetchRoad(report.lat, report.lng, mapsKey); } catch (_) { /* degrade */ }

    const photosB64: string[] = [];
    for (const path of (report.media_paths ?? []).slice(0, 7)) {
      try {
        const { data } = await supabase.storage.from("media").download(path);
        if (data) {
          const buf = new Uint8Array(await data.arrayBuffer());
          let bin = "";
          for (let i = 0; i < buf.length; i += 0x8000) {
            bin += String.fromCharCode(...buf.subarray(i, i + 0x8000));
          }
          photosB64.push(btoa(bin));
        }
      } catch (_) { /* skip missing photo */ }
    }

    const answers = [
      report.vehicle_type ? `vehicle_type=${report.vehicle_type}` : null,
      report.lane_position ? `lane_position=${report.lane_position}` : null,
      report.impact_severity ? `impact_severity=${report.impact_severity}` : null,
    ].filter(Boolean).join(", ") || "none (driver skipped all questions)";

    const prompt =
`You are the risk-analysis engine for TampalPintar, a pothole reporting system for Selangor, Malaysia. Return ONLY the JSON matching the response schema.

REPORT SIGNALS
- Vehicle speed when reported: ${report.speed_kmh ?? "unknown"} km/h
- Time context: ${isNightInKL() ? "night (poor lighting likely)" : "daytime"}
- Weather at the pin: ${weather ? `${weather.condition}, precipitation probability ${weather.precipProbabilityPct ?? "?"}%, qpf ${weather.precipQpfMm ?? "?"} mm` : "unavailable (mark rainfall factor unknown)"}
- Reverse-geocoded road data: ${road ? `routes=[${road.routes.join("; ")}], locality=${road.locality || "?"}, address=${road.formatted}` : "unavailable (classify as municipal_local)"}
- Driver-reported context (absent = driver skipped; NEVER assume a default): ${answers}
- ${photosB64.length} image(s) follow in chronological order${photosB64.length > 0 && report.immediate_index != null ? `; image #${report.immediate_index + 1} is the exact report moment` : ""}. If none, set depth_estimate to "unknown".

TASKS
1. Estimate pothole depth/severity from the images.
2. risk_score 0-100 weighing: depth, vehicle speed, night lighting, rainfall, traffic flow (infer from road class: expressway=high, local=low), PLUS vehicle_type / lane_position / impact_severity when present (motorcycle, fast lane, swerve, damage all push risk up).
3. rationale: ONE line an official can quote; mention driver-reported factors whenever they moved the score.
4. road_type: highway_expressway = tolled expressways / E-numbered / named highways (${CONCESSIONAIRES}); federal_route = Federal Routes (FT / 1-3 digit national route numbers); state_route = B-prefixed Selangor routes; municipal_local = residential/taman/local streets AND anything unrecognizable.
5. authority_role is FIXED by road_type: highway_expressway->highway, federal_route->jkr_malaysia, state_route->jkr_selangor, municipal_local->local_council.
6. authority_name: the specific concessionaire for expressways; "JKR Malaysia" for federal; "JKR Selangor" for state; for municipal pick the council from locality (${COUNCILS}); default MBSA when unsure.
7. factors: one entry per factor you actually used, names exactly: depth, speed, lighting, rainfall, traffic, vehicle_type, lane_position, impact_severity (driver factors only when present).`;

    try {
      analysis = await callGemini(geminiKey, prompt, photosB64);
    } catch (_) {
      return Response.json({ error: "analysis failed" }, { status: 502 });
    }
  }

  const { error: upError } = await supabase
    .from("reports")
    .update({
      risk_score: analysis.risk_score,
      factor_breakdown: analysis.factors,
      rationale: analysis.rationale,
      road_type: analysis.road_type,
      authority_role: analysis.authority_role,
      authority_name: analysis.authority_name,
      analyzed_at: new Date().toISOString(),
      ...(analysis.risk_score >= 80 ? { assigned: true } : {}),
    })
    .eq("id", reportId);
  if (upError) {
    return Response.json({ error: upError.message }, { status: 500 });
  }
  return Response.json({ ok: true, risk_score: analysis.risk_score });
});
