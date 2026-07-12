create or replace function public.redeem_voucher(p_catalog_id uuid)
returns text language plpgsql security definer set search_path = public as $$
declare
  v_item public.voucher_catalog%rowtype;
  v_balance bigint;
  v_code text;
  v_redemption_id uuid;
begin
  if public.caller_role() is distinct from 'citizen' then
    raise exception 'citizens_only' using errcode = '42501';
  end if;
  select * into v_item from public.voucher_catalog where id = p_catalog_id;
  if not found then
    raise exception 'voucher_not_found';
  end if;
  -- serialize concurrent redemptions by the same user
  perform pg_advisory_xact_lock(hashtext(auth.uid()::text));
  select coalesce(sum(amount), 0) into v_balance
    from public.points_ledger where profile_id = auth.uid();
  if v_balance < v_item.points_cost then
    raise exception 'insufficient_points';
  end if;
  v_code := 'TP-' || upper(substr(md5(random()::text), 1, 4))
         || '-' || upper(substr(md5(random()::text), 1, 4));
  insert into public.redemptions (profile_id, catalog_id, code)
  values (auth.uid(), p_catalog_id, v_code)
  returning id into v_redemption_id;
  insert into public.points_ledger (profile_id, amount, redemption_id, reason)
  values (auth.uid(), -v_item.points_cost, v_redemption_id,
          'Redeemed ' || v_item.name);
  return v_code;
end $$;

revoke all on function public.redeem_voucher(uuid) from public, anon;
grant execute on function public.redeem_voucher(uuid) to authenticated;
