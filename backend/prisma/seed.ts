// T-07 — usuario organizador "fake" para crear eventos en el MVP sin auth real.
// Ver docs/02-decisiones.md (Duda #19).
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

const SEED_ORGANIZER = {
  nombre: 'Organizador Planify',
  email: 'organizador@planify.test',
  password: 'planify-mvp-2026', // solo para el MVP, se reemplaza por Cognito en SCRUM-14
};

async function main() {
  const passwordHash = await bcrypt.hash(SEED_ORGANIZER.password, 10);

  const usuario = await prisma.usuario.upsert({
    where: { email: SEED_ORGANIZER.email },
    update: {},
    create: {
      nombre: SEED_ORGANIZER.nombre,
      email: SEED_ORGANIZER.email,
      passwordHash,
    },
  });

  console.log(`Usuario organizador semilla listo: ${usuario.email} (id ${usuario.id})`);
  console.log(`Password de prueba (solo MVP, no usar en producción real): ${SEED_ORGANIZER.password}`);
}

main()
  .then(async () => {
    await prisma.$disconnect();
    // Salida explícita: garantiza que el contenedor de seed (one-shot en
    // docker-compose) termine y no quede colgado (H-07).
    process.exit(0);
  })
  .catch(async (err) => {
    console.error(err);
    await prisma.$disconnect();
    process.exit(1);
  });
