-- Harden redeem_voucher voucher-code generation:
--   1. Replace md5(random()::text) (non-cryptographic PRNG) with entropy
--      drawn from gen_random_uuid(), which is backed by pg_strong_random
--      and already used for every id default in this schema.
--   2. Add a UNIQUE constraint on redemptions.code so a collision cannot
--      silently hand out the same redeemable code to two profiles.
--   3. Wrap the redemptions insert in a bounded retry loop that catches
--      unique_violation, regenerates the code, and re-raises after a small
--      number of attempts. The external interface (format TP-XXXX-XXXX,
--      uppercase hex) is unchanged.

alter table public.redemptions add constraint redemptions_code_key unique (code);

create or replace function public.redeem_voucher(p_catalog_id uuid)
returns text language plpgsql security definer set search_path = public as $$
declare
  v_item public.voucher_catalog%rowtype;
  v_balance bigint;
  v_code text;
  v_redemption_id uuid;
  v_attempt int := 0;
  v_max_attempts constant int := 5;
  v_inserted boolean := false;
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

  while not v_inserted loop
    v_attempt := v_attempt + 1;
    v_code := 'TP-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,4))
           || '-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,4));
    begin
      insert into public.redemptions (profile_id, catalog_id, code)
      values (auth.uid(), p_catalog_id, v_code)
      returning id into v_redemption_id;
      v_inserted := true;
    exception when unique_violation then
      if v_attempt >= v_max_attempts then
        raise;
      end if;
      -- otherwise loop and regenerate a fresh code; the nested BEGIN block
      -- above is an implicit savepoint, so only the failed insert rolls
      -- back here, not the whole redeem_voucher transaction.
    end;
  end loop;

  insert into public.points_ledger (profile_id, amount, redemption_id, reason)
  values (auth.uid(), -v_item.points_cost, v_redemption_id,
          'Redeemed ' || v_item.name);
  return v_code;
end $$;

revoke all on function public.redeem_voucher(uuid) from public, anon;
grant execute on function public.redeem_voucher(uuid) to authenticated;
