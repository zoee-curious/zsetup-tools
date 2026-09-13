import { Context } from 'hono';
import { load } from 'js-yaml';

export async function getManifestCache(
  c: Context,
  name: string,
  isPrivate: boolean,
) {
  const cache = caches.default;
  const baseUrl = new URL(c.req.url).origin;
  const cacheScope = isPrivate ? 'private' : 'public';
  const cacheKey = new Request(
    `${baseUrl}/getManifest/${name.toLowerCase()}/${cacheScope}`,
  );

  const cachedResponse = await cache.match(cacheKey);
  if (cachedResponse) {
    return cachedResponse;
  }

  const indexResponse = await getIndexManifestCache(c, isPrivate);
  const manifestList: any[] = await indexResponse.json();

  const targetName = name.toLowerCase();
  const targetApp = manifestList.find(
    (app: any) =>
      app.id?.toLowerCase() === targetName ||
      app.name?.toLowerCase() === targetName ||
      app.aliases?.some((alias: any) => alias.toLowerCase() === targetName),
  );

  if (!targetApp || !targetApp.path) {
    return c.json({ error: `${name} Not found!` }, 404);
  }

  let manifestObject = isPrivate
    ? await c.env.BUCKET_PRIVATE.get(targetApp.path)
    : null;
  if (!manifestObject) {
    manifestObject = await c.env.BUCKET_PUBLIC.get(targetApp.path);
  }

  if (!manifestObject) {
    return c.json(
      { error: `File manifest for ${name} not found in storage!` },
      404,
    );
  }

  const rawYaml = await manifestObject.text();
  const manifestData = load(rawYaml);

  const response = c.json(manifestData, 200, {
    'Cache-Control': 'public, max-age=86400',
  });

  c.executionCtx.waitUntil(cache.put(cacheKey, response.clone()));
  return response;
}

export async function getIndexManifestCache(c: Context, isPrivate: boolean) {
  const cache = caches.default;
  const baseUrl = new URL(c.req.url).origin;
  const cacheScope = isPrivate ? 'private' : 'public';
  const cacheKey = new Request(`${baseUrl}/getIndexManifest/${cacheScope}`);

  const cachedResponse = await cache.match(cacheKey);
  if (cachedResponse) {
    console.log(cacheKey);
    return cachedResponse;
  }

  const [publicObject, privateObject] = await Promise.all([
    c.env.BUCKET_PUBLIC.get('manifests/manifests-index.json'),
    isPrivate
      ? c.env.BUCKET_PRIVATE.get('manifests_private/manifests-index.json')
      : null,
  ]);

  const publicIndex = publicObject ? await publicObject.json() : [];
  const privateIndex = privateObject ? await privateObject.json() : [];

  const indexMap = new Map();
  if (Array.isArray(publicIndex))
    publicIndex.forEach((item: any) =>
      indexMap.set(item.id.toLowerCase(), item),
    );
  if (Array.isArray(privateIndex))
    privateIndex.forEach((item: any) =>
      indexMap.set(item.id.toLowerCase(), item),
    );

  const finalIndex = Array.from(indexMap.values());

  const response = c.json(finalIndex, 200, {
    'Cache-Control': 'public, max-age=86400',
  });

  c.executionCtx.waitUntil(cache.put(cacheKey, response.clone()));
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
  ];

  if (path.endsWith('manifests-index.json')) {
    await Promise.all(deletePromises);
    return;
  }

  try {
    const parsed = load(content) as any;
    if (!parsed) return;

    const identifiers = new Set<string>();

    if (parsed.id) identifiers.add(parsed.id.toString().toLowerCase());
    if (parsed.name) identifiers.add(parsed.name.toString().toLowerCase());

    const aliases = parsed.Aliases || parsed.aliases;
    if (Array.isArray(aliases)) {
      aliases.forEach((alias: any) => {
        if (alias) identifiers.add(alias.toString().toLowerCase());
      });
    }

    identifiers.forEach((identifier) => {
      deletePromises.push(
        cache.delete(
          new Request(`${baseUrl}/getManifest/${identifier}/public`),
        ),
        cache.delete(
          new Request(`${baseUrl}/getManifest/${identifier}/private`),
        ),
      );
    });

    await Promise.all(deletePromises);
  } catch (error) {
    console.error(`Failed to purge cache for ${path}:`, error);
  }
}
