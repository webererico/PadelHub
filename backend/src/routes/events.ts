import {Router} from 'express';

import {getPool} from '../db';
import {asyncHandler} from '../middleware/asyncHandler';
import {computeStandings, generateSchedule, type EventRoundRow} from '../services/superEvent';

export const eventsRouter = Router();

const FORMAT_SIZES: Record<string, number> = {super8: 8, super12: 12};

eventsRouter.get(
  '/',
  asyncHandler(async (_req, res) => {
    const pool = await getPool();
    const {rows} = await pool.query(
      `select e.id, e.name, e.format, e.status, e.arena_id, e.created_at,
         (select count(*)::int from super_event_players p where p.event_id = e.id) as player_count
       from super_events e
       order by e.created_at desc
       limit 30`,
    );
    res.json(
      rows.map((row) => ({
        id: row.id,
        name: row.name,
        format: row.format,
        status: row.status,
        arenaId: row.arena_id,
        playerCount: row.player_count,
        createdAt: row.created_at.toISOString(),
      })),
    );
  }),
);

eventsRouter.post(
  '/',
  asyncHandler(async (req, res) => {
    const {name, format, playerIds, arenaId} = req.body as {
      name?: string;
      format?: string;
      playerIds?: string[];
      arenaId?: string;
    };

    const expectedSize = format ? FORMAT_SIZES[format] : undefined;
    if (!name?.trim() || !expectedSize || !Array.isArray(playerIds) || playerIds.length !== expectedSize) {
      res.status(400).json({error: 'invalid_payload'});
      return;
    }
    if (new Set(playerIds).size !== playerIds.length) {
      res.status(400).json({error: 'duplicate_players'});
      return;
    }
    if (!playerIds.includes(req.uid!)) {
      res.status(403).json({error: 'must_be_a_participant'});
      return;
    }

    let schedule;
    try {
      schedule = generateSchedule(playerIds);
    } catch {
      res.status(400).json({error: 'invalid_payload'});
      return;
    }

    const pool = await getPool();
    const client = await pool.connect();
    try {
      await client.query('begin');

      const eventRes = await client.query(
        `insert into super_events (name, format, arena_id, created_by) values ($1, $2, $3, $4) returning id`,
        [name.trim(), format, arenaId ?? null, req.uid],
      );
      const eventId = eventRes.rows[0].id;

      for (const userId of playerIds) {
        await client.query(`insert into super_event_players (event_id, user_id) values ($1, $2)`, [eventId, userId]);
      }
      for (const match of schedule) {
        await client.query(
          `insert into super_event_rounds (event_id, round_index, court_number, team_a_player_ids, team_b_player_ids)
           values ($1, $2, $3, $4, $5)`,
          [eventId, match.roundIndex, match.courtNumber, match.teamA, match.teamB],
        );
      }

      await client.query('commit');
      res.status(201).json(await loadEvent(pool, eventId));
    } catch (err) {
      await client.query('rollback');
      res.status(500).json({error: 'could_not_create_event'});
    } finally {
      client.release();
    }
  }),
);

eventsRouter.get(
  '/:eventId',
  asyncHandler(async (req, res) => {
    const pool = await getPool();
    const event = await loadEvent(pool, req.params.eventId);
    if (!event) {
      res.status(404).json({error: 'event_not_found'});
      return;
    }
    res.json(event);
  }),
);

