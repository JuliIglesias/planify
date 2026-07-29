import { ActivityLogService } from '../src/modules/activity-log/activity-log.service';
import { DebtsService } from '../src/modules/debts/debts.service';
import {
  FakeClock,
  FakeDeudaRepository,
  FakeEventoRepository,
  FakeGastoRepository,
  FakeLogActividadRepository,
  FakeParticipanteRepository,
} from './fakes';

/**
 * FR9 — compensación de deudas entre eventos ([Duda #26](../../docs/02-decisiones.md)).
 *
 * Escenario base: Julieta y Marcos comparten dos eventos.
 *  - Asado: Julieta le debe $500 a Marcos
 *  - Cine:  Marcos le debe $300 a Julieta
 * Compensado, Julieta le debe $200.
 */
function armarEscenario() {
  const participantes = new FakeParticipanteRepository();
  const eventos = new FakeEventoRepository(participantes);
  const deudas = new FakeDeudaRepository(participantes);
  const gastos = new FakeGastoRepository();
  const logs = new FakeLogActividadRepository();
  const clock = new FakeClock();
  const log = new ActivityLogService(logs, participantes, clock);

  const service = new DebtsService(deudas, gastos, participantes, eventos, log, clock);

  const asado = eventos.agregar({ nombre: 'Asado', estado: 'confirmado' });
  const cine = eventos.agregar({ nombre: 'Cine', estado: 'confirmado' });

  // Julieta es usuario registrado; participa de los dos eventos.
  const juliEnAsado = participantes.agregar({
    eventoId: asado.id,
    usuarioId: 'usr-juli',
    nombreDisplay: 'Julieta',
  });
  const juliEnCine = participantes.agregar({
    eventoId: cine.id,
    usuarioId: 'usr-juli',
    nombreDisplay: 'Julieta',
  });

  // Marcos también.
  const marcosEnAsado = participantes.agregar({
    eventoId: asado.id,
    usuarioId: 'usr-marcos',
    nombreDisplay: 'Marcos',
  });
  const marcosEnCine = participantes.agregar({
    eventoId: cine.id,
    usuarioId: 'usr-marcos',
    nombreDisplay: 'Marcos',
  });

  deudas.agregar({
    eventoId: asado.id,
    deudorParticipanteId: juliEnAsado.id,
    acreedorParticipanteId: marcosEnAsado.id,
    monto: '500.00',
  });

  deudas.agregar({
    eventoId: cine.id,
    deudorParticipanteId: marcosEnCine.id,
    acreedorParticipanteId: juliEnCine.id,
    monto: '300.00',
  });

  return { service, deudas, eventos, logs, asado, cine, participantes };
}

