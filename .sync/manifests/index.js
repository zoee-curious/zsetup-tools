import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import { glob } from 'glob';
import { load } from 'js-yaml';

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
  globPattern,
  endpoint,
  build,
  upload,
  forced,
  indexPath,
  searchIndexPath,
  scope,
  apiUrl,
  apiKey,
} = {}) {
  console.log(`\nStarting manifest process for pattern: "${globPattern}"...`);

  const localFiles = (await glob(globPattern)).sort();
  const serverIndexMap = {};
  const searchManifestList = [];
  const hashCache = loadHashCache();
  let updatedCount = 0;

  async function uploadFile(filePathNormalized, content) {
    if (!upload) return;

    const currentHash = calculateHash(content);

    if (hashCache[filePathNormalized] === currentHash && !forced) {
      console.log(`[SKIP] Unchanged: ${filePathNormalized}`);
      return;
    }

    try {
      const response = await fetch(`${apiUrl}${endpoint}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'x-scope': scope,
        },
        body: JSON.stringify({
          path: filePathNormalized,
          content: content,
        }),
      });

      if (response.ok) {
        hashCache[filePathNormalized] = currentHash;
        updatedCount++;
        console.log(`[OK] Uploaded: ${filePathNormalized}`);
      } else {
        console.error(
          `[FAIL] Uploading ${filePathNormalized} (Status: ${response.status})`,
        );
      }
    } catch (error) {
      console.error(
        `[ERROR] Failed uploading ${filePathNormalized}:`,
        error.message,
      );
    }
  }

  for (const filePath of localFiles) {
    const filePathNormalized = filePath.replace(/\\/g, '/');

    if (
      (indexPath && filePathNormalized === indexPath.replace(/\\/g, '/')) ||
      (searchIndexPath &&
        filePathNormalized === searchIndexPath.replace(/\\/g, '/'))
    ) {
      continue;
    }

    const content = fs.readFileSync(filePath, 'utf8');

    if (build) {
      try {
        const parsed = load(content) || {};
        if (parsed.Id) {
          const id = parsed.Id.toString();
          const name = parsed.Name || '';
          const version = parsed.Version ? parsed.Version.toString() : '';
          const description = parsed.Description || '';
          const aliases = Array.isArray(parsed.Aliases)
            ? parsed.Aliases.map((a) => a.toString())
            : [];

          serverIndexMap[id.toLowerCase()] = filePathNormalized;
          if (name) serverIndexMap[name.toLowerCase()] = filePathNormalized;
          aliases.forEach((alias) => {
            if (alias) serverIndexMap[alias.toLowerCase()] = filePathNormalized;
          });

          searchManifestList.push({
            id,
            name,
            version,
            description,
            aliases,
          });
        }
      } catch (error) {
        console.error(
          `[ERROR] Parsing YAML on ${filePathNormalized}:`,
          error.message,
        );
      }
    }

    await uploadFile(filePathNormalized, content);
  }

  async function processIndexFile(targetPath, contentData) {
    if (!build || !targetPath) return;

    const indexContent = JSON.stringify(contentData, null, 2);
    const dir = path.dirname(targetPath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }

    const targetPathNormalized = targetPath.replace(/\\/g, '/');
    fs.writeFileSync(targetPath, indexContent);
    console.log(`Index successfully written to: ${targetPath}`);

    await uploadFile(targetPathNormalized, indexContent);
  }

  searchManifestList.sort((a, b) =>
    a.id.localeCompare(b.id, undefined, { numeric: true }),
  );

  await processIndexFile(indexPath, serverIndexMap);
  await processIndexFile(searchIndexPath, searchManifestList);

  if (upload && updatedCount > 0) {
    saveHashCache(hashCache);
  }
}
