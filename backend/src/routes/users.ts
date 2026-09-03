import {Router} from 'express';

import {getPool} from '../db';
import {asyncHandler} from '../middleware/asyncHandler';
import {assembleMatches} from '../services/matchAssembler';

export const usersRouter = Router();

/**
 * Firebase Auth and the Postgres `users` table are separate systems — a
 * signup only creates the former. The client calls this right after
 * sign-in to make sure a matching row exists, upserting it from the
 * verified ID token's own claims (never trusting a client-supplied uid).
 */
usersRouter.post(
  '/me',
  asyncHandler(async (req, res) => {
    const pool = await getPool();
    const email = req.tokenEmail ?? `${req.uid}@padelhub.local`;
    const name = req.tokenName ?? email.split('@')[0];
    const {rows} = await pool.query(
      `insert into users (id, name, email, photo_url)
       values ($1, $2, $3, $4)
       on conflict (id) do update set
         email = excluded.email,
         photo_url = coalesce(excluded.photo_url, users.photo_url)
       returning id, name, email, photo_url, city, state, rating, club_id, is_admin`,
      [req.uid, name, email, req.tokenPicture ?? null],
    );
    res.json(toUserJson(rows[0]));
  }),
);

/** Player search for the record-match flow — `GET /users?q=fern`. */
usersRouter.get(
  '/',
  asyncHandler(async (req, res) => {
    const q = ((req.query.q as string) ?? '').trim();
    if (q.length < 2) {
      res.json([]);
      return;
    }
    const pool = await getPool();
    const {rows} = await pool.query(
      `select id, name, photo_url from users where lower(name) like lower($1) and id != $2 order by name limit 10`,
      [`%${q}%`, req.uid],
    );
    res.json(rows.map((r) => ({id: r.id, name: r.name, photoUrl: r.photo_url})));
  }),
);

usersRouter.get(
  '/:userId',
  asyncHandler(async (req, res) => {
    const pool = await getPool();
    const {rows} = await pool.query(
      `select u.id, u.name, u.email, u.photo_url, u.city, u.state, u.rating, u.is_admin, a.id as club_id, a.name as club_name
       from users u
       left join arenas a on a.id = u.club_id
       where u.id = $1`,
      [req.params.userId],
    );
    if (rows.length === 0) {
      res.status(404).json({error: 'user_not_found'});
      return;
    }
    res.json(toUserJson(rows[0]));
  }),
);

usersRouter.get(
  '/:userId/matches',
  asyncHandler(async (req, res) => {
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
  }),
);

usersRouter.get(
  '/:userId/rating-history',
  asyncHandler(async (req, res) => {
    const pool = await getPool();
    const {rows} = await pool.query(
      `select rating from rating_history where user_id = $1 order by recorded_at asc limit 200`,
      [req.params.userId],
    );
    res.json(rows.map((r) => r.rating));
  }),
);

usersRouter.get(
  '/:userId/badges',
  asyncHandler(async (req, res) => {
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
  }),
);

function toUserJson(row: {
  id: string;
  name: string;
  email: string;
  photo_url: string | null;
  rating: number;
  club_id: string | null;
  club_name?: string | null;
  city: string | null;
  state: string | null;
  is_admin: boolean;
}) {
  return {
    id: row.id,
    name: row.name,
    email: row.email,
    photoUrl: row.photo_url,
    rating: row.rating,
    clubId: row.club_id,
    clubName: row.club_name ?? null,
    city: row.city,
    state: row.state,
    isAdmin: row.is_admin,
  };
}

function snakeToCamel(value: string): string {
  return value.replace(/_([a-z])/g, (_, c: string) => c.toUpperCase());
}
