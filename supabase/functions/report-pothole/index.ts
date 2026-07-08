// Feature Zero submission endpoint: does the duplicate check, photo upload,
// AI risk scoring, and the potholes INSERT itself, in that order, so a
// failure at any step leaves nothing half-written (see HACKATHON.md plan --
// "the edge function is the submission endpoint, not a post-insert hook").
import { createClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY")!;
const GOOGLE_MAPS_API_KEY = Deno.env.get("GOOGLE_MAPS_API_KEY")!;

const GEMINI_MODEL = "gemini-2.5-flash";
const AUTO_ASSIGN_THRESHOLD = 80;

// 1:1 with the DB's `road_type` -> `assigned_role` pairing (potholes table
// check constraint mirrors this same mapping).
const ROAD_TYPE_TO_ROLE: Record<string, string> = {
  highway_expressway: "highway_concessionaire",
  federal_route: "jkr_malaysia",
  state_route: "jkr_selangor",
  municipal_local: "local_council",
};

const ROAD_AUTHORITY_GUIDE = `
Federal Route (simple numeric routes, e.g. "Federal Route 1/2/5") -> JKR Malaysia.
State Road (prefixed "B" + numbers, e.g. "B15") -> JKR Selangor.
Local Council / residential / urban road -> Local Council.
Expressway (e.g. NKVE, NSE, ELITE, LDP, KESAS, SPRINT, SUKE, DASH) -> Highway Concessionaire.
If the road cannot be confidently recognised, classify as municipal_local.
`.trim();

function corsHeaders() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, content-type",
  };
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders() },
  });
}

function base64ToBytes(b64: string): Uint8Array {
  const bin = atob(b64);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes;
}

// Free, no-API-call proxy for night lighting: Malaysia sits near the
// equator so sunrise/sunset barely shift across the year -- a fixed
// 07:00-19:00 MYT (UTC+8) window is accurate enough for a risk subscore.
function nightSubscore(): number {
  const mytHour = (new Date().getUTCHours() + 8) % 24;
  return mytHour < 7 || mytHour >= 19 ? 100 : 0;
}

async function reverseGeocode(lat: number, lng: number): Promise<string> {
  try {
    const res = await fetch(
      `https://geocode.googleapis.com/v4/geocode/location/${lat},${lng}?key=${GOOGLE_MAPS_API_KEY}`,
    );
    const json = await res.json();
    return json?.results?.[0]?.formattedAddress ?? "Unknown road, Selangor";
  } catch {
    return "Unknown road, Selangor";
  }
}

// Returns a 0-100 rainfall subscore. precipitation.probability.percent is
// already 0-100, so it's used directly rather than re-scaled.
async function rainfallSubscore(lat: number, lng: number): Promise<number> {
  try {
    const res = await fetch(
      `https://weather.googleapis.com/v1/currentConditions:lookup?key=${GOOGLE_MAPS_API_KEY}&location.latitude=${lat}&location.longitude=${lng}`,
    );
    const json = await res.json();
    return json?.precipitation?.probability?.percent ?? 0;
  } catch {
    return 0;
  }
}

