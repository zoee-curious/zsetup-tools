import { Context } from 'hono';
import { load } from 'js-yaml';

export async function getManifestCache(c: Context, name: string) {
  const noCache = c.get('noCache');
  const isPrivate = c.get('isPrivate');

  const cache = caches.default;
  const baseUrl = new URL(c.req.url).origin;
  const cacheKey = new Request(
    `${baseUrl}/getManifest/${name.toLowerCase()}/${c.get('cacheScope')}`,
  );

  if (!noCache) {
    const cachedResponse = await cache.match(cacheKey);
    if (cachedResponse) {
      return cachedResponse;
    }
  }

  const indexResponse = await getIndexManifestCache(c);
  const manifestIndex: Record<string, string> = await indexResponse.json();

  const targetName = name.toLowerCase();
  const targetPath = manifestIndex[targetName];

  if (!targetPath) {
    return c.json({ error: `${name} Not found!` }, 404);
  }

  let manifestObject = isPrivate
    ? await c.env.BUCKET_PRIVATE.get(targetPath)
    : null;

  if (!manifestObject) {
    manifestObject = await c.env.BUCKET_PUBLIC.get(targetPath);
  }

  if (!manifestObject) {
    return c.json({ error: `${name} Not found in storage!` }, 404);
  }

  const rawYaml = await manifestObject.text();
  const manifestData = load(rawYaml);

  const cacheControlHeader = noCache
    ? 'no-store, no-cache, must-revalidate, proxy-revalidate'
    : 'public, max-age=3600';

  const response = c.json(manifestData, 200, {
    'Cache-Control': cacheControlHeader,
  });

  if (!noCache && response.status === 200) {
    c.executionCtx.waitUntil(cache.put(cacheKey, response.clone()));
  }

  return response;
}

export async function getIndexManifestCache(c: Context, isSearch = false) {
  const noCache = c.get('noCache');
  const isPrivate = c.get('isPrivate');

  const endpointRequest = isSearch
    ? 'getSearchIndexManifest'
    : 'getIndexManifest';

  const cache = caches.default;
  const baseUrl = new URL(c.req.url).origin;
  const cacheKey = new Request(
    `${baseUrl}/${endpointRequest}/${c.get('cacheScope')}`,
  );

  if (!noCache) {
    const cachedResponse = await cache.match(cacheKey);
    if (cachedResponse) {
      return cachedResponse;
    }
  }

  const publicIndexPath = isSearch
    ? 'manifests/manifests-search-index.json'
    : 'manifests/manifests-index.json';
  const privateIndexPath = isSearch
    ? 'manifests_private/manifests-search-index.json'
    : 'manifests_private/manifests-index.json';

  const [publicObject, privateObject] = await Promise.all([
    c.env.BUCKET_PUBLIC.get(publicIndexPath),
    isPrivate ? c.env.BUCKET_PRIVATE.get(privateIndexPath) : null,
  ]);

  const defaultValue = isSearch ? [] : {};

  const publicIndex = publicObject ? await publicObject.json() : defaultValue;
  const privateIndex = privateObject
    ? await privateObject.json()
    : defaultValue;

  const finalIndex = isSearch
    ? [...(publicIndex as any[]), ...(privateIndex as any[])]
    : { ...publicIndex, ...privateIndex };

  const cacheControlHeader = noCache
    ? 'no-store, no-cache, must-revalidate, proxy-revalidate'
    : 'public, max-age=3600';

  const response = c.json(finalIndex, 200, {
    'Cache-Control': cacheControlHeader,
  });

  if (!noCache && response.status === 200) {
    c.executionCtx.waitUntil(cache.put(cacheKey, response.clone()));
  }

  return response;
}

export async function purgeManifestCache(
  c: Context,
  path: string,
  content: string,
) {
  const cache = caches.default;
  const baseUrl = new URL(c.req.url).origin;

  const deletePromises: Promise<boolean>[] = [
    cache.delete(new Request(`${baseUrl}/getIndexManifest/public`)),
    cache.delete(new Request(`${baseUrl}/getIndexManifest/private`)),
    cache.delete(new Request(`${baseUrl}/getSearchIndexManifest/public`)),
    cache.delete(new Request(`${baseUrl}/getSearchIndexManifest/private`)),
  ];

  if (
    path.endsWith('manifests-index.json') ||
    path.endsWith('manifests-search-index.json')
  ) {
    await Promise.all(deletePromises);
    return;
  }

  try {
    const parsed = load(content) as any;
    if (!parsed) return;

    const rawIdentifiers = [
      parsed.Id || parsed.id,
      parsed.Name || parsed.name,
      ...(Array.isArray(parsed.Aliases || parsed.aliases)
        ? parsed.Aliases || parsed.aliases
        : []),
    ];

    const identifiers = new Set(
      rawIdentifiers
        .filter(Boolean)
        .map((item) => item.toString().toLowerCase()),
    );

    for (const identifier of identifiers) {
      deletePromises.push(
        cache.delete(
          new Request(`${baseUrl}/getManifest/${identifier}/public`),
        ),
        cache.delete(
          new Request(`${baseUrl}/getManifest/${identifier}/private`),
        ),
      );
    }

    await Promise.all(deletePromises);
  } catch (error) {
    console.error(`Failed to purge cache for ${path}:`, error);
  }
}
