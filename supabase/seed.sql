-- Demo accounts: 4 government roles + 1 citizen to own seeded reports.
-- Fixed UUIDs (not gen_random_uuid()) so this file stays readable and the
-- auth.users / auth.identities rows can reference the same id in one pass.
-- Shared demo password for all 5 accounts: Demo1234!

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token
) values
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'demo-citizen@tampalpintar.demo', crypt('Demo1234!', gen_salt('bf')), now(), now(), now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 'jkr-malaysia@tampalpintar.demo', crypt('Demo1234!', gen_salt('bf')), now(), now(), now(), '{"provider":"email","providers":["email"]}', '{"role":"jkr_malaysia"}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', 'jkr-selangor@tampalpintar.demo', crypt('Demo1234!', gen_salt('bf')), now(), now(), now(), '{"provider":"email","providers":["email"]}', '{"role":"jkr_selangor"}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000004', 'authenticated', 'authenticated', 'local-council@tampalpintar.demo', crypt('Demo1234!', gen_salt('bf')), now(), now(), now(), '{"provider":"email","providers":["email"]}', '{"role":"local_council"}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000005', 'authenticated', 'authenticated', 'highway-concessionaire@tampalpintar.demo', crypt('Demo1234!', gen_salt('bf')), now(), now(), now(), '{"provider":"email","providers":["email"]}', '{"role":"highway_concessionaire"}', now(), now(), '', '', '', '');

insert into auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
select gen_random_uuid(), id, id::text, jsonb_build_object('sub', id::text, 'email', email), 'email', now(), now(), now()
from auth.users
where id in (
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000002',
  '00000000-0000-0000-0000-000000000003',
  '00000000-0000-0000-0000-000000000004',
  '00000000-0000-0000-0000-000000000005'
);

-- profiles rows are created automatically by the handle_new_user trigger.

-- 10 seeded potholes across Selangor, one pair per road type/authority, far
-- enough apart (different towns) that none trips the 10m duplicate trigger.
-- photo_url is a placeholder image -- seed rows skip the real upload path,
-- the edge function always writes an actual Storage URL for live reports.
insert into potholes (reporter_id, photo_url, lat, lng, status, risk_score, risk_rationale, road_type, assigned_role, reported_at, assigned_at, fixed_at) values
  ('00000000-0000-0000-0000-000000000001', 'https://placehold.co/600x400?text=Pothole', 3.0733, 101.5185, 'fixed', 45, 'Shallow pothole, dry conditions, low traffic road.', 'municipal_local', 'local_council', now() - interval '6 days', now() - interval '5 days', now() - interval '3 days'),
  ('00000000-0000-0000-0000-000000000001', 'https://placehold.co/600x400?text=Pothole', 3.1073, 101.6067, 'not_assigned', 38, 'Minor surface crack, no standing water visible.', 'municipal_local', 'local_council', now() - interval '1 day', null, null),
  ('00000000-0000-0000-0000-000000000001', 'https://placehold.co/600x400?text=Pothole', 3.0333, 101.4500, 'assigned', 62, 'Moderate depth pothole near a residential junction.', 'municipal_local', 'local_council', now() - interval '2 days', now() - interval '1 day', null),
  ('00000000-0000-0000-0000-000000000001', 'https://placehold.co/600x400?text=Pothole', 2.9925, 101.7874, 'not_assigned', 25, 'Hairline crack, cosmetic only at this stage.', 'municipal_local', 'local_council', now() - interval '12 hours', null, null),
  ('00000000-0000-0000-0000-000000000001', 'https://placehold.co/600x400?text=Pothole', 3.3187, 101.5753, 'assigned', 88, 'Deep pothole on a high-speed federal route, night rain reported.', 'federal_route', 'jkr_malaysia', now() - interval '4 days', now() - interval '4 days', null),
  ('00000000-0000-0000-0000-000000000001', 'https://placehold.co/600x400?text=Pothole', 2.9987, 101.7196, 'not_assigned', 55, 'Medium pothole, moderate traffic flow observed.', 'federal_route', 'jkr_malaysia', now() - interval '8 hours', null, null),
  ('00000000-0000-0000-0000-000000000001', 'https://placehold.co/600x400?text=Pothole', 3.3410, 101.2497, 'not_assigned', 40, 'Shallow pothole on a state route shoulder.', 'state_route', 'jkr_selangor', now() - interval '18 hours', null, null),
  ('00000000-0000-0000-0000-000000000001', 'https://placehold.co/600x400?text=Pothole', 3.5670, 101.6499, 'fixed', 70, 'Large pothole, since repaired by JKR Selangor.', 'state_route', 'jkr_selangor', now() - interval '10 days', now() - interval '9 days', now() - interval '6 days'),
  ('00000000-0000-0000-0000-000000000001', 'https://placehold.co/600x400?text=Pothole', 3.1225, 101.5851, 'assigned', 91, 'Severe pothole on an expressway lane, high vehicle speed context.', 'highway_expressway', 'highway_concessionaire', now() - interval '3 days', now() - interval '3 days', null),
  ('00000000-0000-0000-0000-000000000001', 'https://placehold.co/600x400?text=Pothole', 3.0219, 101.6169, 'not_assigned', 33, 'Small pothole on the expressway shoulder, low risk for now.', 'highway_expressway', 'highway_concessionaire', now() - interval '5 hours', null, null);
