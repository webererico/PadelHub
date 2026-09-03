import {Router} from 'express';

import {getPool} from '../db';
import {asyncHandler} from '../middleware/asyncHandler';

export const rankingRouter = Router();

const SCOPES = new Set(['global', 'country', 'state', 'city', 'club', 'friends']);

rankingRouter.get(
  '/',
  asyncHandler(async (req, res) => {
    const scope = (req.query.scope as string | undefined) ?? 'global';
    if (!SCOPES.has(scope)) {
      res.status(400).json({error: 'invalid_scope'});
      return;
    }

    const pool = await getPool();
    const filters: string[] = [];
    const params: unknown[] = [];

    if (scope !== 'global') {
      const viewer = await pool.query(`select city, state, country, club_id from users where id = $1`, [req.uid]);
      const me = viewer.rows[0];
      if (!me) {
        res.status(404).json({error: 'viewer_not_found'});
        return;
      }
      // 'friends' falls back to the player's city until a follow graph exists.
      if (scope === 'city' || scope === 'friends') {
        params.push(me.city);
        filters.push(`u.city = $${params.length}`);
      } else if (scope === 'state') {
        params.push(me.state);
        filters.push(`u.state = $${params.length}`);
      } else if (scope === 'country') {
        params.push(me.country);
        filters.push(`u.country = $${params.length}`);
      } else if (scope === 'club') {
        params.push(me.club_id);
        filters.push(`u.club_id = $${params.length}`);
      }
    }

    const where = filters.length > 0 ? `where ${filters.join(' and ')}` : '';
    const {rows} = await pool.query(
      `select u.id, u.name, u.rating, a.name as club_name,
         (select mp.rating_delta from match_players mp
            join matches m on m.id = mp.match_id
            where mp.user_id = u.id and m.status = 'confirmed'
            order by m.played_at desc limit 1) as rating_delta
       from users u
       left join arenas a on a.id = u.club_id
       ${where}
       order by u.rating desc
       limit 100`,
      params,
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
