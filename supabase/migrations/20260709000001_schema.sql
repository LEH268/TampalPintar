-- enums
create type public.user_role as enum ('citizen','jkr_malaysia','jkr_selangor','local_council','highway');
create type public.report_source as enum ('photo','voice');
create type public.report_status as enum ('active','fixed');
create type public.road_type as enum ('highway_expressway','federal_route','state_route','municipal_local');
create type public.vehicle_type as enum ('motorcycle','car','heavy_commercial');
create type public.lane_position as enum ('left_slow','middle','right_fast','single_lane');
create type public.impact_severity as enum ('bump','swerve','damage');

-- profiles
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role public.user_role not null default 'citizen',
  display_name text not null,
  dashcam_id text unique,
  default_vehicle_type public.vehicle_type,
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, display_name, dashcam_id, default_vehicle_type)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data->>'display_name',''), split_part(new.email,'@',1)),
    nullif(new.raw_user_meta_data->>'dashcam_id',''),
    (nullif(new.raw_user_meta_data->>'default_vehicle_type',''))::public.vehicle_type
  );
  return new;
end $$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- reports
create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter uuid not null references public.profiles(id),
  lat double precision not null,
  lng double precision not null,
  speed_kmh double precision,
  source public.report_source not null,
  reported_at timestamptz not null default now(),
  captured_at timestamptz,
  status public.report_status not null default 'active',
  fixed_at timestamptz,
  assigned boolean not null default false,
  road_type public.road_type,
  authority_role public.user_role,
  authority_name text,
  risk_score integer check (risk_score between 0 and 100),
  factor_breakdown jsonb,
  rationale text,
  media_paths text[] not null default '{}',
  immediate_index integer,
  vehicle_type public.vehicle_type,
  lane_position public.lane_position,
  impact_severity public.impact_severity,
  analyzed_at timestamptz
);
create index reports_status_idx on public.reports (status);
create index reports_authority_active_idx on public.reports (authority_role) where status = 'active';

-- rewards
create table public.voucher_catalog (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  brand text not null,
  points_cost integer not null check (points_cost > 0),
  value_rm numeric(8,2) not null
);

create table public.redemptions (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id),
  catalog_id uuid not null references public.voucher_catalog(id),
  code text not null,
  redeemed_at timestamptz not null default now()
);

create table public.points_ledger (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id),
  amount integer not null,
  report_id uuid references public.reports(id),
  redemption_id uuid references public.redemptions(id),
  reason text not null,
  created_at timestamptz not null default now()
);
create index ledger_profile_idx on public.points_ledger (profile_id);

-- helpers
create or replace function public.caller_role()
returns public.user_role language sql stable security definer set search_path = public as
$$ select role from public.profiles where id = auth.uid() $$;

create or replace function public.haversine_m(
  lat1 double precision, lng1 double precision,
  lat2 double precision, lng2 double precision)
returns double precision language sql immutable as $$
  select 2 * 6371000 * asin( least(1.0, sqrt(
    power(sin(radians(lat2-lat1)/2),2) +
    cos(radians(lat1))*cos(radians(lat2))*power(sin(radians(lng2-lng1)/2),2)
  )));
$$;

-- RLS on (deny-all until policies land in the next migration)
alter table public.profiles enable row level security;
alter table public.reports enable row level security;
alter table public.voucher_catalog enable row level security;
alter table public.redemptions enable row level security;
alter table public.points_ledger enable row level security;
