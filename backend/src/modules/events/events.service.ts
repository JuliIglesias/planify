import { prisma } from '../../common/prisma';
import { BadRequestError, ForbiddenError, NotFoundError } from '../../common/errors';

interface CreateEventInput {
  nombre: string;
  lugarTexto: string;
  grupoId?: string;
  nuevoGrupoNombre?: string;
  miembroUsuarioIds?: string[];
}

// HU-06 — creación de evento en 2 pasos (paso 1: nombre+lugar; paso 2: grupo existente
// o miembros nuevos, que dispara HU-04). El organizador queda como Participante con
// es_organizador=true (ver nota de diseño de docs/01-plan-de-ejecucion.md §3).
export async function createEvent(usuarioId: string, input: CreateEventInput) {
  if (!input.nombre?.trim()) throw new BadRequestError('nombre es requerido');
  if (!input.lugarTexto?.trim()) throw new BadRequestError('lugarTexto es requerido');
  if (!input.grupoId && !input.nuevoGrupoNombre) {
    throw new BadRequestError('Se requiere grupoId (grupo existente) o nuevoGrupoNombre (HU-04/HU-05)');
  }

  const organizadorUsuario = await prisma.usuario.findUniqueOrThrow({ where: { id: usuarioId } });

  return prisma.$transaction(async (tx) => {
    let grupoId = input.grupoId;

    if (!grupoId) {
      const miembroIds = Array.from(new Set([usuarioId, ...(input.miembroUsuarioIds ?? [])]));
      const grupo = await tx.grupo.create({
        data: {
          nombre: input.nuevoGrupoNombre!.trim(),
          miembros: { create: miembroIds.map((id) => ({ usuarioId: id })) },
        },
      });
      grupoId = grupo.id;
    }

    const evento = await tx.evento.create({
      data: {
        grupoId,
        nombre: input.nombre.trim(),
        lugarTexto: input.lugarTexto.trim(),
        creadoPor: 'pending', // se resuelve abajo (evento y participante organizador se crean juntos)
      },
    });

    const organizador = await tx.participante.create({
      data: {
        eventoId: evento.id,
        usuarioId,
        nombreDisplay: organizadorUsuario.nombre,
        esOrganizador: true,
        estadoAsistencia: 'confirmado',
      },
    });

    const eventoFinal = await tx.evento.update({
      where: { id: evento.id },
      data: { creadoPor: organizador.id },
    });

    return { evento: eventoFinal, organizador };
  });
}

// HU-11 — cancelación de evento, solo por el organizador.
export async function cancelEvent(usuarioId: string, eventoId: string) {
  const evento = await prisma.evento.findUnique({ where: { id: eventoId } });
  if (!evento) throw new NotFoundError('Evento no encontrado');

  const organizador = await prisma.participante.findFirst({
    where: { eventoId, usuarioId, esOrganizador: true },
  });
  if (!organizador) throw new ForbiddenError('Solo el organizador puede cancelar el evento');

  return prisma.$transaction([
    prisma.evento.update({ where: { id: eventoId }, data: { estado: 'cancelado' } }),
    // Invalida el acceso de los participantes anónimos (Duda #5): se limpia su token de sesión.
    prisma.participante.updateMany({
      where: { eventoId, esAnonimo: true },
      data: { tokenSesion: null },
    }),
  ]);
}

// HU-10 — confirmación/rechazo de asistencia por parte de cualquier participante.
export async function setAttendance(participanteId: string, estado: 'confirmado' | 'rechazado') {
  return prisma.participante.update({
    where: { id: participanteId },
    data: { estadoAsistencia: estado },
  });
}