eventsRouter.post(
  '/:eventId/rounds/:roundId/score',
  asyncHandler(async (req, res) => {
    const {teamAGames, teamBGames} = req.body as {teamAGames?: number; teamBGames?: number};
    if (
      !Number.isInteger(teamAGames) ||
      !Number.isInteger(teamBGames) ||
      teamAGames! < 0 ||
      teamBGames! < 0 ||
      teamAGames! > 6 ||
      teamBGames! > 6 ||
      teamAGames === teamBGames
    ) {
      res.status(400).json({error: 'invalid_score'});
      return;
    }

    const pool = await getPool();
    const client = await pool.connect();
    try {
      await client.query('begin');

      const roundRes = await client.query(
        `select team_a_player_ids, team_b_player_ids from super_event_rounds
         where id = $1 and event_id = $2`,
        [req.params.roundId, req.params.eventId],
      );
      if (roundRes.rowCount === 0) {
        await client.query('rollback');
        res.status(404).json({error: 'round_not_found'});
        return;
      }
      const players: string[] = [...roundRes.rows[0].team_a_player_ids, ...roundRes.rows[0].team_b_player_ids];
      if (!players.includes(req.uid!)) {
        await client.query('rollback');
        res.status(403).json({error: 'not_a_participant'});
        return;
      }

      await client.query(`update super_event_rounds set team_a_games = $1, team_b_games = $2 where id = $3`, [
        teamAGames,
        teamBGames,
        req.params.roundId,
      ]);

      const remaining = await client.query(
        `select count(*)::int as count from super_event_rounds where event_id = $1 and team_a_games is null`,
        [req.params.eventId],
      );
      const newStatus = remaining.rows[0].count === 0 ? 'completed' : 'in_progress';
      await client.query(`update super_events set status = $1 where id = $2 and status != $1`, [newStatus, req.params.eventId]);

      await client.query('commit');
      res.json(await loadEvent(pool, req.params.eventId));
    } catch (err) {
      await client.query('rollback');
      res.status(500).json({error: 'could_not_score_round'});
    } finally {
      client.release();
    }
  }),
);

// eslint-disable-next-line @typescript-eslint/no-explicit-any
async function loadEvent(pool: any, eventId: string) {
  const eventRes = await pool.query(
    `select e.id, e.name, e.format, e.status, e.arena_id, e.created_at
     from super_events e where e.id = $1`,
    [eventId],
  );
  if (eventRes.rowCount === 0) return null;
  const event = eventRes.rows[0];

  const playersRes = await pool.query(
    `select u.id, u.name from super_event_players p join users u on u.id = p.user_id where p.event_id = $1 order by u.name`,
    [eventId],
  );

  const roundsRes = await pool.query(
    `select r.id, r.round_index, r.court_number, r.team_a_player_ids, r.team_b_player_ids, r.team_a_games, r.team_b_games
     from super_event_rounds r where r.event_id = $1 order by r.round_index, r.court_number`,
    [eventId],
  );

  const playerNames = new Map<string, string>(playersRes.rows.map((p: {id: string; name: string}) => [p.id, p.name]));

  const rounds: EventRoundRow[] = roundsRes.rows.map(
    (r: {
      id: string;
      round_index: number;
      court_number: number;
      team_a_player_ids: string[];
      team_b_player_ids: string[];
      team_a_games: number | null;
      team_b_games: number | null;
    }) => ({
      id: r.id,
      roundIndex: r.round_index,
      courtNumber: r.court_number,
      teamAPlayerIds: r.team_a_player_ids,
      teamBPlayerIds: r.team_b_player_ids,
      teamAGames: r.team_a_games,
      teamBGames: r.team_b_games,
    }),
  );

  const standings = computeStandings(rounds).map((s) => ({
    userId: s.userId,
    name: playerNames.get(s.userId) ?? 'Jogador',
    gamesWon: s.gamesWon,
    gamesLost: s.gamesLost,
    roundsWon: s.roundsWon,
    roundsPlayed: s.roundsPlayed,
  }));

  return {
    id: event.id,
    name: event.name,
    format: event.format,
    status: event.status,
    arenaId: event.arena_id,
    createdAt: event.created_at.toISOString(),
    players: playersRes.rows.map((p: {id: string; name: string}) => ({id: p.id, name: p.name})),
    rounds: rounds.map((r) => ({
      id: r.id,
      roundIndex: r.roundIndex,
      courtNumber: r.courtNumber,
      teamAPlayerIds: r.teamAPlayerIds,
      teamBPlayerIds: r.teamBPlayerIds,
      teamAPlayerNames: r.teamAPlayerIds.map((id) => playerNames.get(id) ?? 'Jogador'),
      teamBPlayerNames: r.teamBPlayerIds.map((id) => playerNames.get(id) ?? 'Jogador'),
      teamAGames: r.teamAGames,
      teamBGames: r.teamBGames,
    })),
    standings,
  };
}
