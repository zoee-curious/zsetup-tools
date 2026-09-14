import { Context } from 'hono';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { S3Client, GetObjectCommand } from '@aws-sdk/client-s3';

const getS3Client = (env: any) =>
  new S3Client({
    region: 'auto',
    endpoint: `https://${env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
    credentials: {
      accessKeyId: env.R2_ACCESS_KEY_ID,
      secretAccessKey: env.R2_SECRET_ACCESS_KEY,
    },
  });

export async function getAssetCache(c: Context, fileName: string) {
  const isPrivate = c.get('isPrivate');

  const indexResponse = await getIndexAssetCache(c);
  const indexMap: Record<string, string> = await indexResponse.json();

  const assetPath = indexMap[fileName];
  if (!assetPath) return null;

  let targetBucketName = c.env.BUCKET_PUBLIC_NAME;

  if (isPrivate) {
    const privateObject = await c.env.BUCKET_PRIVATE.head(assetPath);
    if (privateObject) {
      targetBucketName = c.env.BUCKET_PRIVATE_NAME;
    }
  }

  const s3 = getS3Client(c.env);
  const command = new GetObjectCommand({
    Bucket: targetBucketName,
    Key: assetPath,
  });

  return await getSignedUrl(s3, command, { expiresIn: 900 });
}

export async function getIndexAssetCache(c: Context) {
  const isPrivate = c.get('isPrivate');
  const noCache = c.get('noCache');

  const cache = caches.default;
  const baseUrl = new URL(c.req.url).origin;
  const cacheScope = isPrivate ? 'private' : 'public';
  const cacheKey = new Request(`${baseUrl}/getIndexAsset/${cacheScope}`);

  if (!noCache) {
    const cachedResponse = await cache.match(cacheKey);
    if (cachedResponse) {
      return cachedResponse;
    }
  }

  const [publicObject, privateObject] = await Promise.all([
    c.env.BUCKET_PUBLIC.get('assets/assets-index.json'),
    isPrivate
      ? c.env.BUCKET_PRIVATE.get('assets_private/assets-index.json')
      : null,
  ]);

  const publicIndex = publicObject ? await publicObject.json() : {};
  const privateIndex = privateObject ? await privateObject.json() : {};

  const finalIndex = Object.assign({}, publicIndex, privateIndex);

  const response = c.json(finalIndex, 200, {
    'Cache-Control': 'public, max-age=3600',
  });

  c.executionCtx.waitUntil(cache.put(cacheKey, response.clone()));
  return response;
}

export async function purgeAssetIndexCache(c: Context) {
  const cache = caches.default;
  const baseUrl = new URL(c.req.url).origin;

  await Promise.all([
    cache.delete(new Request(`${baseUrl}/getIndexAsset/public`)),
    cache.delete(new Request(`${baseUrl}/getIndexAsset/private`)),
  ]);
}
