import { prisma } from '../../common/prisma';
import { NotFoundError, BadRequestError } from '../../common/errors';
import { logActivity, ActivityType } from '../activity-log/activity-log.service';
import { simplifyDebts, toCents, fromCents, ParticipantAmountCents } from './debt-engine';

/**
 * HU-15 — recalcula las deudas simplificadas de un evento desde cero.
 * Se llama después de cada alta/baja de gasto y de cada pago.
 *
 * Preserva el estado `saldado` de las deudas que ya se pagaron y siguen
 * existiendo igual, para no "revivir" un pago cuando alguien agrega otro gasto.
 */
export async function recalculateEventDebts(eventoId: string) {
  const gastos = await prisma.gasto.findMany({
    where: { eventoId },
    include: { acreedores: true, deudores: true },
  });

  const entries: ParticipantAmountCents[] = [];
  for (const gasto of gastos) {
    for (const acreedor of gasto.acreedores) {
      entries.push({
        participanteId: acreedor.participanteId,
        aportadoCents: toCents(acreedor.montoAportado.toString()),
        adeudadoCents: 0,
      });
    }
    for (const deudor of gasto.deudores) {
      entries.push({
        participanteId: deudor.participanteId,
        aportadoCents: 0,
        adeudadoCents: toCents(deudor.montoAdeudado.toString()),
      });
    }
  }

  const simplified = entries.length > 0 ? simplifyDebts(entries) : [];

  const previas = await prisma.deudaSimplificada.findMany({ where: { eventoId } });
  const saldadasPrevias = new Map(
    previas
      .filter((d) => d.estado === 'saldado')
      .map((d) => [`${d.deudorParticipanteId}->${d.acreedorParticipanteId}`, d]),
  );

  return prisma.$transaction(async (tx) => {
    await tx.deudaSimplificada.deleteMany({ where: { eventoId } });

    for (const debt of simplified) {
      const key = `${debt.deudorParticipanteId}->${debt.acreedorParticipanteId}`;
      const previa = saldadasPrevias.get(key);
      const monto = fromCents(debt.montoCents);
      const sigueIgual = previa && previa.monto.toString() === monto;

      await tx.deudaSimplificada.create({
        data: {
          eventoId,
          deudorParticipanteId: debt.deudorParticipanteId,
          acreedorParticipanteId: debt.acreedorParticipanteId,
          monto,
          estado: sigueIgual ? 'saldado' : 'pendiente',
          saldadoEn: sigueIgual ? previa.saldadoEn : null,
        },
      });
    }

    return tx.deudaSimplificada.findMany({ where: { eventoId } });
  });
}

/** Deudas de un evento, con el nombre de cada parte para pintarlas en la UI. */
export async function getEventDebts(eventoId: string) {
  return prisma.deudaSimplificada.findMany({
    where: { eventoId },
    include: {
      deudor: { select: { id: true, nombreDisplay: true } },
      acreedor: { select: { id: true, nombreDisplay: true } },
    },
  });
}

/**
 * HU-16/HU-17 — balance del usuario y saldos por persona.
 * Los 3 estados de la UI (Duda #2): `pagar` si yo debo, `pendiente` si me deben
 * y todavía no me pagaron, `saldado` si no queda nada.
 */
export async function getUserBalance(usuarioId: string) {
  const participaciones = await prisma.participante.findMany({
    where: { usuarioId },
    select: { id: true },
  });
  const misIds = participaciones.map((p) => p.id);

  const deudas = await prisma.deudaSimplificada.findMany({
    where: {
      OR: [
        { deudorParticipanteId: { in: misIds } },
        { acreedorParticipanteId: { in: misIds } },
      ],
    },
    include: {
      deudor: { select: { id: true, nombreDisplay: true, usuarioId: true } },
      acreedor: { select: { id: true, nombreDisplay: true, usuarioId: true } },
      evento: { select: { id: true, nombre: true } },
    },
  });

  let meDebenCents = 0;
  let deboCents = 0;
  const porPersona = new Map<
    string,
    { nombre: string; netoCents: number; estado: 'pagar' | 'pendiente' | 'saldado' }
  >();

  for (const deuda of deudas) {
    if (deuda.estado === 'saldado') continue;

    const montoCents = toCents(deuda.monto.toString());
    const soyDeudor = misIds.includes(deuda.deudorParticipanteId);
    const otro = soyDeudor ? deuda.acreedor : deuda.deudor;
    // Agrupamos por usuario registrado; los anónimos quedan por participante,
    // porque su identidad no persiste más allá del evento (Duda #5).
    const clave = otro.usuarioId ?? otro.id;

    if (soyDeudor) deboCents += montoCents;
    else meDebenCents += montoCents;

    const actual = porPersona.get(clave) ?? {
      nombre: otro.nombreDisplay,
      netoCents: 0,
      estado: 'saldado' as const,
    };
    actual.netoCents += soyDeudor ? -montoCents : montoCents;
    porPersona.set(clave, actual);
  }

  const saldos = [...porPersona.entries()].map(([id, valor]) => ({
    id,
    nombre: valor.nombre,
    monto: fromCents(Math.abs(valor.netoCents)),
    estado: valor.netoCents === 0 ? 'saldado' : valor.netoCents < 0 ? 'pagar' : 'pendiente',
  }));

  return {
    balanceNeto: fromCents(meDebenCents - deboCents),
    meDeben: fromCents(meDebenCents),
    debo: fromCents(deboCents),
    saldos,
  };
}

/** HU-18 — marcar una deuda como saldada. */
export async function settleDebt(deudaId: string, participanteId: string) {
  const deuda = await prisma.deudaSimplificada.findUnique({ where: { id: deudaId } });
  if (!deuda) throw new NotFoundError('Deuda no encontrada');
  if (deuda.estado === 'saldado') throw new BadRequestError('La deuda ya está saldada');

  const actualizada = await prisma.deudaSimplificada.update({
    where: { id: deudaId },
    data: { estado: 'saldado', saldadoEn: new Date() },
  });

  await logActivity(prisma, {
    eventoId: deuda.eventoId,
    tipo: ActivityType.deudaSaldada,
    actorParticipanteId: participanteId,
    payload: { deudaId, monto: deuda.monto.toString() },
  });

  await maybeFinalizeEvent(deuda.eventoId);

  return actualizada;
}

/**
 * Un evento se considera finalizado cuando no le queda ninguna deuda pendiente
 * (definición del usuario en Duda #5). Es lo que dispara el estado "SALDADO"
 * del historial.
 */
export async function maybeFinalizeEvent(eventoId: string) {
  const pendientes = await prisma.deudaSimplificada.count({
    where: { eventoId, estado: { not: 'saldado' } },
  });

  const evento = await prisma.evento.findUnique({ where: { id: eventoId } });
  if (!evento || evento.estado === 'cancelado') return;

  const totalDeudas = await prisma.deudaSimplificada.count({ where: { eventoId } });

  if (pendientes === 0 && totalDeudas > 0 && evento.estado !== 'finalizado') {
    await prisma.evento.update({ where: { id: eventoId }, data: { estado: 'finalizado' } });
  } else if (pendientes > 0 && evento.estado === 'finalizado') {
    await prisma.evento.update({ where: { id: eventoId }, data: { estado: 'confirmado' } });
  }
}
