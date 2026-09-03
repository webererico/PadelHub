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
        await awardBadges(client, matchId);
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

matchesRouter.get(
  '/:matchId/comments',
  asyncHandler(async (req, res) => {
    const pool = await getPool();
    const {rows} = await pool.query(
      `select c.id, c.user_id, u.name as user_name, c.body, c.created_at
       from comments c
       join users u on u.id = c.user_id
       where c.match_id = $1
       order by c.created_at asc`,
      [req.params.matchId],
    );
    res.json(
      rows.map((r) => ({
        id: r.id,
        userId: r.user_id,
        userName: r.user_name,
        body: r.body,
        createdAt: r.created_at.toISOString(),
      })),
    );
  }),
);

matchesRouter.post(
  '/:matchId/comments',
  asyncHandler(async (req, res) => {
    const body = (req.body as {body?: string})?.body?.trim();
    if (!body) {
      res.status(400).json({error: 'invalid_payload'});
      return;
    }
    const pool = await getPool();
    const {rows} = await pool.query(
      `insert into comments (match_id, user_id, body) values ($1, $2, $3)
       returning id, created_at`,
      [req.params.matchId, req.uid, body],
    );
    const me = await pool.query(`select name from users where id = $1`, [req.uid]);
    res.status(201).json({
      id: rows[0].id,
      userId: req.uid,
      userName: me.rows[0]?.name ?? 'Jogador',
      body,
      createdAt: rows[0].created_at.toISOString(),
    });
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

/**
 * Checks the badge rules that are derivable from data we already have.
 * "Inimigo do Erro" (fewest unforced errors) isn't implementable yet —
 * nothing tracks in-match error stats.
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
async function awardBadges(client: any, matchId: string): Promise<void> {
  const sets = await client.query(
    `select team_a_games, team_b_games from match_sets where match_id = $1`,
    [matchId],
  );
  const players = await client.query(`select user_id, team from match_players where match_id = $1`, [matchId]);
  const teamA: string[] = players.rows.filter((p: {team: string}) => p.team === 'A').map((p: {user_id: string}) => p.user_id);
  const teamB: string[] = players.rows.filter((p: {team: string}) => p.team === 'B').map((p: {user_id: string}) => p.user_id);

  // Pneu Furado: won a set 6-0 (either side, possibly both across different sets).
  const teamAGotSixLove = sets.rows.some((s: {team_a_games: number; team_b_games: number}) => s.team_a_games === 6 && s.team_b_games === 0);
  const teamBGotSixLove = sets.rows.some((s: {team_a_games: number; team_b_games: number}) => s.team_b_games === 6 && s.team_a_games === 0);
  const sixLoveWinners = [...(teamAGotSixLove ? teamA : []), ...(teamBGotSixLove ? teamB : [])];
  for (const userId of sixLoveWinners) {
    await client.query(`insert into player_badges (user_id, badge_type) values ($1, 'pneu_furado') on conflict do nothing`, [userId]);
  }

  // Nômade do Padel: played at 5+ distinct arenas.
  for (const userId of [...teamA, ...teamB]) {
    const arenaCount = await client.query(
      `select count(distinct m.arena_id)::int as count
       from matches m
       join match_players mp on mp.match_id = m.id
       where mp.user_id = $1 and m.arena_id is not null and m.status = 'confirmed'`,
      [userId],
    );
    if ((arenaCount.rows[0]?.count ?? 0) >= 5) {
      await client.query(`insert into player_badges (user_id, badge_type) values ($1, 'nomade_do_padel') on conflict do nothing`, [userId]);
    }
  }
}
