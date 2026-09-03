import {Router} from 'express';

import {getPool} from '../db';
import {assembleMatches} from '../services/matchAssembler';

export const usersRouter = Router();

usersRouter.get('/:userId', async (req, res) => {
  const pool = await getPool();
  const {rows} = await pool.query(
    `select u.id, u.name, u.email, u.photo_url, u.city, u.state, u.rating, a.id as club_id, a.name as club_name
     from users u
     left join arenas a on a.id = u.club_id
     where u.id = $1`,
    [req.params.userId],
  );
  if (rows.length === 0) {
    res.status(404).json({error: 'user_not_found'});
    return;
  }
  const row = rows[0];
  res.json({
    id: row.id,
    name: row.name,
    email: row.email,
    photoUrl: row.photo_url,
    rating: row.rating,
    clubId: row.club_id,
    clubName: row.club_name,
    city: row.city,
    state: row.state,
  });
});

usersRouter.get('/:userId/matches', async (req, res) => {
  const pool = await getPool();
  const {rows} = await pool.query(
    `select distinct m.id, m.played_at from matches m
     join match_players mp on mp.match_id = m.id
     where mp.user_id = $1
     order by m.played_at desc limit 50`,
    [req.params.userId],
  );
  const matches = await assembleMatches(pool, rows.map((r) => r.id), req.uid);
  res.json(matches);
});

usersRouter.get('/:userId/rating-history', async (req, res) => {
  const pool = await getPool();
  const {rows} = await pool.query(
    `select rating from rating_history where user_id = $1 order by recorded_at asc limit 200`,
    [req.params.userId],
  );
  res.json(rows.map((r) => r.rating));
});

usersRouter.get('/:userId/badges', async (req, res) => {
  const pool = await getPool();
  const {rows} = await pool.query(
    `select badge_type, unlocked_at from player_badges where user_id = $1 order by unlocked_at asc`,
    [req.params.userId],
  );
  res.json(
    rows.map((r) => ({
      type: snakeToCamel(r.badge_type),
      unlockedAt: r.unlocked_at.toISOString(),
    })),
  );
});

function snakeToCamel(value: string): string {
  return value.replace(/_([a-z])/g, (_, c: string) => c.toUpperCase());
}
