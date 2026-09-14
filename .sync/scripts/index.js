import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import { glob } from 'glob';
import { config } from 'dotenv';

config();

const API_KEY = process.env.API_KEY;
const API_URL = process.env.API_URL || 'http://127.0.0.1:8787';

const HASH_CACHE_FILE = path.join(
  process.cwd(),
  '.sync',
  'scripts',
  'cache',
  'cache-hash.json',
);

function loadHashCache() {
  if (fs.existsSync(HASH_CACHE_FILE)) {
    try {
      return JSON.parse(fs.readFileSync(HASH_CACHE_FILE, 'utf8'));
    } catch {
      return {};
    }
  }
  return {};
}

function saveHashCache(cacheData) {
  const dir = path.dirname(HASH_CACHE_FILE);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  fs.writeFileSync(HASH_CACHE_FILE, JSON.stringify(cacheData, null, 2));
}

function calculateHash(content) {
  return crypto.createHash('md5').update(content).digest('hex');
}

export async function syncScripts({
  globPattern = 'scripts/**/*.ps1',
  endpoint = '/putScript',
  forced = process.env.FORCE_SYNC === 'true',
  apiUrl = API_URL,
  apiKey = API_KEY,
} = {}) {
  console.log(`\nStarting sync scripts for pattern: "${globPattern}"...`);

  const localFiles = (await glob(globPattern)).sort();
  const hashCache = loadHashCache();
  let updatedCount = 0;

  for (const filePath of localFiles) {
    const filePathNormalized = filePath.replace(/\\/g, '/');

    const content = fs.readFileSync(filePath, 'utf8');
    const currentHash = calculateHash(content);

    if (hashCache[filePathNormalized] === currentHash && !forced) {
      console.log(`[SKIP] Unchanged: ${filePathNormalized}`);
      continue;
    }

    try {
      const url = `${apiUrl}${endpoint}`;
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
        body: JSON.stringify({
          path: filePathNormalized,
          content: content,
        }),
      });

      if (response.ok) {
        console.log(`[OK] Uploaded: ${filePathNormalized}`);
        hashCache[filePathNormalized] = currentHash;
        updatedCount++;
      } else {
        console.error(
          `[FAIL] ${filePathNormalized} (Status: ${response.status})`,
        );
      }
    } catch (err) {
      console.error(
        `[ERROR] Failed uploading ${filePathNormalized}:`,
        err.message,
      );
    }
  }

  if (updatedCount > 0) {
    saveHashCache(hashCache);
    console.log(`Successfully synced ${updatedCount} script(s).`);
  } else {
    console.log('No scripts updated.');
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  syncScripts().catch((err) => {
    console.error('Scripts sync failed:', err);
    process.exit(1);
  });
}
