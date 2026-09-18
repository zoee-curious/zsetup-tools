import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';

export async function syncR2Assets({ targetPath, bucket, r2AcountId } = {}) {
  const localPath = path.resolve(`./${targetPath}`);

  if (!fs.existsSync(localPath)) {
    console.warn(`Directory ./${targetPath} does not exist. Skipping sync.`);
    return;
  }

  console.log(`Starting Sync R2 ${targetPath}...`);

  const endpoint = `https://${r2AcountId}.r2.cloudflarestorage.com`;
  const command = `aws s3 sync ./${targetPath} s3://${bucket}/${targetPath} --endpoint-url ${endpoint} --delete --exclude "assets-index.json"`;

  try {
    execSync(command, { stdio: 'inherit' });
    console.log(`Sync R2 ${targetPath} successfully!`);
  } catch (error) {
    console.error(`Failed sync R2 ${targetPath}:`, error.message);
  }
}
