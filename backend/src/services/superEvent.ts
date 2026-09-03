/**
 * Super 8 / Super 12 schedule generation via the circle method.
 *
 * Standard round-robin circle method pairs each player against a different
 * opponent every round; here we reinterpret each round's "meeting pairs" as
 * PARTNERSHIPS instead of opponents. Over n-1 rounds every player partners
 * with every other player exactly once. The n/2 partnerships generated per
 * round are then grouped, two at a time, into n/4 courts (2 partnerships =
 * 4 players per court).
 */

export interface ScheduledMatch {
  roundIndex: number;
  courtNumber: number;
  teamA: [string, string];
  teamB: [string, string];
}

export function generateSchedule(playerIds: string[]): ScheduledMatch[] {
  const n = playerIds.length;
  if (n !== 8 && n !== 12) {
    throw new Error('generateSchedule expects exactly 8 or 12 players');
  }
  if (new Set(playerIds).size !== n) {
    throw new Error('playerIds must be distinct');
  }

  const rounds = n - 1;
  const fixed = playerIds[0];
  let rotating = playerIds.slice(1);

  const schedule: ScheduledMatch[] = [];

  for (let round = 0; round < rounds; round++) {
    const circle = [fixed, ...rotating];
    const partnerships: [string, string][] = [];
    for (let i = 0; i < n / 2; i++) {
      partnerships.push([circle[i], circle[n - 1 - i]]);
    }

    for (let court = 0; court < n / 4; court++) {
      const teamA = partnerships[court * 2];
      const teamB = partnerships[court * 2 + 1];
      schedule.push({roundIndex: round, courtNumber: court + 1, teamA, teamB});
    }

    rotating = [rotating[rotating.length - 1], ...rotating.slice(0, rotating.length - 1)];
  }

  return schedule;
}

export interface EventRoundRow {
  id: string;
  roundIndex: number;
  courtNumber: number;
  teamAPlayerIds: string[];
  teamBPlayerIds: string[];
  teamAGames: number | null;
  teamBGames: number | null;
}

export interface EventStanding {
  userId: string;
  gamesWon: number;
  gamesLost: number;
  roundsWon: number;
  roundsPlayed: number;
}

/** Individual standings: a player's team changes every round, so each player's tally is the sum across every round they took part in. */
export function computeStandings(rounds: EventRoundRow[]): EventStanding[] {
  const byPlayer = new Map<string, EventStanding>();

  const ensure = (userId: string): EventStanding => {
    let s = byPlayer.get(userId);
    if (!s) {
      s = {userId, gamesWon: 0, gamesLost: 0, roundsWon: 0, roundsPlayed: 0};
      byPlayer.set(userId, s);
    }
    return s;
  };

  for (const round of rounds) {
    if (round.teamAGames === null || round.teamBGames === null) continue;
    const aWon = round.teamAGames > round.teamBGames;

    for (const userId of round.teamAPlayerIds) {
      const s = ensure(userId);
      s.gamesWon += round.teamAGames;
      s.gamesLost += round.teamBGames;
      s.roundsPlayed += 1;
      if (aWon) s.roundsWon += 1;
    }
    for (const userId of round.teamBPlayerIds) {
      const s = ensure(userId);
      s.gamesWon += round.teamBGames;
      s.gamesLost += round.teamAGames;
      s.roundsPlayed += 1;
      if (!aWon) s.roundsWon += 1;
    }
  }

  return Array.from(byPlayer.values()).sort((a, b) => {
    if (b.gamesWon !== a.gamesWon) return b.gamesWon - a.gamesWon;
    const diffA = a.gamesWon - a.gamesLost;
    const diffB = b.gamesWon - b.gamesLost;
    return diffB - diffA;
  });
}
