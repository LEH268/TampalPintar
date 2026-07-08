create table potholes (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references profiles(id),
  photo_url text not null,
  lat double precision not null,
  lng double precision not null,
  status pothole_status not null default 'not_assigned',
  risk_score smallint not null check (risk_score between 0 and 100),
  risk_rationale text not null,
  road_type road_type not null,
  assigned_role user_role not null check (assigned_role <> 'citizen'),
  reported_at timestamptz not null default now(),
  assigned_at timestamptz,
  fixed_at timestamptz
);

create index potholes_active_role_idx on potholes (assigned_role) where status <> 'fixed';

alter table potholes enable row level security;

-- Citizens see every active report; officials see only active reports routed to their role.
create policy potholes_select on potholes for select using (
  status <> 'fixed' and (
    (select role from profiles where id = auth.uid()) = 'citizen'
    or assigned_role = (select role from profiles where id = auth.uid())
  )
);

alter publication supabase_realtime add table potholes;

insert into storage.buckets (id, name, public)
values ('pothole-photos', 'pothole-photos', true)
on conflict (id) do nothing;
