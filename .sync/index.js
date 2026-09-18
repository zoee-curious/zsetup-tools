import { config } from 'dotenv';
import { syncR2Assets } from './assets/aws/index.js';
import { syncAssets } from './assets/index.js';
import { syncManifests } from './manifests/index.js';
import { syncScripts } from './scripts/index.js';

config();

const API_KEY = process.env.API_KEY;
const API_URL = process.env.API_URL;

const BUCKET = process.env.BUCKET_PUBLIC_NAME;
const R2_ACCOUNT_ID = process.env.R2_ACCOUNT_ID;

await syncScripts({
  globPattern: 'scripts/zst.ps1',
  endpoint: '/putScript',
  forced: process.env.FORCE_SYNC === 'true',
  apiUrl: API_URL,
  apiKey: API_KEY,
});

await syncManifests({
  globPattern: 'manifests/**/*.yaml',
  endpoint: '/putManifest',
  build: true,
  upload: true,
  forced: process.env.FORCE_SYNC === 'true',
  indexPath: 'manifests/manifests-index.json',
  searchIndexPath: 'manifests/manifests-search-index.json',
  scope: 'public',
  apiUrl: API_URL,
  apiKey: API_KEY,
});

await syncR2Assets({
  targetPath: 'assets',
  bucket: BUCKET,
  r2AcountId: R2_ACCOUNT_ID,
});

await syncAssets({
  globPattern: 'assets/**/*.*',
  endpoint: '/putAssetIndex',
  build: true,
  upload: true,
  forced: process.env.FORCE_SYNC === 'true',
  indexPath: 'assets/assets-index.json',
  scope: 'public',
  apiUrl: API_URL,
  apiKey: API_KEY,
});
