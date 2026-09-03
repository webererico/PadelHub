import type {NextFunction, Request, Response} from 'express';
import {getAuth} from 'firebase-admin/auth';

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      uid?: string;
      /** Claims carried by the verified ID token — not the Postgres profile. */
      tokenEmail?: string;
      tokenName?: string;
      tokenPicture?: string;
    }
  }
}

/** Verifies the Firebase ID token sent as `Authorization: Bearer <token>`. */
export async function authenticate(req: Request, res: Response, next: NextFunction): Promise<void> {
  const header = req.header('Authorization');
  const token = header?.startsWith('Bearer ') ? header.slice('Bearer '.length) : undefined;

  if (!token) {
    res.status(401).json({error: 'missing_token'});
    return;
  }

  try {
    const decoded = await getAuth().verifyIdToken(token);
    req.uid = decoded.uid;
    req.tokenEmail = decoded.email;
    req.tokenName = typeof decoded.name === 'string' ? decoded.name : undefined;
    req.tokenPicture = typeof decoded.picture === 'string' ? decoded.picture : undefined;
    next();
  } catch (err) {
    res.status(401).json({error: 'invalid_token'});
  }
}
