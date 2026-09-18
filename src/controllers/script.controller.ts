import { Context } from 'hono';
import {
  getScriptCache,
  purgeScriptCache,
} from '../services/script.service.js';

export const putScript = async (c: Context) => {
  const validKey = c.get('validKey');
  try {
    const { path, content } = await c.req.json();
    if (!validKey || !path || !content) {
      return c.json({ error: 'Unauthorized or Invalid payload' }, 401);
    }

    await c.env.BUCKET_PUBLIC.put(path, content);
    c.executionCtx.waitUntil(purgeScriptCache(c));

    return c.json(200);
  } catch (error: any) {
    return c.json({ error: error.message }, 500);
  }
};

export const getScript = async (c: Context) => {
  const scriptPath = 'scripts/zst.ps1';
  return await getScriptCache(c, scriptPath);
};

export const getInstallScript = async (c: Context) => {
  const scriptPath = 'scripts/zst.ps1';

  const replaceScript = (text: string) => {
    return text
      .replace('$Action', '$Action = "install"')
      .replace('$Name', '$Name = "update"');
  };

  return await getScriptCache(c, scriptPath, replaceScript);
};

export const getRemoteScript = async (c: Context) => {
  const action = c.req.param('action');
  const name = c.req.param('name');
  const scriptPath = 'scripts/zst.ps1';

  const replaceScript = (text: string) => {
    return text
      .replace('$Action', `$Action = "${action}"`)
      .replace('$Name', `$Name = "${name}"`);
  };

  return await getScriptCache(c, scriptPath, replaceScript);
};
