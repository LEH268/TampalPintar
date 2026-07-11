create or replace function public.mark_fixed(p_report_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_report public.reports%rowtype;
  v_role public.user_role := public.caller_role();
begin
  select * into v_report from public.reports where id = p_report_id for update;
  if not found then
    raise exception 'report_not_found';
  end if;
  if v_role is null or v_role = 'citizen'
     or v_report.authority_role is distinct from v_role then
    raise exception 'not_your_report' using errcode = '42501';
  end if;
  if v_report.status <> 'active' then
    raise exception 'already_fixed';
  end if;
  if not v_report.assigned then
    raise exception 'not_assigned';
  end if;
  update public.reports
     set status = 'fixed', fixed_at = now()
   where id = p_report_id;
  insert into public.points_ledger (profile_id, amount, report_id, reason)
  values (v_report.reporter, coalesce(v_report.risk_score, 50), p_report_id,
          'Pothole fixed');
end $$;

revoke all on function public.mark_fixed(uuid) from public, anon;
grant execute on function public.mark_fixed(uuid) to authenticated;
