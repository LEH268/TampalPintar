-- Authoritative backstop for the 10m duplicate-report rule (story #10):
-- the edge function also pre-checks this before spending a Gemini call,
-- but every insert path (present or future) must go through this trigger.
create or replace function reject_if_duplicate_nearby() returns trigger
language plpgsql security definer as $$
begin
  if exists (
    select 1 from potholes
    where status <> 'fixed'
      and earth_distance(ll_to_earth(lat, lng), ll_to_earth(new.lat, new.lng)) < 10
  ) then
    raise exception 'DUPLICATE_NEARBY' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

create trigger trg_reject_duplicate_nearby
  before insert on potholes
  for each row execute function reject_if_duplicate_nearby();
