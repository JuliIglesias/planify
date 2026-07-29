import { prisma } from '../../common/prisma';
import { BadRequestError } from '../../common/errors';

// HU-04 — auto-creación de grupo al crear un evento con miembros nuevos.
export async function createGroup(nombre: string, usuarioIds: string[]) {
  if (!nombre?.trim()) throw new BadRequestError('nombre de grupo es requerido');

  return prisma.grupo.create({
    data: {
      nombre: nombre.trim(),
      miembros: {
        create: usuarioIds.map((usuarioId) => ({ usuarioId })),
      },
    },
    include: { miembros: true },
  });
}

// HU-05 — grupos existentes del organizador, para reutilizar al crear un evento nuevo.
export async function listGroupsForUser(usuarioId: string) {
  return prisma.grupo.findMany({
    where: { miembros: { some: { usuarioId } } },
    include: { miembros: true },
  });
}
