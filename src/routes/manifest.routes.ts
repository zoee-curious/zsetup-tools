import { Hono } from 'hono';
import {
  getIndexManifest,
  getManifest,
  putManifest,
} from '../controllers/manifest.controller.js';
import { authRequest } from '../middlewares/auth.middleware.js';

const manifestRoutes = new Hono();

manifestRoutes.use('*', authRequest);

manifestRoutes.post('/putManifest', putManifest);
manifestRoutes.get('/getIndexManifest', getIndexManifest);
manifestRoutes.get('/getManifest/:name', getManifest);

export default manifestRoutes;
