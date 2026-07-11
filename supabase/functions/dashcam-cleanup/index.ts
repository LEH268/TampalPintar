import { createClient } from "npm:@supabase/supabase-js@2";

Deno.serve(async (req) => {
  let dashcamId: unknown;
  try {
    ({ dashcam_id: dashcamId } = await req.json());
  } catch {
    return Response.json({ error: "invalid JSON" }, { status: 400 });
  }
  if (typeof dashcamId !== "string" || dashcamId.length === 0 ||
      dashcamId.includes("/") || dashcamId.includes("..")) {
    return Response.json({ error: "dashcam_id required" }, { status: 400 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const prefix = `live/${dashcamId}`;
  let deleted = 0;
  for (;;) {
    const { data: objects, error } = await supabase.storage
      .from("media")
      .list(prefix, { limit: 100 });
    if (error) {
      return Response.json({ error: error.message }, { status: 500 });
    }
    if (!objects || objects.length === 0) break;
    const paths = objects.map((o) => `${prefix}/${o.name}`);
    const { error: delError } = await supabase.storage
      .from("media")
      .remove(paths);
    if (delError) {
      return Response.json({ error: delError.message }, { status: 500 });
    }
    deleted += paths.length;
  }
  return Response.json({ deleted });
});
