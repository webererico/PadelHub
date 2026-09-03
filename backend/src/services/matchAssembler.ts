import type {Pool} from 'pg';

export interface MatchPlayerJson {
  id: string;
  name: string;
  photoUrl: string | null;
}

export interface MatchJson {
  id: string;
  format: string;
  status: string;
  teamA: MatchPlayerJson[];
  teamB: MatchPlayerJson[];
  sets: {teamA: number; teamB: number}[];
  playedAt: string;
  arenaName: string | null;
  ratingDelta: number | null;
  kudosCount: number;
  commentCount: number;
}

/** Loads full match payloads (players, sets, counts) for a set of match ids. */
export async function assembleMatches(pool: Pool, matchIds: string[], viewerId?: string): Promise<MatchJson[]> {
  if (matchIds.length === 0) return [];

  const [matchesRes, setsRes, playersRes, kudosRes, commentsRes] = await Promise.all([
    pool.query(
      `select m.id, m.format, m.status, m.played_at, a.name as arena_name
       from matches m
       left join arenas a on a.id = m.arena_id
       where m.id = any($1::uuid[])`,
      [matchIds],
    ),
    pool.query(
      `select match_id, set_index, team_a_games, team_b_games
       from match_sets where match_id = any($1::uuid[]) order by match_id, set_index`,
      [matchIds],
    ),
    pool.query(
      `select mp.match_id, mp.team, mp.rating_delta, u.id as user_id, u.name, u.photo_url
       from match_players mp
       join users u on u.id = mp.user_id
       where mp.match_id = any($1::uuid[])`,
      [matchIds],
    ),
    pool.query(
      `select match_id, count(*)::int as count from kudos where match_id = any($1::uuid[]) group by match_id`,
      [matchIds],
    ),
    pool.query(
      `select match_id, count(*)::int as count from comments where match_id = any($1::uuid[]) group by match_id`,
      [matchIds],
    ),
  ]);

  const kudosByMatch = new Map<string, number>(kudosRes.rows.map((r) => [r.match_id, r.count]));
  const commentsByMatch = new Map<string, number>(commentsRes.rows.map((r) => [r.match_id, r.count]));

  return matchesRes.rows.map((match) => {
    const players = playersRes.rows.filter((p) => p.match_id === match.id);
    const teamA = players.filter((p) => p.team === 'A');
    const teamB = players.filter((p) => p.team === 'B');
    const viewerPlayer = viewerId ? players.find((p) => p.user_id === viewerId) : undefined;

    return {
      id: match.id,
      format: match.format,
      status: statusToCamel(match.status),
      teamA: teamA.map(toPlayerJson),
      teamB: teamB.map(toPlayerJson),
      sets: setsRes.rows
        .filter((s) => s.match_id === match.id)
        .map((s) => ({teamA: s.team_a_games, teamB: s.team_b_games})),
      playedAt: match.played_at.toISOString(),
      arenaName: match.arena_name,
      ratingDelta: viewerPlayer?.rating_delta ?? null,
      kudosCount: kudosByMatch.get(match.id) ?? 0,
      commentCount: commentsByMatch.get(match.id) ?? 0,
    };
  });
}

function toPlayerJson(row: {user_id: string; name: string; photo_url: string | null}): MatchPlayerJson {
  return {id: row.user_id, name: row.name, photoUrl: row.photo_url};
}

/** DB stores snake_case status; the Flutter client's MatchStatus enum is camelCase. */
function statusToCamel(status: string): string {
  return status.replace(/_([a-z])/g, (_, c: string) => c.toUpperCase());
}
