import type {NextFunction, Request, RequestHandler, Response} from 'express';

/**
 * Express 4 does not catch a rejected promise thrown by an async route
 * handler — it's left unhandled, which can crash the whole function
 * instance instead of just failing the one request. Wrap every async
 * handler with this so errors reach the error-handling middleware.
 */
export function asyncHandler(
  handler: (req: Request, res: Response, next: NextFunction) => Promise<void>,
): RequestHandler {
  return (req, res, next) => {
    handler(req, res, next).catch(next);
  };
}
