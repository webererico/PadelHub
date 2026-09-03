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

app.use('/matches', matchesRouter);
app.use('/ranking', rankingRouter);
app.use('/arenas', arenasRouter);
app.use('/users', usersRouter);
app.use('/events', eventsRouter);

app.use((err: unknown, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error(err);
  res.status(500).json({error: 'internal_error'});
});

export const api = functions.onRequest(
  {region: 'southamerica-east1', cors: true, secrets: ['DB_PASSWORD']},
  app,
);
