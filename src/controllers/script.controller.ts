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
      return c.json({ error: 'Invalid payload' }, 400);
    }

    await c.env.BUCKET_PUBLIC.put(path, content);
    c.executionCtx.waitUntil(purgeScriptCache(c, path));

    return c.json({ success: true, path: path });
  } catch (error: any) {
    return c.json({ error: error.message }, 500);
  }
};

export const getScript = async (c: Context) => {
  const scriptPath = c.req.path.replace('/getScript', 'scripts');
  const baseUrl = new URL(c.req.url).origin;

  const replaceScript = (text: string) => {
    return text
      .replace('{{ACTION}}', '')
      .replace('{{NAME}}', '')
      .replace('https://zoee.fun', baseUrl);
  };

  return await getScriptCache(c, scriptPath, replaceScript);
};

export const getInstallScript = async (c: Context) => {
  const scriptPath = 'scripts/Install.ps1';
  const baseUrl = new URL(c.req.url).origin;

  const replaceScript = (text: string) => {
    return text.replace('https://zoee.fun', baseUrl);
  };

  return await getScriptCache(c, scriptPath, replaceScript);
};

export const getRemoteScript = async (c: Context) => {
  const action = c.req.param('action') || '';
  const name = c.req.param('name') || '';

  const scriptPath = 'scripts/Main.ps1';
  const baseUrl = new URL(c.req.url).origin;

  const replaceScript = (text: string) => {
    return text
      .replace('{{ACTION}}', action)
      .replace('{{NAME}}', name)
      .replace('https://zoee.fun', baseUrl);
  };

  return await getScriptCache(c, scriptPath, replaceScript);
};
