-- Supabase Realtime's postgres_changes evaluates the SELECT policy against
-- the NEW row for UPDATE events; if the update makes a row fail that
-- policy (exactly what "status <> 'fixed'" did on the fix transition), the
-- event is silently never delivered -- not even as a removal signal. That
-- would leave a stale pin on the map after Complete instead of it
-- disappearing live. Fix: SELECT policy no longer excludes fixed rows;
-- both Flutter apps filter status == 'fixed' out of the pins list
-- themselves before rendering. Same data exposure either way (a fixed
-- pothole isn't sensitive), just moves the filter to the client so the
-- realtime event still reaches it.
drop policy potholes_select on potholes;

create policy potholes_select on potholes for select using (
  (select role from profiles where id = auth.uid()) = 'citizen'
  or assigned_role = (select role from profiles where id = auth.uid())
);
