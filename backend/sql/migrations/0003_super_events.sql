-- Super 8 / Super 12: rotating-partners doubles events.
-- Every round each player partners with a different teammate; standings are
-- kept separate from the main ELO rating (a short games-to-6 round isn't
-- comparable to a full match win/loss).

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
