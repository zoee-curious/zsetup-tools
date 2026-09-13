import { Context, Next } from 'hono';

export async function authRequest(c: Context, next: Next) {
  const secretKey = c.env.API_KEY;
  const clientKey = c.req.header('x-api-key');
  const isPrivate = c.req.header('x-visability') === 'private';
  const validKey = clientKey && clientKey === secretKey;

  if (isPrivate && (!clientKey || clientKey !== secretKey)) {
    return c.json({ error: 'Unauthorized' }, 401);
  }

  c.set('validKey', validKey);
  c.set('isPrivate', isPrivate);
  await next();
}
