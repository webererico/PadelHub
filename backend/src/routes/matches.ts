import {Router} from 'express';

import {getPool} from '../db';
import {asyncHandler} from '../middleware/asyncHandler';
import {assembleMatches} from '../services/matchAssembler';
import {computeDoublesRatingUpdate} from '../services/elo';

export const matchesRouter = Router();

const FORMATS = new Set(['amistosa', 'torneio', 'americano']);

matchesRouter.get(
  '/feed',
  asyncHandler(async (req, res) => {
    const scope = (req.query.scope as string | undefined) ?? 'friends';
    const pool = await getPool();

    // 'friends' falls back to "matches involving me" until a follow graph exists.
    const {rows} = await pool.query(
      scope === 'friends'
        ? `select distinct m.id, m.played_at from matches m
           join match_players mp on mp.match_id = m.id
           where mp.user_id = $1
           order by m.played_at desc limit 30`
        : `select id, played_at from matches order by played_at desc limit 30`,
      scope === 'friends' ? [req.uid] : [],
    );

    const matches = await assembleMatches(pool, rows.map((r) => r.id), req.uid);
    res.json(matches);
  }),
);

matchesRouter.post(
  '/',
  asyncHandler(async (req, res) => {
    const {format, teamAPlayerIds, teamBPlayerIds, sets, arenaId} = req.body as {
      format: string;
      teamAPlayerIds: string[];
      teamBPlayerIds: string[];
      sets: {teamA: number; teamB: number}[];
      arenaId?: string;
    };

    if (!FORMATS.has(format) || teamAPlayerIds?.length !== 2 || teamBPlayerIds?.length !== 2 || !sets?.length) {
      res.status(400).json({error: 'invalid_payload'});
      return;
    }
    if (!teamAPlayerIds.includes(req.uid!)) {
      res.status(403).json({error: 'must_be_a_participant'});
      return;
    }

    const pool = await getPool();
    const client = await pool.connect();
    try {
      await client.query('begin');

      const matchRes = await client.query(
        `insert into matches (format, status, arena_id, created_by)
         values ($1, 'pending_confirmation', $2, $3) returning id, played_at`,
        [format, arenaId ?? null, req.uid],
      );
      const matchId = matchRes.rows[0].id;

      for (const userId of teamAPlayerIds) {
        await client.query(`insert into match_players (match_id, user_id, team) values ($1, $2, 'A')`, [matchId, userId]);
      }
      for (const userId of teamBPlayerIds) {
        await client.query(`insert into match_players (match_id, user_id, team) values ($1, $2, 'B')`, [matchId, userId]);
      }
      for (let i = 0; i < sets.length; i++) {
        await client.query(
          `insert into match_sets (match_id, set_index, team_a_games, team_b_games) values ($1, $2, $3, $4)`,
          [matchId, i, sets[i].teamA, sets[i].teamB],
        );
      }

      await client.query('commit');

      const [match] = await assembleMatches(pool, [matchId], req.uid);
      res.status(201).json(match);
    } catch (err) {
      await client.query('rollback');
      res.status(500).json({error: 'could_not_create_match'});
    } finally {
      client.release();
    }
  }),
);

/**
 * Validação cruzada anti-fraude: a partida só entra para o ranking depois
 * que ao menos um adversário confirmar o placar lançado.
 */
matchesRouter.post(
  '/:matchId/confirm',
  asyncHandler(async (req, res) => {
    const {matchId} = req.params;
    const pool = await getPool();
    const client = await pool.connect();

    try {
      await client.query('begin');

      const playerRow = await client.query(
        `select team from match_players where match_id = $1 and user_id = $2`,
        [matchId, req.uid],
      );
      if (playerRow.rowCount === 0) {
        await client.query('rollback');
        res.status(403).json({error: 'not_a_participant'});
        return;
      }

      await client.query(
        `insert into match_confirmations (match_id, user_id) values ($1, $2)
         on conflict (match_id, user_id) do nothing`,
        [matchId, req.uid],
      );

      const matchRow = await client.query(`select status, played_at from matches where id = $1`, [matchId]);
      if (matchRow.rows[0]?.status === 'pending_confirmation') {
        await client.query(`update matches set status = 'confirmed' where id = $1`, [matchId]);
        await applyRatingChanges(client, matchId);
      }

      await client.query('commit');
      res.status(204).send();
    } catch (err) {
      await client.query('rollback');
      res.status(500).json({error: 'could_not_confirm_match'});
    } finally {
      client.release();
    }
  }),
);

matchesRouter.post(
  '/:matchId/kudos',
  asyncHandler(async (req, res) => {
    const pool = await getPool();
    await pool.query(
      `insert into kudos (match_id, user_id) values ($1, $2) on conflict (match_id, user_id) do nothing`,
      [req.params.matchId, req.uid],
    );
    res.status(204).send();
  }),
);

// eslint-disable-next-line @typescript-eslint/no-explicit-any
async function applyRatingChanges(client: any, matchId: string): Promise<void> {
  const sets = await client.query(
    `select team_a_games, team_b_games from match_sets where match_id = $1 order by set_index`,
    [matchId],
  );
  const setsWonByA = sets.rows.filter((s: {team_a_games: number; team_b_games: number}) => s.team_a_games > s.team_b_games).length;
  const teamAWon = setsWonByA > sets.rows.length - setsWonByA;

  const players = await client.query(
    `select mp.user_id, mp.team, u.rating from match_players mp join users u on u.id = mp.user_id where mp.match_id = $1`,
    [matchId],
  );
  const teamA = players.rows.filter((p: {team: string}) => p.team === 'A');
  const teamB = players.rows.filter((p: {team: string}) => p.team === 'B');

  const {teamADelta, teamBDelta} = computeDoublesRatingUpdate(
    [teamA[0].rating, teamA[1].rating],
    [teamB[0].rating, teamB[1].rating],
    teamAWon,
  );

  for (const player of teamA) {
    await applyPlayerDelta(client, matchId, player.user_id, teamADelta);
  }
  for (const player of teamB) {
    await applyPlayerDelta(client, matchId, player.user_id, teamBDelta);
  }
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
async function applyPlayerDelta(client: any, matchId: string, userId: string, delta: number): Promise<void> {
  const updated = await client.query(`update users set rating = rating + $1 where id = $2 returning rating`, [delta, userId]);
  await client.query(`update match_players set rating_delta = $1 where match_id = $2 and user_id = $3`, [delta, matchId, userId]);
  await client.query(`insert into rating_history (user_id, rating, match_id) values ($1, $2, $3)`, [
    userId,
    updated.rows[0].rating,
    matchId,
  ]);
}
