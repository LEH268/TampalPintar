-- Smallest runnable check for the two non-trivial DB guards: the 10m
-- duplicate-report trigger and the mark_pothole_fixed status guard.
-- Plain SQL, no pgTAP -- everything runs inside one transaction that always
-- rolls back, so it never leaves test rows behind. Run with:
--   psql "$DATABASE_URL" -f supabase/smoke_test.sql
-- A clean run prints two "PASS:" notices and nothing else; any assertion
-- failure raises and aborts with "SMOKE TEST FAILED: ...".

begin;

insert into potholes (reporter_id, photo_url, lat, lng, status, risk_score, risk_rationale, road_type, assigned_role)
values ('00000000-0000-0000-0000-000000000001', 'test', 1.0, 1.0, 'not_assigned', 10, 'smoke test', 'municipal_local', 'local_council');

do $$
begin
  insert into potholes (reporter_id, photo_url, lat, lng, status, risk_score, risk_rationale, road_type, assigned_role)
  values ('00000000-0000-0000-0000-000000000001', 'test', 1.00001, 1.00001, 'not_assigned', 10, 'smoke test dup', 'municipal_local', 'local_council');
  raise exception 'SMOKE TEST FAILED: duplicate insert within 10m did not raise';
exception
  when sqlstate 'P0001' then
    if sqlerrm <> 'DUPLICATE_NEARBY' then
      raise exception 'SMOKE TEST FAILED: expected DUPLICATE_NEARBY, got %', sqlerrm;
    end if;
    raise notice 'PASS: duplicate-nearby trigger fired correctly';
end;
$$;

-- Impersonate the local_council official (matches assigned_role on the test
-- row) via the same JWT-claim GUC PostgREST sets, so the RPC's own auth.uid()
-- lookup resolves the way it would for a real logged-in official -- this is
-- what makes the guard fail on the STATUS check (NOT_ASSIGNED) specifically,
-- not the earlier role check (FORBIDDEN).
do $$
declare
  v_id uuid;
begin
  select id into v_id from potholes where lat = 1.0 and lng = 1.0;
  perform set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000004', true);

  begin
    perform mark_pothole_fixed(v_id);
    raise exception 'SMOKE TEST FAILED: mark_pothole_fixed on a not_assigned row did not raise';
  exception
    when sqlstate 'P0001' then
      if sqlerrm <> 'NOT_ASSIGNED' then
        raise exception 'SMOKE TEST FAILED: expected NOT_ASSIGNED, got %', sqlerrm;
      end if;
      raise notice 'PASS: mark_pothole_fixed correctly rejects a not_assigned row';
  end;
end;
$$;

rollback;
