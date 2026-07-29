import express from 'express';
import cors from 'cors';
import helmet from 'helmet';

import { Container } from './container';
import { createRoutes } from './routes';
import { errorHandler, notFoundHandler } from './middlewares/errorHandler';

/**
 * Arma la app de Express a partir de un container ya cableado.
 *
 * Recibe el container en vez de crearlo: así los tests pueden inyectar
 * servicios falsos y probar la API entera sin base de datos.
 */
export function createApp(container: Container) {
  const app = express();

  app.use(helmet());
  app.use(cors());
  app.use(express.json());

  app.use(createRoutes(container));

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
