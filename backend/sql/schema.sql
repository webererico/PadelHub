-- PadelHub — Cloud SQL (PostgreSQL) schema.
-- Run with: psql "$DATABASE_URL" -f sql/schema.sql

create extension if not exists "pgcrypto"; -- gen_random_uuid()

create table if not exists arenas (
  id              uuid primary key default gen_random_uuid(),
  name            text not null,
  city            text not null,
  state           text not null,
  country         text not null default 'BR',
  court_count     int not null default 1,
  created_at      timestamptz not null default now()
);

-- Primary key is the Firebase Auth UID (not a generated uuid).
create table if not exists users (
  id              text primary key,
  name            text not null,
  email           text not null unique,
  photo_url       text,
  club_id         uuid references arenas(id),
  city            text,
  state           text,
  country         text default 'BR',
  rating          int not null default 1000,
  is_admin        boolean not null default false,
  created_at      timestamptz not null default now()
);

create index if not exists idx_users_club on users(club_id);
create index if not exists idx_users_city on users(city, state);
create index if not exists idx_users_rating on users(rating desc);
create index if not exists idx_users_name on users(lower(name) text_pattern_ops);

create table if not exists matches (
  id              uuid primary key default gen_random_uuid(),
  format          text not null check (format in ('amistosa', 'torneio', 'americano')),
  status          text not null default 'pending_confirmation'
                    check (status in ('pending_confirmation', 'confirmed', 'disputed')),
  arena_id        uuid references arenas(id),
  created_by      text not null references users(id),
  played_at       timestamptz not null default now(),
  created_at      timestamptz not null default now()
);

create index if not exists idx_matches_status on matches(status);
create index if not exists idx_matches_arena on matches(arena_id);
create index if not exists idx_matches_played_at on matches(played_at desc);

create table if not exists match_sets (
  match_id        uuid not null references matches(id) on delete cascade,
  set_index       int not null,
  team_a_games    int not null,
  team_b_games    int not null,
  primary key (match_id, set_index)
);

create table if not exists match_players (
  match_id        uuid not null references matches(id) on delete cascade,
  user_id         text not null references users(id),
  team            char(1) not null check (team in ('A', 'B')),
  rating_delta    int,
  primary key (match_id, user_id)
);

create index if not exists idx_match_players_user on match_players(user_id);

-- Anti-fraude: a partida só conta para o ranking depois que >=1 adversário confirmar.
create table if not exists match_confirmations (
  match_id        uuid not null references matches(id) on delete cascade,
  user_id         text not null references users(id),
  confirmed_at    timestamptz not null default now(),
  primary key (match_id, user_id)
);

create table if not exists rating_history (
  id              uuid primary key default gen_random_uuid(),
  user_id         text not null references users(id),
  rating          int not null,
  match_id        uuid references matches(id),
  recorded_at     timestamptz not null default now()
);

create index if not exists idx_rating_history_user on rating_history(user_id, recorded_at);

create table if not exists player_badges (
  user_id         text not null references users(id),
  badge_type      text not null check (badge_type in ('pneu_furado', 'nomade_do_padel', 'inimigo_do_erro')),
  unlocked_at     timestamptz not null default now(),
  primary key (user_id, badge_type)
);

create table if not exists kudos (
  match_id        uuid not null references matches(id) on delete cascade,
  user_id         text not null references users(id),
  created_at      timestamptz not null default now(),
  primary key (match_id, user_id)
);

create table if not exists comments (
  id              uuid primary key default gen_random_uuid(),
  match_id        uuid not null references matches(id) on delete cascade,
  user_id         text not null references users(id),
  body            text not null,
  created_at      timestamptz not null default now()
);

create index if not exists idx_comments_match on comments(match_id, created_at);

-- Super 8 / Super 12: rotating-partners doubles events. Every round each
-- player partners with a different teammate; standings are kept separate
-- from the main ELO rating (a short games-to-6 round isn't comparable to a
-- full match win/loss).
create table if not exists super_events (
  id              uuid primary key default gen_random_uuid(),
  name            text not null,
  format          text not null check (format in ('super8', 'super12')),
  arena_id        uuid references arenas(id),
  created_by      text not null references users(id),
  status          text not null default 'scheduled'
                    check (status in ('scheduled', 'in_progress', 'completed')),
  created_at      timestamptz not null default now()
);

create index if not exists idx_super_events_status on super_events(status);

create table if not exists super_event_players (
  event_id        uuid not null references super_events(id) on delete cascade,
  user_id         text not null references users(id),
  primary key (event_id, user_id)
);

create table if not exists super_event_rounds (
  id                    uuid primary key default gen_random_uuid(),
  event_id              uuid not null references super_events(id) on delete cascade,
  round_index           int not null,
  court_number          int not null,
  team_a_player_ids     text[] not null,
  team_b_player_ids     text[] not null,
  team_a_games          int,
  team_b_games          int,
  created_at            timestamptz not null default now()
);

create index if not exists idx_super_event_rounds_event on super_event_rounds(event_id, round_index);

-- Quadras ocupadas agora, para o "ao vivo" do perfil de arena.
create table if not exists court_sessions (
  id                  uuid primary key default gen_random_uuid(),
  arena_id            uuid not null references arenas(id),
  court_label         text not null,
  team_a_player_ids   text[] not null,
  team_b_player_ids   text[] not null,
  score_label         text not null default '0-0',
  started_at          timestamptz not null default now(),
  ended_at            timestamptz
);

create index if not exists idx_court_sessions_arena on court_sessions(arena_id) where ended_at is null;
