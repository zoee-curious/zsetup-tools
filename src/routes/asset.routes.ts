import { Hono } from 'hono';
import {
  getAsset,
  getIndexAsset,
  putAssetIndex,
} from '../controllers/asset.controller.js';
import { authRequest } from '../middlewares/auth.middleware.js';

const assetRoutes = new Hono();

assetRoutes.use('*', authRequest);

assetRoutes.post('/putAssetIndex', putAssetIndex);

assetRoutes.get('/getIndexAsset', getIndexAsset);
assetRoutes.get('/download/*', getAsset);

export default assetRoutes;
