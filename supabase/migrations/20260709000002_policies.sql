-- profiles
create policy "profiles own select" on public.profiles
  for select using (auth.uid() = id);
create policy "profiles own update" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

-- reports: citizens
create policy "citizen sees active or own" on public.reports
  for select using (
    public.caller_role() = 'citizen'
    and (status = 'active' or reporter = auth.uid())
  );
-- reports: government roles
create policy "role sees own authority" on public.reports
  for select using (
    public.caller_role() <> 'citizen'
    and authority_role = public.caller_role()
  );
create policy "role updates own authority" on public.reports
  for update using (
    public.caller_role() <> 'citizen'
    and authority_role = public.caller_role()
  ) with check (authority_role = public.caller_role());
-- (no INSERT policy on reports: submit_report RPC is the only write path)

-- rewards: citizens read own rows; nobody writes directly
create policy "ledger own rows" on public.points_ledger
  for select using (profile_id = auth.uid() and public.caller_role() = 'citizen');
create policy "redemptions own rows" on public.redemptions
  for select using (profile_id = auth.uid() and public.caller_role() = 'citizen');
create policy "catalog for citizens" on public.voucher_catalog
  for select using (public.caller_role() = 'citizen');
