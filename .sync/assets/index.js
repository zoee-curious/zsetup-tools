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
  'assets',
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

export async function syncAssets({
  globPattern = 'assets/**/*.*',
  endpoint = '/putAssetIndex',
  build = true,
  upload = true,
  forced = false,
  indexPath = 'assets/assets-index.json',
  visability = 'public',
  apiUrl = API_URL,
  apiKey = API_KEY,
} = {}) {
  console.log(
    `\nStarting assets index process for pattern: "${globPattern}"...`,
  );

  const localFiles = (await glob(globPattern)).sort();
  const assetsIndexMap = {};

  for (const filePath of localFiles) {
    const filePathNormalized = filePath.replace(/\\/g, '/');

    if (indexPath && filePathNormalized === indexPath.replace(/\\/g, '/'))
      continue;

    if (build) {
      const fileName = path.basename(filePathNormalized);
      assetsIndexMap[fileName] = filePathNormalized;
    }
  }

  if (build && indexPath) {
    const indexContent = JSON.stringify(assetsIndexMap, null, 2);

    const dir = path.dirname(indexPath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }

    const currentIndexHash = calculateHash(indexContent);
    const indexFilePathNormalized = indexPath.replace(/\\/g, '/');

    fs.writeFileSync(indexPath, indexContent);
    console.log(`Index successfully written to: ${indexPath}`);

    if (upload) {
      const hashCache = loadHashCache();

      if (hashCache[indexFilePathNormalized] === currentIndexHash && !forced) {
        console.log(
          `[SKIP] Assets index file unchanged: ${indexFilePathNormalized}`,
        );
      } else {
        try {
          const res = await fetch(`${apiUrl}${endpoint}`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': apiKey,
              'x-visability': visability,
            },
            body: JSON.stringify({
              path: indexFilePathNormalized,
              content: indexContent,
            }),
          });

          if (res.ok) {
            hashCache[indexFilePathNormalized] = currentIndexHash;
            saveHashCache(hashCache);
            console.log(
              `[OK] Uploaded Assets Index File: ${indexFilePathNormalized}`,
            );
          } else {
            console.error(
              `[FAIL] Uploading Assets Index File (Status: ${res.status})`,
            );
          }
        } catch (err) {
          console.error(
            `[ERROR] Failed uploading assets index file:`,
            err.message,
          );
        }
      }
    }
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  syncAssets().catch((err) => {
    console.error('Assets sync failed:', err);
    process.exit(1);
  });
}