describe('Balances — compensación cruzada entre eventos (FR9)', () => {
  it('el balance por persona ya viene compensado', async () => {
    const { service } = armarEscenario();

    const balance = await service.balanceDe('usr-juli');

    // $500 que debo − $300 que me deben = $200 que debo, en una sola línea.
    expect(balance.saldos).toHaveLength(1);
    expect(balance.saldos[0]).toMatchObject({
      id: 'usr-marcos',
      nombre: 'Marcos',
      monto: '200.00',
      estado: 'pagar',
    });
    expect(balance.balanceNeto).toBe('-200.00');
  });

  it('el detalle muestra el desglose por evento y el neto', async () => {
    const { service, asado, cine } = armarEscenario();

    const detalle = await service.detalleConPersona('usr-juli', 'usr-marcos');

    expect(detalle.nombre).toBe('Marcos');
    expect(detalle.monto).toBe('200.00');
    expect(detalle.estado).toBe('pagar');
    expect(detalle.totalQueDebo).toBe('500.00');
    expect(detalle.totalQueMeDebe).toBe('300.00');

    expect(detalle.deudas).toHaveLength(2);
    expect(detalle.deudas).toContainEqual(
      expect.objectContaining({ eventoId: asado.id, monto: '500.00', yoDebo: true }),
    );
    expect(detalle.deudas).toContainEqual(
      expect.objectContaining({ eventoId: cine.id, monto: '300.00', yoDebo: false }),
    );
  });

  it('la compensación es simétrica: Marcos ve que le deben $200', async () => {
    const { service } = armarEscenario();

    const balance = await service.balanceDe('usr-marcos');

    expect(balance.saldos[0]).toMatchObject({ monto: '200.00', estado: 'pendiente' });
    expect(balance.balanceNeto).toBe('200.00');
  });

  it('saldar desde Balances cierra las deudas de TODOS los eventos', async () => {
    const { service, deudas } = armarEscenario();

    const resultado = await service.saldarConPersona('usr-juli', 'usr-marcos');

    expect(resultado.saldadas).toBe(2);
    expect(resultado.eventosAfectados).toHaveLength(2);
    // Las dos deudas quedan saldadas, en ambos sentidos.
    expect(deudas.deudas.every((d) => d.estado === 'saldado')).toBe(true);
  });

  it('al saldar en cascada, cada evento afectado pasa a finalizado', async () => {
    const { service, eventos, asado, cine } = armarEscenario();

    await service.saldarConPersona('usr-juli', 'usr-marcos');

    expect(eventos.eventos.find((e) => e.id === asado.id)!.estado).toBe('finalizado');
    expect(eventos.eventos.find((e) => e.id === cine.id)!.estado).toBe('finalizado');
  });

  it('registra la actividad en cada evento afectado', async () => {
    const { service, logs, asado, cine } = armarEscenario();

    await service.saldarConPersona('usr-juli', 'usr-marcos');

    const entradas = logs.entradas.filter((e) => e.tipo === 'deuda_saldada');
    expect(entradas.map((e) => e.eventoId).sort()).toEqual([asado.id, cine.id].sort());
    expect(entradas[0].payload).toMatchObject({ compensacionCruzada: true });
  });

  it('después de saldar, el balance queda en cero', async () => {
    const { service } = armarEscenario();

    await service.saldarConPersona('usr-juli', 'usr-marcos');
    const balance = await service.balanceDe('usr-juli');

    expect(balance.saldos).toHaveLength(0);
    expect(balance.balanceNeto).toBe('0.00');
  });

  it('no deja saldar si no hay nada pendiente con esa persona', async () => {
    const { service } = armarEscenario();

    await service.saldarConPersona('usr-juli', 'usr-marcos');

    await expect(service.saldarConPersona('usr-juli', 'usr-marcos')).rejects.toThrow(
      /No hay deudas pendientes/,
    );
  });

  it('solo toca las deudas de la persona indicada', async () => {
    const { service, deudas, participantes, eventos } = armarEscenario();

    // Un tercero con una deuda aparte, que no debe verse afectado.
    const otroEvento = eventos.agregar({ nombre: 'Cumple' });
    const juliAca = participantes.agregar({
      eventoId: otroEvento.id,
      usuarioId: 'usr-juli',
      nombreDisplay: 'Julieta',
    });
    const sofia = participantes.agregar({
      eventoId: otroEvento.id,
      usuarioId: 'usr-sofia',
      nombreDisplay: 'Sofía',
    });
    const conSofia = deudas.agregar({
      eventoId: otroEvento.id,
      deudorParticipanteId: juliAca.id,
      acreedorParticipanteId: sofia.id,
      monto: '800.00',
    });

    await service.saldarConPersona('usr-juli', 'usr-marcos');

    expect(deudas.deudas.find((d) => d.id === conSofia.id)!.estado).toBe('pendiente');

    const balance = await service.balanceDe('usr-juli');
    expect(balance.saldos).toHaveLength(1);
    expect(balance.saldos[0]).toMatchObject({ id: 'usr-sofia', monto: '800.00' });
  });

  it('dentro de un evento se siguen viendo solo las deudas de ese evento', async () => {
    const { service, asado } = armarEscenario();

    const delEvento = await service.listarDelEvento(asado.id);

    // El cine no aparece acá: la compensación es solo de la pantalla Balances.
    expect(delEvento).toHaveLength(1);
    expect(delEvento[0].monto).toBe('500.00');
  });

  it('un anónimo se agrupa por participante, no por usuario', async () => {
    const { service, deudas, participantes, eventos } = armarEscenario();

    const evento = eventos.agregar({ nombre: 'Previa' });
    const juli = participantes.agregar({
      eventoId: evento.id,
      usuarioId: 'usr-juli',
      nombreDisplay: 'Julieta',
    });
    const anonimo = participantes.agregar({
      eventoId: evento.id,
      esAnonimo: true,
      nombreDisplay: 'Invitado',
    });
    deudas.agregar({
      eventoId: evento.id,
      deudorParticipanteId: anonimo.id,
      acreedorParticipanteId: juli.id,
      monto: '150.00',
    });

    const detalle = await service.detalleConPersona('usr-juli', anonimo.id);

    expect(detalle.nombre).toBe('Invitado');
    expect(detalle.monto).toBe('150.00');
    expect(detalle.estado).toBe('pendiente');
  });
});
