import { Context, Next } from 'hono';

export async function authRequest(c: Context, next: Next) {
  const secretKey = c.env.API_KEY;
  const scope = c.req.header('x-scope');
  const clientKey = c.req.header('x-api-key');
  const cacheHeader = c.req.header('Cache-Control') || c.req.header('Pragma');
  const cacheQuery = c.req.query('nocache');

  const noCache = Boolean(
    cacheHeader?.includes('no-cache') ||
    cacheHeader?.includes('no-store') ||
    cacheQuery === 'true',
  );

  const isPrivate = Boolean(scope === 'private');
  const validKey = Boolean(clientKey && secretKey && clientKey === secretKey);

  if (isPrivate && !validKey) {
    return c.json({ error: 'Unauthorized' }, 401);
  }

  c.set('noCache', noCache);
  c.set('isPrivate', isPrivate);
  c.set('validKey', validKey);

  c.set('cacheScope', isPrivate ? 'private' : 'public');
  c.set('targetBucket', isPrivate ? c.env.BUCKET_PRIVATE : c.env.BUCKET_PUBLIC);
  c.set(
    'targetBucketName',
    isPrivate ? c.env.BUCKET_PRIVATE_NAME : c.env.BUCKET_PUBLIC_NAME,
  );

  await next();
}
