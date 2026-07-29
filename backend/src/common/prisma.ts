import { PrismaClient } from '@prisma/client';

// Singleton — evita abrir una conexión nueva por request (ver docs/01-plan-de-ejecucion.md §2).
export const prisma = new PrismaClient();
