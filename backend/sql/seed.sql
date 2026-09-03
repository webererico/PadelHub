-- Demo data matching the PadelHub design mockups. For local dev only.
-- Run with: psql "$DATABASE_URL" -f sql/seed.sql

insert into arenas (id, name, city, state, court_count) values
  ('a1a1a1a1-0000-0000-0000-000000000001', 'Arena Padel Club', 'São Paulo', 'SP', 6),
  ('a1a1a1a1-0000-0000-0000-000000000002', 'Vibe Padel', 'Rio de Janeiro', 'RJ', 4),
  ('a1a1a1a1-0000-0000-0000-000000000003', 'Play Padel Alphaville', 'Barueri', 'SP', 5)
on conflict (id) do nothing;

insert into users (id, name, email, city, state, club_id, rating) values
  ('demo-rafael',  'Rafael Costa',   'rafael@example.com',  'São Paulo', 'SP', 'a1a1a1a1-0000-0000-0000-000000000001', 1842),
  ('demo-bruno',   'Bruno Silva',    'bruno@example.com',   'São Paulo', 'SP', 'a1a1a1a1-0000-0000-0000-000000000001', 1690),
  ('demo-fernanda','Fernanda Lima',  'fernanda@example.com','São Paulo', 'SP', 'a1a1a1a1-0000-0000-0000-000000000001', 1755),
  ('demo-thiago',  'Thiago Rocha',   'thiago@example.com',  'São Paulo', 'SP', 'a1a1a1a1-0000-0000-0000-000000000001', 1774),
  ('demo-andre',   'André Reis',     'andre@example.com',   'São Paulo', 'SP', 'a1a1a1a1-0000-0000-0000-000000000001', 2014),
  ('demo-camila',  'Camila Souza',   'camila@example.com',  'São Paulo', 'SP', 'a1a1a1a1-0000-0000-0000-000000000001', 1968),
  ('demo-beatriz', 'Beatriz Campos', 'beatriz@example.com', 'São Paulo', 'SP', 'a1a1a1a1-0000-0000-0000-000000000001', 1790),
  ('demo-gabriel', 'Gabriel Nunes',  'gabriel@example.com', 'Curitiba',  'PR', null, 1702),
  ('demo-marina',  'Marina Alves',   'marina@example.com',  'Barueri',   'SP', 'a1a1a1a1-0000-0000-0000-000000000003', 1650),
  ('demo-joao',    'João Pedro',     'joaopedro@example.com','Barueri',  'SP', 'a1a1a1a1-0000-0000-0000-000000000003', 1710)
on conflict (id) do nothing;

insert into player_badges (user_id, badge_type) values
  ('demo-rafael', 'pneu_furado'),
  ('demo-rafael', 'nomade_do_padel')
on conflict do nothing;

insert into court_sessions (arena_id, court_label, team_a_player_ids, team_b_player_ids, score_label, started_at) values
  ('a1a1a1a1-0000-0000-0000-000000000001', 'Quadra 1', array['demo-camila','demo-andre'], array['demo-beatriz','demo-gabriel'], '6-4', now() - interval '18 minutes'),
  ('a1a1a1a1-0000-0000-0000-000000000001', 'Quadra 3', array['demo-fernanda','demo-thiago'], array['demo-rafael','demo-bruno'], '3-2', now() - interval '6 minutes')
on conflict do nothing;
