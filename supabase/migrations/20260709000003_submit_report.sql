create or replace function public.submit_report(
  p_lat double precision,
  p_lng double precision,
  p_source public.report_source,
  p_speed_kmh double precision default null,
  p_captured_at timestamptz default null,
  p_media_paths text[] default '{}',
  p_immediate_index integer default null,
  p_vehicle_type public.vehicle_type default null,
  p_lane_position public.lane_position default null,
  p_impact_severity public.impact_severity default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_id uuid;
begin
  if auth.uid() is null or public.caller_role() is distinct from 'citizen' then
    raise exception 'only_citizens_can_submit' using errcode = '42501';
  end if;
  if exists (
    select 1 from public.reports r
    where r.status = 'active'
      and public.haversine_m(p_lat, p_lng, r.lat, r.lng) < 10
  ) then
    raise exception 'duplicate_within_10m';
  end if;
  insert into public.reports (
    reporter, lat, lng, speed_kmh, source, captured_at,
    media_paths, immediate_index, vehicle_type, lane_position, impact_severity)
  values (
    auth.uid(), p_lat, p_lng, p_speed_kmh, p_source, p_captured_at,
    coalesce(p_media_paths, '{}'), p_immediate_index,
    p_vehicle_type, p_lane_position, p_impact_severity)
  returning id into v_id;
  return v_id;
end $$;

revoke all on function public.submit_report(double precision,double precision,public.report_source,double precision,timestamptz,text[],integer,public.vehicle_type,public.lane_position,public.impact_severity) from public, anon;
grant execute on function public.submit_report(double precision,double precision,public.report_source,double precision,timestamptz,text[],integer,public.vehicle_type,public.lane_position,public.impact_severity) to authenticated;
