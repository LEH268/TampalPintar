-- Close the privilege-escalation hole: the own-row UPDATE policies on profiles
-- and reports gate rows, not columns, and `authenticated` held table-wide UPDATE.
-- Restrict authenticated UPDATE to the columns clients legitimately change.
-- SECURITY DEFINER functions (submit_report, mark_fixed, redeem_voucher) and the
-- service-role client run as table owner and are unaffected by these grants.
revoke update on public.profiles from authenticated, anon;
grant  update (display_name, dashcam_id, default_vehicle_type)
  on public.profiles to authenticated;

revoke update on public.reports from authenticated, anon;
grant  update (assigned) on public.reports to authenticated;
