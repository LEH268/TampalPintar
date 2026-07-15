insert into storage.buckets (id, name, public)
values ('media', 'media', true)
on conflict (id) do nothing;

create policy "media live insert" on storage.objects
  for insert to anon, authenticated
  with check (bucket_id = 'media' and name like 'live/%');

create policy "media reports insert own" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'media'
              and name like 'reports/' || auth.uid()::text || '/%');

create policy "media read" on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'media');

create policy "media reports delete own" on storage.objects
  for delete to authenticated
  using (bucket_id = 'media'
         and name like 'reports/' || auth.uid()::text || '/%');
