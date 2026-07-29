import 'dotenv/config';
import { PrismaClient } from '@prisma/client';
import { createApp } from './app';
import { createContainer } from './container';

const port = process.env.PORT ? Number(process.env.PORT) : 3000;

const prisma = new PrismaClient();
const app = createApp(createContainer(prisma));

const server = app.listen(port, () => {
  console.log(`Planify backend escuchando en http://localhost:${port}`);
});

// El ambiente se apaga a mano entre demos (Duda #8): cerrar prolijo evita
// dejar conexiones colgadas contra RDS.
for (const señal of ['SIGINT', 'SIGTERM'] as const) {
  process.on(señal, () => {
    server.close(() => {
      void prisma.$disconnect().then(() => process.exit(0));
    });
  });
}
