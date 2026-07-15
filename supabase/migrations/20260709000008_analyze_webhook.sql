create extension if not exists pg_net;

create or replace function public.trigger_analyze_report()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform net.http_post(
    url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/analyze-report',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer YOUR_SUPABASE_ANON_KEY'
    ),
    body := jsonb_build_object('report_id', new.id)
  );
  return new;
end $$;

create trigger reports_analyze
after insert on public.reports
for each row
when (new.risk_score is null)
execute function public.trigger_analyze_report();
