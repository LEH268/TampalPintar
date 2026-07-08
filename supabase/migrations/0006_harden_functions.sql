-- Close two gaps the security advisor flagged after 0002/0004/0005:
-- 1) SECURITY DEFINER functions without a pinned search_path are hijackable
--    if a caller-controlled schema ever precedes `public` in their session.
-- 2) Postgres grants EXECUTE to PUBLIC on every new function by default, so
--    the explicit `grant ... to authenticated` in 0005 didn't actually
--    exclude anon. The RPCs already self-check auth.uid() and would reject
--    an anon caller, but revoking PUBLIC/anon is a free defense-in-depth
--    fix, and the trigger functions should not be directly callable at all.

alter function handle_new_user() set search_path = public;
alter function reject_if_duplicate_nearby() set search_path = public;
alter function assign_pothole(uuid) set search_path = public;
alter function mark_pothole_fixed(uuid) set search_path = public;

revoke execute on function handle_new_user() from public;
revoke execute on function reject_if_duplicate_nearby() from public;
revoke execute on function assign_pothole(uuid) from public;
revoke execute on function mark_pothole_fixed(uuid) from public;

revoke execute on function assign_pothole(uuid) from anon;
revoke execute on function mark_pothole_fixed(uuid) from anon;
