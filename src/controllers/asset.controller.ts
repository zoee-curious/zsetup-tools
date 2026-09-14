import { Context } from 'hono';
import {
  getAssetCache,
  getIndexAssetCache,
  purgeAssetIndexCache,
} from '../services/assets.service.js';

export const putAssetIndex = async (c: Context) => {
  const validKey = c.get('validKey');
  const isPrivate = c.get('isPrivate');
  try {
    const { path, content } = await c.req.json();
    if (!validKey || !path || !content) {
      return c.json({ error: 'Unauthorized or Invalid payload' }, 401);
    }

    const targetBucket = isPrivate ? c.env.BUCKET_PRIVATE : c.env.BUCKET_PUBLIC;
    await targetBucket.put(path, content);

    c.executionCtx.waitUntil(purgeAssetIndexCache(c));
    return c.json({ success: true, path: path });
  } catch (error: any) {
    return c.json({ error: error.message }, 500);
  }
};

export const getAsset = async (c: Context) => {
  const rawFileName = c.req.path.replace(/^\/download\//, '');
  const fileName = decodeURIComponent(rawFileName);
  try {
    const assetUrl = await getAssetCache(c, fileName);
    if (!assetUrl) {
      return c.json({ error: `${fileName} Not found!` }, 404);
    }

    return c.redirect(assetUrl, 302);
  } catch (error: any) {
    return c.json({ error: error.message }, 500);
  }
};

export const getIndexAsset = async (c: Context) => {
  try {
    return await getIndexAssetCache(c);
  } catch (error: any) {
    return c.json({ error: error.message }, 500);
  }
};
