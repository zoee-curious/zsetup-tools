import { Context } from 'hono';

export async function getScriptCache(
  c: Context,
  scriptPath: string,
  transform?: (text: string) => string,
) {
  const noCache = c.get('noCache');

  const cache = caches.default;
  const cacheKey = new Request(c.req.url, c.req.raw);

  if (!noCache) {
    const cachedResponse = await cache.match(cacheKey);
    if (cachedResponse) {
      return cachedResponse;
    }
  }

  try {
    const script = await c.env.BUCKET_PUBLIC.get(scriptPath);
    if (!script) {
      return c.json({ error: `${scriptPath} Not found!` }, 404);
    }

    const headers = new Headers();
    script.writeHttpMetadata(headers);
    headers.set('Content-Type', 'text/plain; charset=utf-8');

    const cacheControlHeader = noCache
      ? 'no-store, no-cache, must-revalidate, proxy-revalidate'
      : 'public, max-age=3600';

    headers.set('Cache-Control', cacheControlHeader);

    let response: Response;
    if (transform) {
      const originalText = await script.text();
      const modifiedText = transform(originalText);
      response = c.text(modifiedText, 200, Object.fromEntries(headers));
    } else {
      response = c.body(script.body, 200, Object.fromEntries(headers));
    }

    if (!noCache && response.status === 200) {
      c.executionCtx.waitUntil(cache.put(cacheKey, response.clone()));
    }

    return response;
  } catch (error: any) {
    return c.json({ error: error.message }, 500);
  }
}

export async function purgeMainScriptCache(c: Context) {
  const cache = caches.default;
  const baseUrl = new URL(c.req.url).origin;
  const actions = ['state', 'search', 'show', 'install'];

  try {
    const [publicObject, privateObject] = await Promise.all([
      c.env.BUCKET_PUBLIC.get('manifests/manifests-index.json'),
      c.env.BUCKET_PRIVATE.get('manifests_private/manifests-index.json'),
    ]);

    const publicIndex: Record<string, string> = publicObject
      ? await publicObject.json()
      : {};
    const privateIndex: Record<string, string> = privateObject
      ? await privateObject.json()
      : {};

    const combinedIndex = { ...publicIndex, ...privateIndex };
    const identifiers = Object.keys(combinedIndex);

    const deletePromises: Promise<boolean>[] = [];

    for (const identifier of identifiers) {
      for (const action of actions) {
        const targetUrl = `${baseUrl}/${action}/${identifier}`;
        deletePromises.push(cache.delete(new Request(targetUrl)));
      }
    }

    await Promise.all(deletePromises);
  } catch (error) {
    console.error('Failed to purge main script cache:', error);
  }
}

export async function purgeScriptCache(c: Context) {
  const cache = caches.default;
  const baseUrl = new URL(c.req.url).origin;

  c.executionCtx.waitUntil(purgeMainScriptCache(c));
  await cache.delete(new Request(`${baseUrl}/install`));
  await cache.delete(new Request(`${baseUrl}/getScript`));
}
