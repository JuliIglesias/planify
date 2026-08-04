import { BadRequestError, NotFoundError } from '../../common/errors';
import { DeudaSimplificada } from '../../domain/entities';
import {
  Clock,
  DeudaConPersonas,
  DeudaRepository,
  EventoRepository,
  GastoRepository,
  NuevaDeuda,
  ParticipanteRepository,
} from '../../domain/repositories';
import { ActivityLogService } from '../activity-log/activity-log.service';
import { ActivityType } from '../activity-log/activity-log.types';
import { fromCents, ParticipantAmountCents, simplifyDebts, toCents } from './debt-engine';

export interface SaldoPorPersona {
  id: string;
  username: string;
  monto: string;
  estado: 'pagar' | 'pendiente' | 'saldado';
}

export interface BalanceUsuario {
  balanceNeto: string;
  meDeben: string;
  debo: string;
  saldos: SaldoPorPersona[];
}

/** Una deuda concreta de un evento, dentro del detalle con una persona. */
export interface DeudaDeEvento {
  id: string;
  eventoId: string;
  eventoNombre: string;
  monto: string;
  /** `true` si en ESE evento la deuda es mía hacia la otra persona. */
  yoDebo: boolean;
}

/**
 * Desglose de la relación con una persona: qué se debe en cada evento y cuánto
 * queda después de compensar (FR9).
 */
export interface DetalleConPersona {
  personaId: string;
  username: string;
  /** Neto ya compensado, siempre en positivo. El signo lo da `estado`. */
  monto: string;
  estado: 'pagar' | 'pendiente' | 'saldado';
  /** Lo que yo le debo, sin compensar. */
  totalQueDebo: string;
  /** Lo que ella me debe, sin compensar. */
  totalQueMeDebe: string;
  deudas: DeudaDeEvento[];
}

/**
 * SCRUM-11 — HU-15 a HU-18. La aritmética vive en `debt-engine.ts` (pura y
 * testeable); esta clase se ocupa de leer, persistir y aplicar las reglas de
 * negocio alrededor (qué queda saldado, cuándo se finaliza un evento).
 */
export class DebtsService {
  constructor(
    private readonly deudas: DeudaRepository,
    private readonly gastos: GastoRepository,
    private readonly participantes: ParticipanteRepository,
    private readonly eventos: EventoRepository,
    private readonly log: ActivityLogService,
    private readonly clock: Clock,
  ) {}

  /**
   * HU-15 — recalcula desde cero las deudas del evento. Se llama después de
   * cada alta de gasto y de cada pago.
   */
  async recalcular(eventoId: string): Promise<DeudaSimplificada[]> {
    const gastos = await this.gastos.listMontosByEvento(eventoId);

    const movimientos: ParticipantAmountCents[] = [];
    for (const gasto of gastos) {
      for (const acreedor of gasto.acreedores) {
        movimientos.push({
          participanteId: acreedor.participanteId,
          aportadoCents: toCents(acreedor.monto),
          adeudadoCents: 0,
        });
      }
      for (const deudor of gasto.deudores) {
        movimientos.push({
          participanteId: deudor.participanteId,
          aportadoCents: 0,
          adeudadoCents: toCents(deudor.monto),
        });
      }
    }

    const simplificadas = movimientos.length > 0 ? simplifyDebts(movimientos) : [];

    // Una deuda que ya se pagó y quedó idéntica sigue saldada: agregar otro
    // gasto al evento no debe "revivir" un pago que ya ocurrió.
    const previas = await this.deudas.listByEvento(eventoId);
    const saldadasPrevias = new Map(
      previas
        .filter((d) => d.estado === 'saldado')
        .map((d) => [this.clave(d.deudorParticipanteId, d.acreedorParticipanteId), d]),
    );

    const nuevas: NuevaDeuda[] = simplificadas.map((deuda) => {
      const monto = fromCents(deuda.montoCents);
      const previa = saldadasPrevias.get(
        this.clave(deuda.deudorParticipanteId, deuda.acreedorParticipanteId),
      );
      const sigueIgual = previa?.monto === monto;

      return {
        deudorParticipanteId: deuda.deudorParticipanteId,
        acreedorParticipanteId: deuda.acreedorParticipanteId,
        monto,
        estado: sigueIgual ? 'saldado' : 'pendiente',
        saldadoEn: sigueIgual ? (previa?.saldadoEn ?? null) : null,
      };
    });

    const resultado = await this.deudas.reemplazarEvento(eventoId, nuevas);
    await this.actualizarEstadoEvento(eventoId);
    return resultado;
  }

