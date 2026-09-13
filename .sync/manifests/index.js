import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import { glob } from 'glob';
import { load } from 'js-yaml';
import { config } from 'dotenv';

config();

const API_KEY = process.env.API_KEY;
const API_URL = process.env.API_URL || 'http://127.0.0.1:8787';

const HASH_CACHE_FILE = path.join(
  process.cwd(),
  '.sync',
  'manifests',
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

export async function syncManifests({
  globPattern = 'manifests/**/*.yaml',
  endpoint = '/putManifest',
  build = true,
  upload = true,
  forced = false,
  indexPath = 'manifests/manifests-index.json',
  visability = 'public',
  apiUrl = API_URL,
  apiKey = API_KEY,
} = {}) {
  console.log(`\nStarting manifest process for pattern: "${globPattern}"...`);

  const localFiles = (await glob(globPattern)).sort();
  const manifestList = [];
  const hashCache = loadHashCache();
  let updatedCount = 0;

  for (const filePath of localFiles) {
    const filePathNormalized = filePath.replace(/\\/g, '/');

    if (indexPath && filePathNormalized === indexPath.replace(/\\/g, '/'))
      continue;

    const content = fs.readFileSync(filePath, 'utf8');
    const currentHash = calculateHash(content);

    if (build) {
      try {
        const parsed = load(content) || {};
        if (parsed.Id) {
          manifestList.push({
            id: parsed.Id.toString(),
            name: parsed.Name || '',
            version: parsed.Version ? parsed.Version.toString() : '',
            publisher: parsed.Publisher || '',
            description: parsed.Description || '',
            aliases: Array.isArray(parsed.Aliases)
              ? parsed.Aliases.map((a) => a.toString())
              : [],
            url: parsed.Url || '',
            path: filePathNormalized,
          });
        }
      } catch (err) {
        console.error(
          `[ERROR] Parsing YAML on ${filePathNormalized}:`,
          err.message,
        );
      }
    }

    if (upload) {
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
            'x-visability': visability,
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
  }

  if (build && indexPath) {
    manifestList.sort((a, b) =>
      a.id.localeCompare(b.id, undefined, { numeric: true }),
    );
    const indexContent = JSON.stringify(manifestList, null, 2);

    const dir = path.dirname(indexPath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }

    const currentIndexHash = calculateHash(indexContent);
    const indexFilePathNormalized = indexPath.replace(/\\/g, '/');

    fs.writeFileSync(indexPath, indexContent);
    console.log(`Index successfully written to: ${indexPath}`);

    if (upload) {
      if (hashCache[indexFilePathNormalized] === currentIndexHash && !forced) {
        console.log(`[SKIP] Index file unchanged: ${indexFilePathNormalized}`);
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
            updatedCount++;
            console.log(`[OK] Uploaded Index File: ${indexFilePathNormalized}`);
          } else {
            console.error(
              `[FAIL] Uploading Index File (Status: ${res.status})`,
            );
          }
        } catch (err) {
          console.error(`[ERROR] Failed uploading index file:`, err.message);
        }
      }
    }
  }

  if (upload && updatedCount > 0) {
    saveHashCache(hashCache);
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  syncManifests().catch((err) => {
    console.error('Manifests sync failed:', err);
    process.exit(1);
  });
}
