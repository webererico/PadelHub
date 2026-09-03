import {Router} from 'express';

import {getPool} from '../db';
import {asyncHandler} from '../middleware/asyncHandler';
import {requireAdmin} from '../middleware/requireAdmin';

export const arenasRouter = Router();

/** Admin arena-registration dashboard: list + create. */
arenasRouter.get(
  '/',
  requireAdmin,
  asyncHandler(async (_req, res) => {
    const pool = await getPool();
    const {rows} = await pool.query(
      `select a.id, a.name, a.city, a.state, a.court_count,
         (select count(*)::int from users u where u.club_id = a.id) as active_player_count
       from arenas a order by a.name`,
    );
    res.json(
      rows.map((row) => ({
        id: row.id,
        name: row.name,
        city: row.city,
        state: row.state,
        courtCount: row.court_count,
        activePlayerCount: row.active_player_count,
      })),
    );
  }),
);

arenasRouter.post(
  '/',
  requireAdmin,
  asyncHandler(async (req, res) => {
    const {name, city, state, courtCount} = req.body as {
      name?: string;
      city?: string;
      state?: string;
      courtCount?: number;
    };
    if (!name?.trim() || !city?.trim() || !state?.trim()) {
      res.status(400).json({error: 'invalid_payload'});
      return;
    }
    const pool = await getPool();
    const {rows} = await pool.query(
      `insert into arenas (name, city, state, court_count) values ($1, $2, $3, $4)
       returning id, name, city, state, court_count`,
      [name.trim(), city.trim(), state.trim(), courtCount && courtCount > 0 ? courtCount : 1],
    );
    const row = rows[0];
    res.status(201).json({
      id: row.id,
      name: row.name,
      city: row.city,
      state: row.state,
      courtCount: row.court_count,
      activePlayerCount: 0,
    });
  }),
);

arenasRouter.get(
  '/:arenaId',
  asyncHandler(async (req, res) => {
    const pool = await getPool();
    const {rows} = await pool.query(
      `select a.id, a.name, a.city, a.state, a.court_count,
         (select count(*)::int from users u where u.club_id = a.id) as active_player_count
       from arenas a where a.id = $1`,
      [req.params.arenaId],
    );
    if (rows.length === 0) {
      res.status(404).json({error: 'arena_not_found'});
      return;
    }
    const row = rows[0];
    res.json({
      id: row.id,
      name: row.name,
      city: row.city,
      state: row.state,
      courtCount: row.court_count,
      activePlayerCount: row.active_player_count,
    });
  }),
);

arenasRouter.get(
  '/:arenaId/ranking',
  asyncHandler(async (req, res) => {
    const pool = await getPool();
    const {rows} = await pool.query(
      `select u.id, u.name, u.rating, a.name as club_name,
         (select mp.rating_delta from match_players mp
            join matches m on m.id = mp.match_id
            where mp.user_id = u.id and m.status = 'confirmed'
            order by m.played_at desc limit 1) as rating_delta
       from users u
       left join arenas a on a.id = u.club_id
       where u.club_id = $1
       order by u.rating desc
       limit 50`,
      [req.params.arenaId],
    );
    res.json(
      rows.map((row, index) => ({
        position: index + 1,
        userId: row.id,
        name: row.name,
        rating: row.rating,
        ratingDelta: row.rating_delta ?? 0,
        clubName: row.club_name,
      })),
    );
  }),
);

arenasRouter.get(
  '/:arenaId/live',
  asyncHandler(async (req, res) => {
    const pool = await getPool();
    const {rows} = await pool.query(
      `select cs.court_label, cs.started_at, cs.score_label,
         (select string_agg(u.name, ' & ') from users u where u.id = any(cs.team_a_player_ids)) as team_a,
         (select string_agg(u.name, ' & ') from users u where u.id = any(cs.team_b_player_ids)) as team_b
       from court_sessions cs
       where cs.arena_id = $1 and cs.ended_at is null
       order by cs.started_at desc`,
      [req.params.arenaId],
    );
    res.json(
      rows.map((row) => ({
        courtLabel: row.court_label,
        startedAt: row.started_at.toISOString(),
        teamA: row.team_a,
        teamB: row.team_b,
        scoreLabel: row.score_label,
      })),
    );
  }),
);