  async listarDelEvento(eventoId: string): Promise<DeudaConPersonas[]> {
    return this.deudas.listByEvento(eventoId);
  }

  /**
   * HU-16/HU-17 — balance del usuario y saldos por persona.
   * Los 3 estados de la UI (Duda #2): `pagar` si yo debo, `pendiente` si me
   * deben y no me pagaron, `saldado` si no queda nada.
   */
  async balanceDe(usuarioId: string): Promise<BalanceUsuario> {
    const participaciones = await this.participantes.listByUsuario(usuarioId);
    const misIds = new Set(participaciones.map((p) => p.id));

    const deudas = await this.deudas.listByParticipantes([...misIds]);

    let meDebenCents = 0;
    let deboCents = 0;
    const porPersona = new Map<string, { username: string; netoCents: number }>();

    for (const deuda of deudas) {
      if (deuda.estado === 'saldado') continue;

      const montoCents = toCents(deuda.monto);
      const soyDeudor = misIds.has(deuda.deudorParticipanteId);
      const otro = soyDeudor ? deuda.acreedor : deuda.deudor;

      // Se agrupa por usuario registrado; los anónimos quedan sueltos por
      // participante, porque su identidad no sobrevive al evento (Duda #5).
      const clave = otro.usuarioId ?? otro.id;

      if (soyDeudor) deboCents += montoCents;
      else meDebenCents += montoCents;

      const actual = porPersona.get(clave) ?? { username: otro.username, netoCents: 0 };
      actual.netoCents += soyDeudor ? -montoCents : montoCents;
      porPersona.set(clave, actual);
    }

    const saldos: SaldoPorPersona[] = [...porPersona.entries()].map(([id, valor]) => ({
      id,
      username: valor.username,
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

  /**
   * FR9 — desglose de la relación con una persona: qué se debe en cada evento
   * y cuánto queda después de compensar.
   *
   * Ojo con la diferencia de alcance (decisión del usuario, [Duda #26]):
   * - Dentro de un evento se ven SOLO las deudas de ese evento (`listarDelEvento`).
   * - En la pantalla Balances se ve el neto compensado entre todos los eventos.
   */
  async detalleConPersona(usuarioId: string, personaId: string): Promise<DetalleConPersona> {
    const { misIds, deudas } = await this.deudasPendientesCon(usuarioId, personaId);

    let deboCents = 0;
    let meDebenCents = 0;
    const detalle: DeudaDeEvento[] = [];
    let username = '';

    for (const deuda of deudas) {
      const montoCents = toCents(deuda.monto);
      const yoDebo = misIds.has(deuda.deudorParticipanteId);

      if (yoDebo) deboCents += montoCents;
      else meDebenCents += montoCents;

      username = yoDebo ? deuda.acreedor.username : deuda.deudor.username;

      detalle.push({
        id: deuda.id,
        eventoId: deuda.eventoId,
        eventoNombre: deuda.eventoNombre,
        monto: deuda.monto,
        yoDebo,
      });
    }

    const netoCents = meDebenCents - deboCents;

    return {
      personaId,
      username,
      monto: fromCents(Math.abs(netoCents)),
      estado: netoCents === 0 ? 'saldado' : netoCents < 0 ? 'pagar' : 'pendiente',
      totalQueDebo: fromCents(deboCents),
      totalQueMeDebe: fromCents(meDebenCents),
      deudas: detalle,
    };
  }

  /**
   * FR9 — saldar la relación completa con una persona desde la pantalla
   * Balances: cierra **todas** las deudas pendientes con ella, en ambos
   * sentidos y de todos los eventos, y actualiza el estado de cada evento
   * afectado (decisión del usuario, [Duda #26]).
   */
  async saldarConPersona(
    usuarioId: string,
    personaId: string,
  ): Promise<{ saldadas: number; eventosAfectados: string[] }> {
    const { misIds, deudas } = await this.deudasPendientesCon(usuarioId, personaId);

    if (deudas.length === 0) {
      throw new BadRequestError('No hay deudas pendientes con esa persona');
    }

    const ahora = this.clock.now();
    const saldadas = await this.deudas.marcarSaldadasEnLote(
      deudas.map((d) => d.id),
      ahora,
    );

    // Una entrada de log por evento afectado, con el participante que soy yo
    // en ese evento como actor.
    const eventosAfectados = [...new Set(deudas.map((d) => d.eventoId))];

    for (const eventoId of eventosAfectados) {
      const deudasDelEvento = deudas.filter((d) => d.eventoId === eventoId);
      const actor = misIds.has(deudasDelEvento[0].deudorParticipanteId)
        ? deudasDelEvento[0].deudorParticipanteId
        : deudasDelEvento[0].acreedorParticipanteId;

      await this.log.registrar({
        eventoId,
        tipo: ActivityType.deudaSaldada,
        actorParticipanteId: actor,
        payload: {
          compensacionCruzada: true,
          deudas: deudasDelEvento.length,
        },
      });

      await this.actualizarEstadoEvento(eventoId);
    }

    return { saldadas, eventosAfectados };
  }

  /**
   * Deudas pendientes entre el usuario y otra persona, a través de todos los
   * eventos. `personaId` es el `usuarioId` de un registrado o el
   * `participanteId` de un anónimo (los anónimos no tienen identidad global,
   * ver [Duda #5]).
   */
  private async deudasPendientesCon(
    usuarioId: string,
    personaId: string,
  ): Promise<{ misIds: Set<string>; deudas: DeudaConPersonas[] }> {
    const participaciones = await this.participantes.listByUsuario(usuarioId);
    const misIds = new Set(participaciones.map((p) => p.id));

    const todas = await this.deudas.listByParticipantes([...misIds]);

    const deudas = todas.filter((deuda) => {
      if (deuda.estado === 'saldado') return false;

      const soyDeudor = misIds.has(deuda.deudorParticipanteId);
      const otro = soyDeudor ? deuda.acreedor : deuda.deudor;
      return (otro.usuarioId ?? otro.id) === personaId;
    });

    return { misIds, deudas };
  }

  /** HU-18 — marcar una deuda puntual como saldada (desde el evento). */
  async saldar(deudaId: string, participanteId: string): Promise<DeudaSimplificada> {
    const deuda = await this.deudas.findById(deudaId);
    if (!deuda) throw new NotFoundError('Deuda no encontrada');
    if (deuda.estado === 'saldado') throw new BadRequestError('La deuda ya está saldada');

    const saldada = await this.deudas.marcarSaldada(deudaId, this.clock.now());

    // Item 2 (Fase 4) — el nombre de la contraparte viaja en el payload para
    // que el log del evento pueda agrupar varios saldos seguidos del mismo
    // actor en una sola línea ("saldó cuentas con X, Y y Z") en vez de una
    // entrada por cada deuda saldada.
    const otroId =
      deuda.deudorParticipanteId === participanteId
        ? deuda.acreedorParticipanteId
        : deuda.deudorParticipanteId;
    const otro = await this.participantes.findById(otroId);

    await this.log.registrar({
      eventoId: deuda.eventoId,
      tipo: ActivityType.deudaSaldada,
      actorParticipanteId: participanteId,
      payload: { deudaId, monto: deuda.monto, contraparteNombre: otro?.username ?? '' },
    });

    await this.actualizarEstadoEvento(deuda.eventoId);

    return saldada;
  }

  /**
   * Un evento se finaliza cuando no le queda ninguna deuda pendiente
   * (definición de Duda #5). Es lo que enciende el badge "SALDADO" del
   * historial. Si vuelve a haber deuda, se revierte a `confirmado`.
   */
  private async actualizarEstadoEvento(eventoId: string): Promise<void> {
    const evento = await this.eventos.findById(eventoId);
    if (!evento || evento.estado === 'cancelado') return;

    const [pendientes, total] = await Promise.all([
      this.deudas.contarPendientes(eventoId),
      this.deudas.contarTotal(eventoId),
    ]);

    if (pendientes === 0 && total > 0 && evento.estado !== 'finalizado') {
      await this.eventos.updateEstado(eventoId, 'finalizado');
    } else if (pendientes > 0 && evento.estado === 'finalizado') {
      await this.eventos.updateEstado(eventoId, 'confirmado');
    }
  }

  private clave(deudorId: string, acreedorId: string): string {
    return `${deudorId}->${acreedorId}`;
  }
}
