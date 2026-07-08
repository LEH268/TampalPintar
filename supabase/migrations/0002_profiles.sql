create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role user_role not null default 'citizen',
  created_at timestamptz not null default now()
);

alter table profiles enable row level security;

create policy profiles_select on profiles for select using (auth.uid() = id);

-- Populates profiles for both normal signups (no role in metadata -> citizen)
-- and seeded government accounts (role set directly in auth.users metadata).
create or replace function handle_new_user() returns trigger
language plpgsql security definer as $$
begin
  insert into profiles (id, role)
  values (new.id, coalesce((new.raw_user_meta_data->>'role')::user_role, 'citizen'));
  return new;
end;
$$;

create trigger trg_handle_new_user
  after insert on auth.users
  for each row execute function handle_new_user();
