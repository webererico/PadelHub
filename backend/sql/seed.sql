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

-- Confirmed matches, so the Feed and Ranking have something to show
-- instead of an empty state.

insert into matches (id, format, status, arena_id, created_by, played_at) values
  ('b2b2b2b2-0000-0000-0000-000000000001', 'amistosa', 'confirmed', 'a1a1a1a1-0000-0000-0000-000000000001', 'demo-rafael', now() - interval '2 hours'),
  ('b2b2b2b2-0000-0000-0000-000000000002', 'torneio',  'confirmed', 'a1a1a1a1-0000-0000-0000-000000000003', 'demo-marina', now() - interval '5 hours'),
  ('b2b2b2b2-0000-0000-0000-000000000003', 'amistosa', 'confirmed', 'a1a1a1a1-0000-0000-0000-000000000001', 'demo-andre',  now() - interval '1 day')
on conflict (id) do nothing;

insert into match_sets (match_id, set_index, team_a_games, team_b_games) values
  ('b2b2b2b2-0000-0000-0000-000000000001', 0, 6, 4),
  ('b2b2b2b2-0000-0000-0000-000000000001', 1, 3, 6),
  ('b2b2b2b2-0000-0000-0000-000000000001', 2, 10, 8),
  ('b2b2b2b2-0000-0000-0000-000000000002', 0, 6, 4),
  ('b2b2b2b2-0000-0000-0000-000000000002', 1, 6, 2),
  ('b2b2b2b2-0000-0000-0000-000000000003', 0, 6, 2),
  ('b2b2b2b2-0000-0000-0000-000000000003', 1, 6, 3)
on conflict do nothing;

insert into match_players (match_id, user_id, team, rating_delta) values
  ('b2b2b2b2-0000-0000-0000-000000000001', 'demo-rafael',   'A', 16),
  ('b2b2b2b2-0000-0000-0000-000000000001', 'demo-bruno',    'A', 16),
  ('b2b2b2b2-0000-0000-0000-000000000001', 'demo-fernanda', 'B', -16),
  ('b2b2b2b2-0000-0000-0000-000000000001', 'demo-thiago',   'B', -16),
  ('b2b2b2b2-0000-0000-0000-000000000002', 'demo-marina',   'A', 18),
  ('b2b2b2b2-0000-0000-0000-000000000002', 'demo-joao',     'A', 18),
  ('b2b2b2b2-0000-0000-0000-000000000002', 'demo-beatriz',  'B', -18),
  ('b2b2b2b2-0000-0000-0000-000000000002', 'demo-gabriel',  'B', -18),
  ('b2b2b2b2-0000-0000-0000-000000000003', 'demo-andre',    'A', 9),
  ('b2b2b2b2-0000-0000-0000-000000000003', 'demo-camila',   'A', 9),
  ('b2b2b2b2-0000-0000-0000-000000000003', 'demo-beatriz',  'B', -9),
  ('b2b2b2b2-0000-0000-0000-000000000003', 'demo-gabriel',  'B', -9)
on conflict do nothing;

insert into match_confirmations (match_id, user_id) values
  ('b2b2b2b2-0000-0000-0000-000000000001', 'demo-fernanda'),
  ('b2b2b2b2-0000-0000-0000-000000000002', 'demo-beatriz'),
  ('b2b2b2b2-0000-0000-0000-000000000003', 'demo-beatriz')
on conflict do nothing;

insert into kudos (match_id, user_id) values
  ('b2b2b2b2-0000-0000-0000-000000000001', 'demo-fernanda'),
  ('b2b2b2b2-0000-0000-0000-000000000001', 'demo-thiago'),
  ('b2b2b2b2-0000-0000-0000-000000000001', 'demo-andre'),
  ('b2b2b2b2-0000-0000-0000-000000000002', 'demo-camila'),
  ('b2b2b2b2-0000-0000-0000-000000000003', 'demo-rafael')
on conflict do nothing;

insert into comments (match_id, user_id, body) values
  ('b2b2b2b2-0000-0000-0000-000000000001', 'demo-fernanda', 'Que virada surreal no terceiro set, revanche marcada!'),
  ('b2b2b2b2-0000-0000-0000-000000000002', 'demo-beatriz', 'Bem jogado, o saque de vocês estava impossível hoje.')
on conflict do nothing;

-- A rising rating history for demo-rafael, so the profile chart has a line
-- to draw instead of a single flat point.
insert into rating_history (user_id, rating, recorded_at) values
  ('demo-rafael', 1628, now() - interval '6 months'),
  ('demo-rafael', 1665, now() - interval '5 months'),
  ('demo-rafael', 1701, now() - interval '4 months'),
  ('demo-rafael', 1750, now() - interval '3 months'),
  ('demo-rafael', 1790, now() - interval '2 months'),
  ('demo-rafael', 1826, now() - interval '1 month'),
  ('demo-rafael', 1842, now() - interval '2 hours')
on conflict do nothing;
