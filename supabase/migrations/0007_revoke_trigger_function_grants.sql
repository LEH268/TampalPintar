-- Supabase's default privileges grant EXECUTE to anon/authenticated on every
-- new public-schema function so PostgREST can expose it automatically.
-- handle_new_user and reject_if_duplicate_nearby are trigger-only (never
-- meant to be called directly via RPC) -- revoking from PUBLIC in 0006
-- wasn't enough since anon/authenticated had their own explicit grants
-- underneath it.
revoke execute on function handle_new_user() from anon, authenticated;
revoke execute on function reject_if_duplicate_nearby() from anon, authenticated;