async function classifyWithGemini(
  photoBytes: Uint8Array,
  address: string,
): Promise<{ depthSubscore: number; roadType: string; rationale: string }> {
  const prompt = `You are assessing a citizen-submitted pothole report photo for a Selangor, Malaysia road authority.

Reverse-geocoded address of the report: "${address}"

Selangor road authority guide:
${ROAD_AUTHORITY_GUIDE}

From the photo, estimate:
1. depth_subscore: 0-100, how severe/deep the pothole looks (0 = cosmetic surface crack, 100 = severe deep hazard).
2. road_type: exactly one of highway_expressway, federal_route, state_route, municipal_local -- infer from the address text against the guide above.
3. rationale: one sentence a government official could read to understand the depth estimate.`;

  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [
          {
            parts: [
              { text: prompt },
              { inline_data: { mime_type: "image/jpeg", data: btoa(String.fromCharCode(...photoBytes)) } },
            ],
          },
        ],
        generationConfig: {
          responseMimeType: "application/json",
          responseSchema: {
            type: "OBJECT",
            properties: {
              depth_subscore: { type: "NUMBER" },
              road_type: {
                type: "STRING",
                enum: ["highway_expressway", "federal_route", "state_route", "municipal_local"],
              },
              rationale: { type: "STRING" },
            },
            required: ["depth_subscore", "road_type", "rationale"],
          },
        },
      }),
    },
  );

  if (!res.ok) throw new Error(`Gemini request failed: ${res.status}`);
  const json = await res.json();
  const text = json?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text) throw new Error("Gemini returned no content");
  const parsed = JSON.parse(text);
  return {
    depthSubscore: parsed.depth_subscore,
    roadType: parsed.road_type,
    rationale: parsed.rationale,
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders() });
  if (req.method !== "POST") return jsonResponse({ error: "METHOD_NOT_ALLOWED" }, 405);

  const authHeader = req.headers.get("Authorization") ?? "";
  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user }, error: authError } = await userClient.auth.getUser();
  if (authError || !user) return jsonResponse({ error: "UNAUTHENTICATED" }, 401);

  const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  const { data: profile } = await admin.from("profiles").select("role").eq("id", user.id).single();
  if (profile?.role !== "citizen") return jsonResponse({ error: "FORBIDDEN" }, 403);

  const { photoBase64, lat, lng } = await req.json();
  if (typeof photoBase64 !== "string" || typeof lat !== "number" || typeof lng !== "number") {
    return jsonResponse({ error: "INVALID_INPUT" }, 400);
  }

  // Cheap pre-check before spending a Gemini call -- the DB trigger (0004,
  // 0008) is the authoritative backstop regardless of this result.
  const { data: isDuplicate } = await admin.rpc("pothole_within_10m", { p_lat: lat, p_lng: lng });
  if (isDuplicate) return jsonResponse({ error: "DUPLICATE_NEARBY" }, 409);

  const photoBytes = base64ToBytes(photoBase64);
  const photoPath = `${user.id}/${crypto.randomUUID()}.jpg`;
  const { error: uploadError } = await admin.storage
    .from("pothole-photos")
    .upload(photoPath, photoBytes, { contentType: "image/jpeg" });
  if (uploadError) return jsonResponse({ error: "UPLOAD_FAILED" }, 500);
  const { data: { publicUrl } } = admin.storage.from("pothole-photos").getPublicUrl(photoPath);

  const address = await reverseGeocode(lat, lng);

  let riskScore: number;
  let riskRationale: string;
  let roadType: string;
  try {
    const [rainfall, aiResult] = await Promise.all([
      rainfallSubscore(lat, lng),
      classifyWithGemini(photoBytes, address),
    ]);
    const night = nightSubscore();
    riskScore = Math.max(
      0,
      Math.min(100, Math.round(0.6 * aiResult.depthSubscore + 0.25 * rainfall + 0.15 * night)),
    );
    riskRationale = aiResult.rationale;
    roadType = aiResult.roadType in ROAD_TYPE_TO_ROLE ? aiResult.roadType : "municipal_local";
  } catch {
    // Losing a citizen's report to a third-party API hiccup is worse than a
    // mediocre default score -- see plan step 11.
    riskScore = 50;
    riskRationale = "AI scoring unavailable, default applied.";
    roadType = "municipal_local";
  }

  const assignedRole = ROAD_TYPE_TO_ROLE[roadType];
  const autoAssigned = riskScore >= AUTO_ASSIGN_THRESHOLD;

  const { data: inserted, error: insertError } = await admin
    .from("potholes")
    .insert({
      reporter_id: user.id,
      photo_url: publicUrl,
      lat,
      lng,
      status: autoAssigned ? "assigned" : "not_assigned",
      risk_score: riskScore,
      risk_rationale: riskRationale,
      road_type: roadType,
      assigned_role: assignedRole,
      assigned_at: autoAssigned ? new Date().toISOString() : null,
    })
    .select()
    .single();

  if (insertError) {
    if (insertError.message.includes("DUPLICATE_NEARBY")) {
      return jsonResponse({ error: "DUPLICATE_NEARBY" }, 409);
    }
    return jsonResponse({ error: "INSERT_FAILED", detail: insertError.message }, 500);
  }

  return jsonResponse(inserted, 201);
});
