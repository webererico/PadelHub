/**
 * Doubles ELO rating, matching the concept spec: beating a much stronger
 * pair grants a large gain, losing to one costs very little — and vice
 * versa. Each team's rating is the average of its two players; the same
 * delta is then applied to both players on that team.
 */

const DEFAULT_K_FACTOR = 32;

export interface RatingUpdate {
  teamADelta: number;
  teamBDelta: number;
}

function expectedScore(ratingA: number, ratingB: number): number {
  return 1 / (1 + 10 ** ((ratingB - ratingA) / 400));
}

export function computeDoublesRatingUpdate(
  teamARatings: [number, number],
  teamBRatings: [number, number],
  teamAWon: boolean,
  kFactor: number = DEFAULT_K_FACTOR,
): RatingUpdate {
  const teamARating = (teamARatings[0] + teamARatings[1]) / 2;
  const teamBRating = (teamBRatings[0] + teamBRatings[1]) / 2;

  const expectedA = expectedScore(teamARating, teamBRating);
  const actualA = teamAWon ? 1 : 0;

  const teamADelta = Math.round(kFactor * (actualA - expectedA));
  const teamBDelta = -teamADelta;

  return {teamADelta, teamBDelta};
}
