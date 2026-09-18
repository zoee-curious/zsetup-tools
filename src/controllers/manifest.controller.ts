import { Context } from 'hono';
import {
  getIndexManifestCache,
  getManifestCache,
  purgeManifestCache,
} from '../services/manifest.service.js';

export const putManifest = async (c: Context) => {
  const validKey = c.get('validKey');
  try {
    const { path, content } = await c.req.json();
    if (!validKey || !path || !content) {
      return c.json({ error: 'Unauthorized or Invalid payload' }, 401);
    }

    await c.get('targetBucket').put(path, content);
    c.executionCtx.waitUntil(purgeManifestCache(c, path, content));

    return c.json(200);
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

export const getSearchIndexManifest = async (c: Context) => {
  try {
    return await getIndexManifestCache(c, true);
  } catch (error: any) {
    return c.json({ error: error.message }, 500);
  }
};
