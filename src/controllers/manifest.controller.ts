import { Context } from 'hono';
import {
  getIndexManifestCache,
  getManifestCache,
  purgeManifestCache,
} from '../services/manifest.service.js';

export const putManifest = async (c: Context) => {
  const isPrivate = c.get('isPrivate');

  try {
    const { path, content } = await c.req.json();
    if (!path || !content) {
      return c.json({ error: 'Invalid payload' }, 400);
    }

    const targetBucket = isPrivate ? c.env.BUCKET_PRIVATE : c.env.BUCKET_PUBLIC;
    await targetBucket.put(path, content);

    c.executionCtx.waitUntil(purgeManifestCache(c, path, content));
    return c.json({ success: true, path: path });
  } catch (error: any) {
    return c.json({ error: error.message }, 500);
  }
};

export const getManifest = async (c: Context) => {
  const name = c.req.param('name');
  const isPrivate = c.get('isPrivate');

  try {
    return await getManifestCache(c, name as string, isPrivate);
  } catch (error: any) {
    return c.json({ error: error.message }, 500);
  }
};

export const getIndexManifest = async (c: Context) => {
  const isPrivate = c.get('isPrivate');

  try {
    return await getIndexManifestCache(c, isPrivate);
  } catch (error: any) {
    return c.json({ error: error.message }, 500);
  }
};
