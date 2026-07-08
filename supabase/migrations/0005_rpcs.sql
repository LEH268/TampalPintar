-- Non-reversible one-way transitions: not_assigned -> assigned -> fixed.
-- Both RPCs lock the row, re-check the caller's role against assigned_role,
-- and re-check current status server-side so the transition can't be
-- skipped or repeated from a stale client.

create or replace function assign_pothole(p_pothole_id uuid) returns void
language plpgsql security definer as $$
declare
  v_role user_role;
  v_status pothole_status;
  v_assigned_role user_role;
begin
  select role into v_role from profiles where id = auth.uid();
  select status, assigned_role into v_status, v_assigned_role from potholes where id = p_pothole_id for update;

  if v_status is null then raise exception 'NOT_FOUND'; end if;
  if v_role is distinct from v_assigned_role then raise exception 'FORBIDDEN'; end if;
  if v_status <> 'not_assigned' then raise exception 'ALREADY_ASSIGNED'; end if;

  update potholes set status = 'assigned', assigned_at = now() where id = p_pothole_id;
end;
$$;

create or replace function mark_pothole_fixed(p_pothole_id uuid) returns void
language plpgsql security definer as $$
declare
  v_role user_role;
  v_status pothole_status;
  v_assigned_role user_role;
begin
  select role into v_role from profiles where id = auth.uid();
  select status, assigned_role into v_status, v_assigned_role from potholes where id = p_pothole_id for update;

  if v_status is null then raise exception 'NOT_FOUND'; end if;
  if v_role is distinct from v_assigned_role then raise exception 'FORBIDDEN'; end if;
  if v_status <> 'assigned' then raise exception 'NOT_ASSIGNED'; end if; -- rejects unassigned AND already-fixed

  update potholes set status = 'fixed', fixed_at = now() where id = p_pothole_id;
end;
$$;

grant execute on function assign_pothole(uuid) to authenticated;
grant execute on function mark_pothole_fixed(uuid) to authenticated;
