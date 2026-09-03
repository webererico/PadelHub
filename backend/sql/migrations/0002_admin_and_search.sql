-- Adds admin role + a name index for player search.
-- Run this in Cloud SQL Studio against an existing database that was
-- created from an earlier version of schema.sql (schema.sql itself is
-- already up to date for fresh installs).

alter table users add column if not exists is_admin boolean not null default false;
create index if not exists idx_users_name on users(lower(name) text_pattern_ops);

-- To make yourself an admin, run (replace with your real Firebase UID —
-- find it in Firebase Console > Authentication > Users):
--   update users set is_admin = true where id = '<your-firebase-uid>';
