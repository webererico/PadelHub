import {getPool} from '../db';
import {asyncHandler} from './asyncHandler';

/** Must run after `authenticate` (needs req.uid). 403s anyone who isn't flagged is_admin. */
export const requireAdmin = asyncHandler(async (req, res, next) => {
  const pool = await getPool();
  const {rows} = await pool.query('select is_admin from users where id = $1', [req.uid]);
  if (!rows[0]?.is_admin) {
    res.status(403).json({error: 'admin_only'});
    return;
  }
  next();
});
