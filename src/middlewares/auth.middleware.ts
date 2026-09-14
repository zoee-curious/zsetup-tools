import { Context, Next } from 'hono';

export async function authRequest(c: Context, next: Next) {
  const secretKey = c.env.API_KEY;
  const clientKey = c.req.header('x-api-key');
  const isPrivate = c.req.header('x-visability') === 'private';
  const ignoreCache = c.req.header('Cache-Control')?.includes('no-cache');
  const validKey = clientKey && clientKey === secretKey;

  // console.log(c.req.header('x-api-key'));
  // console.log(c.req.header('x-visability'));
  // console.log(c.req.header('Cache-Control'));
  // console.log(c.req.header('Pragma'));

  if (isPrivate && (!clientKey || clientKey !== secretKey)) {
    return c.json({ error: 'Unauthorized' }, 401);
  }

  c.set('ignoreCache', ignoreCache);
  c.set('isPrivate', isPrivate);
  c.set('validKey', validKey);

  await next();
}
