-- Read-only version of the 0004 trigger's check, callable from the edge
-- function as a cheap pre-check before it spends a Gemini call. The trigger
-- remains the authoritative backstop -- this just avoids the AI round trip
-- for the common case of an obvious duplicate.
create or replace function pothole_within_10m(p_lat double precision, p_lng double precision) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from potholes
    where status <> 'fixed'
      and earth_distance(ll_to_earth(lat, lng), ll_to_earth(p_lat, p_lng)) < 10
  );
$$;

grant execute on function pothole_within_10m(double precision, double precision) to authenticated;
