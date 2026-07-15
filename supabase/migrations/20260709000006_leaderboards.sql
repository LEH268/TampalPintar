create or replace function public.top_reporters()
returns table(display_name text, lifetime_points bigint)
language sql stable security definer set search_path = public as $$
  select p.display_name,
         coalesce(sum(l.amount) filter (where l.amount > 0), 0) as lifetime_points
  from public.profiles p
  join public.points_ledger l on l.profile_id = p.id
  where p.role = 'citizen'
  group by p.id, p.display_name
  having coalesce(sum(l.amount) filter (where l.amount > 0), 0) > 0
  order by lifetime_points desc
  limit 50;
$$;

create or replace function public.department_response()
returns table(role public.user_role, avg_open_seconds double precision, fix_count bigint)
language sql stable security definer set search_path = public as $$
  select r.role,
         avg(extract(epoch from (rep.fixed_at - rep.reported_at))) as avg_open_seconds,
         count(rep.id) as fix_count
  from (values ('jkr_malaysia'::public.user_role),
               ('jkr_selangor'),
               ('local_council'),
               ('highway')) as r(role)
  left join public.reports rep
    on rep.authority_role = r.role and rep.status = 'fixed'
  group by r.role
  order by avg_open_seconds asc nulls last;
$$;

revoke all on function public.top_reporters() from public, anon;
grant execute on function public.top_reporters() to authenticated;
revoke all on function public.department_response() from public, anon;
grant execute on function public.department_response() to authenticated;
