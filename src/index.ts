import { Hono } from 'hono';
import manifestRoutes from './routes/manifest.routes.js';
import scriptRoutes from './routes/script.routes.js';
import assetRoutes from './routes/asset.routes.js';

const app = new Hono();

app.route('/', assetRoutes);
app.route('/', manifestRoutes);
app.route('/', scriptRoutes);

export default app;
