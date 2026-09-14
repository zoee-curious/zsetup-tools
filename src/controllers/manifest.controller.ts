import { Context } from 'hono';
import {
  getIndexManifestCache,
  getManifestCache,
  purgeManifestCache,
} from '../services/manifest.service.js';

export const putManifest = async (c: Context) => {
  const validKey = c.get('validKey');
  const isPrivate = c.get('isPrivate');
  try {
    const { path, content } = await c.req.json();
    if (!validKey || !path || !content) {
      return c.json({ error: 'Unauthorized or Invalid payload' }, 401);
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
  try {
    return await getManifestCache(c, name as string);
  } catch (error: any) {
    return c.json({ error: error.message }, 500);
  }
};

export const getIndexManifest = async (c: Context) => {
  try {
    return await getIndexManifestCache(c);
  } catch (error: any) {
    return c.json({ error: error.message }, 500);
  }
};
