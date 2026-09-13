import { config } from 'dotenv';
import { execSync } from 'child_process';

config();

const BUCKET = process.env.BUCKET_PUBLIC_NAME;
const R2_ACCOUNT_ID = process.env.R2_ACCOUNT_ID;
if (!R2_ACCOUNT_ID) {
  console.error(`R2_ACCOUNT_ID Are required!`);
  process.exit(1);
}

const ENDPOINT = `https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com`;

export async function syncR2Assets({ path = 'assets', bucket = BUCKET }) {
  console.log(`Starting Sync R2 ${path}...`);
  const command = `aws s3 sync ./${path} s3://${bucket}/${path} --endpoint-url ${ENDPOINT} --delete --exclude "assets-index.json"`;

  try {
    execSync(command, { stdio: 'inherit' });
    console.log(`Sync R2 ${path} successfuly!`);
  } catch (error) {
    console.error(`Failed sync R2 ${path}:`, error.message);
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  syncR2Assets({}).catch((err) => {
    console.error('Assets sync failed:', err);
    process.exit(1);
  });
}
