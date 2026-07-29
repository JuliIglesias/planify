import { prisma } from '../../common/prisma';
import { BadRequestError, ForbiddenError, NotFoundError } from '../../common/errors';
import { logActivity, ActivityType } from '../activity-log/activity-log.service';
import { recalculateEventDebts } from '../debts/debts.service';
import { toCents, fromCents, splitEvenlyCents } from '../debts/debt-engine';

interface MontoPorParticipante {
  participanteId: string;
  monto: string | number;
}

interface CreateExpenseInput {
  descripcion: string;
  montoTotal: string | number;
  /** Quién puso la plata. Soporta múltiples acreedores (FR7). */
  acreedores: MontoPorParticipante[];
  /** A quiénes les corresponde pagar. Si se omite, se divide en partes iguales
   *  entre `dividirEntre` (o entre todos los participantes del evento). */
  deudores?: MontoPorParticipante[];
  dividirEntre?: string[];
}

/** HU-13/HU-14 — registrar un gasto con múltiples acreedores y deudores. */
export async function createExpense(
  eventoId: string,
  participanteId: string,
  input: CreateExpenseInput,
) {
  if (!input.descripcion?.trim()) throw new BadRequestError('descripcion es requerida');

  const evento = await prisma.evento.findUnique({
    where: { id: eventoId },
    include: { participantes: { select: { id: true } } },
  });
  if (!evento) throw new NotFoundError('Evento no encontrado');
  if (evento.estado === 'cancelado') throw new BadRequestError('El evento está cancelado');

  const totalCents = toCents(input.montoTotal);
  if (totalCents <= 0) throw new BadRequestError('montoTotal debe ser mayor a 0');

  const acreedores = input.acreedores ?? [];
  if (acreedores.length === 0) throw new BadRequestError('Se requiere al menos un acreedor');

  const sumaAcreedoresCents = acreedores.reduce((acc, a) => acc + toCents(a.monto), 0);
  if (sumaAcreedoresCents !== totalCents) {
    throw new BadRequestError(
      `Los aportes suman ${fromCents(sumaAcreedoresCents)} pero el gasto es ${fromCents(totalCents)}`,
    );
  }

  // Si no se detalla quién debe qué, se divide en partes iguales sin perder centavos.
  let deudores = input.deudores;
  if (!deudores || deudores.length === 0) {
    const ids = input.dividirEntre?.length
      ? input.dividirEntre
      : evento.participantes.map((p) => p.id);
    if (ids.length === 0) throw new BadRequestError('No hay participantes para dividir el gasto');

    const partes = splitEvenlyCents(totalCents, ids.length);
    deudores = ids.map((id, i) => ({ participanteId: id, monto: fromCents(partes[i]) }));
  }

  const sumaDeudoresCents = deudores.reduce((acc, d) => acc + toCents(d.monto), 0);
  if (sumaDeudoresCents !== totalCents) {
    throw new BadRequestError(
      `Las deudas suman ${fromCents(sumaDeudoresCents)} pero el gasto es ${fromCents(totalCents)}`,
    );
  }

  const gasto = await prisma.gasto.create({
    data: {
      eventoId,
      descripcion: input.descripcion.trim(),
      montoTotal: fromCents(totalCents),
      creadoPor: participanteId,
      acreedores: {
        create: acreedores.map((a) => ({
          participanteId: a.participanteId,
          montoAportado: fromCents(toCents(a.monto)),
        })),
      },
      deudores: {
        create: deudores.map((d) => ({
          participanteId: d.participanteId,
          montoAdeudado: fromCents(toCents(d.monto)),
        })),
      },
    },
    include: { acreedores: true, deudores: true },
  });

  await logActivity(prisma, {
    eventoId,
    tipo: ActivityType.gastoAgregado,
    actorParticipanteId: participanteId,
    payload: { gastoId: gasto.id, descripcion: gasto.descripcion, monto: gasto.montoTotal.toString() },
  });

  await recalculateEventDebts(eventoId);

  return gasto;
}

export async function listExpenses(eventoId: string) {
  return prisma.gasto.findMany({
    where: { eventoId },
    orderBy: { fecha: 'desc' },
    include: {
      acreedores: { include: { participante: { select: { id: true, nombreDisplay: true } } } },
      deudores: { include: { participante: { select: { id: true, nombreDisplay: true } } } },
      creador: { select: { id: true, nombreDisplay: true } },
    },
  });
}

/** HU-19 — cerrar gastos: permiso exclusivo del organizador (Duda #6). */
export async function closeExpenses(eventoId: string, usuarioId: string) {
  const organizador = await prisma.participante.findFirst({
    where: { eventoId, usuarioId, esOrganizador: true },
  });
  if (!organizador) throw new ForbiddenError('Solo el organizador puede cerrar los gastos');

  return recalculateEventDebts(eventoId);
}
