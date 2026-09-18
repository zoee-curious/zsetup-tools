import { Hono } from 'hono';
import {
  getInstallScript,
  getRemoteScript,
  getScript,
  putScript,
} from '../controllers/script.controller.js';
import { authRequest } from '../middlewares/auth.middleware.js';

const scriptRoutes = new Hono();

scriptRoutes.use('*', authRequest);

scriptRoutes.post('/putScript', putScript);

scriptRoutes.get('/install', getInstallScript);
scriptRoutes.get('/getScript', getScript);
scriptRoutes.get('/:action/:name', getRemoteScript);

export default scriptRoutes;
