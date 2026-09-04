import cors from 'cors';
import express from 'express';
import {initializeApp} from 'firebase-admin/app';
import * as functions from 'firebase-functions/v2/https';

import {authenticate} from './middleware/authenticate';
import {arenasRouter} from './routes/arenas';
import {eventsRouter} from './routes/events';
import {matchesRouter} from './routes/matches';
import {rankingRouter} from './routes/ranking';
import {usersRouter} from './routes/users';

initializeApp();

const app = express();
app.use(cors({origin: true}));
app.use(express.json());
app.use(authenticate);

// Firebase Hosting's rewrite forwards the full matched path to the function
// (it does not strip the "/api" prefix from the "/api/**" source pattern),
// so the routes have to be mounted here to match what actually arrives.
app.use('/api/matches', matchesRouter);
app.use('/api/ranking', rankingRouter);
app.use('/api/arenas', arenasRouter);
app.use('/api/users', usersRouter);
app.use('/api/events', eventsRouter);

app.use((err: unknown, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error(err);
  res.status(500).json({error: 'internal_error'});
});

export const api = functions.onRequest(
  {region: 'southamerica-east1', cors: true, secrets: ['DB_PASSWORD']},
  app,
);
