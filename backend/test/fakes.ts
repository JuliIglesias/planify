import * as D from '../src/domain/entities';
import * as R from '../src/domain/repositories';

/**
 * Implementaciones en memoria de los repositorios.
 *
 * Existen gracias a que los servicios dependen de interfaces y no de Prisma:
 * permiten testear las reglas de negocio sin levantar una base de datos.
 */

let contador = 0;
const nuevoId = (prefijo: string) => `${prefijo}-${++contador}`;

export class FakeClock implements R.Clock {
  constructor(private fecha = new Date('2026-07-28T12:00:00Z')) {}
  now(): Date {
    return this.fecha;
  }
  avanzarHoras(horas: number): void {
    this.fecha = new Date(this.fecha.getTime() + horas * 3600_000);
  }
}

export class FakeIdGenerator implements R.IdGenerator {
  private n = 0;
  generate(): string {
    return `id-${++this.n}`;
  }
}

export class FakePasswordHasher implements R.PasswordHasher {
  async hash(plano: string): Promise<string> {
    return `hash(${plano})`;
  }
  async compare(plano: string, hash: string): Promise<boolean> {
    return hash === `hash(${plano})`;
  }
}

export class FakeTokenService implements R.TokenService {
  sign(payload: R.TokenOrganizador): string {
    return JSON.stringify(payload);
  }
  verify(token: string): R.TokenOrganizador {
    return JSON.parse(token) as R.TokenOrganizador;
  }
}

export class FakeUsuarioRepository implements R.UsuarioRepository {
  constructor(public usuarios: D.Usuario[] = []) {}

  async findById(id: string) {
    return this.usuarios.find((u) => u.id === id) ?? null;
  }
  async findByEmail(email: string) {
    return this.usuarios.find((u) => u.email === email) ?? null;
  }
  async findManyByIds(ids: string[]) {
    return this.usuarios.filter((u) => ids.includes(u.id));
  }

  agregar(parcial: Partial<D.Usuario> = {}): D.Usuario {
    const usuario: D.Usuario = {
      id: nuevoId('usr'),
      nombre: 'Usuario',
      email: `${nuevoId('mail')}@test.com`,
      passwordHash: 'hash(secreto)',
      avatarUrl: null,
      idiomaPreferido: 'es',
      createdAt: new Date('2026-01-01'),
      ...parcial,
    };
    this.usuarios.push(usuario);
    return usuario;
  }
}

export class FakeGrupoRepository implements R.GrupoRepository {
  grupos: D.Grupo[] = [];
  miembros: { grupoId: string; usuarioId: string }[] = [];

  async findById(id: string) {
    return this.grupos.find((g) => g.id === id) ?? null;
  }

  async listByUsuario(usuarioId: string): Promise<R.GrupoConMiembros[]> {
    const ids = this.miembros.filter((m) => m.usuarioId === usuarioId).map((m) => m.grupoId);
    return this.grupos
      .filter((g) => ids.includes(g.id))
      .map((g) => ({
        ...g,
        miembros: this.miembros
          .filter((m) => m.grupoId === g.id)
          .map((m) => ({ id: m.usuarioId, nombre: m.usuarioId })),
      }));
  }

  async create(nombre: string, usuarioIds: string[]): Promise<D.Grupo> {
    const grupo: D.Grupo = {
      id: nuevoId('grp'),
      nombre,
      avatarUrl: null,
      createdAt: new Date('2026-01-01'),
    };
    this.grupos.push(grupo);
    for (const usuarioId of new Set(usuarioIds)) {
      this.miembros.push({ grupoId: grupo.id, usuarioId });
    }
    return grupo;
  }

  async rename(id: string, nombre: string): Promise<D.Grupo> {
    const grupo = this.grupos.find((g) => g.id === id)!;
    grupo.nombre = nombre;
    return grupo;
  }

  async esMiembro(grupoId: string, usuarioId: string) {
    return this.miembros.some((m) => m.grupoId === grupoId && m.usuarioId === usuarioId);
  }
  async contarMiembros(grupoId: string) {
    return this.miembros.filter((m) => m.grupoId === grupoId).length;
  }
  async agregarMiembro(grupoId: string, usuarioId: string) {
    if (!(await this.esMiembro(grupoId, usuarioId))) {
      this.miembros.push({ grupoId, usuarioId });
    }
  }
  async quitarMiembro(grupoId: string, usuarioId: string) {
    this.miembros = this.miembros.filter(
      (m) => !(m.grupoId === grupoId && m.usuarioId === usuarioId),
    );
  }
}

export class FakeEventoRepository implements R.EventoRepository {
  eventos: D.Evento[] = [];
  constructor(private readonly participantes?: FakeParticipanteRepository) {}

  async findById(id: string) {
    return this.eventos.find((e) => e.id === id) ?? null;
  }

  async createWithOrganizer(data: R.CrearEventoData) {
    const evento: D.Evento = {
      id: nuevoId('evt'),
      grupoId: data.grupoId,
      nombre: data.nombre,
      lugarTexto: data.lugarTexto,
      estado: 'planificacion',
      fechaHoraInicio: null,
      creadoPor: '',
      createdAt: new Date('2026-07-28T10:00:00Z'),
    };
    this.eventos.push(evento);

    const organizador = this.participantes!.agregar({
      eventoId: evento.id,
      usuarioId: data.organizadorUsuarioId,
      nombreDisplay: data.organizadorNombre,
      esOrganizador: true,
      estadoAsistencia: 'confirmado',
    });
    evento.creadoPor = organizador.id;

    return { evento, organizador };
  }

  async updateEstado(id: string, estado: D.EventoEstado) {
    const evento = this.eventos.find((e) => e.id === id)!;
    evento.estado = estado;
    return evento;
  }

  async confirmarHorario(id: string, fechaHoraInicio: Date) {
    const evento = this.eventos.find((e) => e.id === id)!;
    evento.estado = 'confirmado';
    evento.fechaHoraInicio = fechaHoraInicio;
    return evento;
  }

  async listUpcomingForUsuario(): Promise<R.EventoConResumen[]> {
    return [];
  }
  async listPastForUsuario(): Promise<R.EventoConResumen[]> {
    return [];
  }
  async listByGrupo(grupoId: string) {
    return this.eventos.filter((e) => e.grupoId === grupoId);
  }

  agregar(parcial: Partial<D.Evento> = {}): D.Evento {
    const evento: D.Evento = {
      id: nuevoId('evt'),
      grupoId: 'grp-1',
      nombre: 'Asado',
      lugarTexto: 'Casa de Juli',
      estado: 'planificacion',
      fechaHoraInicio: null,
      creadoPor: 'part-1',
      createdAt: new Date('2026-07-28T10:00:00Z'),
      ...parcial,
    };
    this.eventos.push(evento);
    return evento;
  }
}

export class FakeParticipanteRepository implements R.ParticipanteRepository {
  participantes: D.Participante[] = [];

  async findById(id: string) {
    return this.participantes.find((p) => p.id === id) ?? null;
  }
  async findByTokenSesion(token: string) {
    return this.participantes.find((p) => p.tokenSesion === token) ?? null;
  }
  async findByEventoAndUsuario(eventoId: string, usuarioId: string) {
    return (
      this.participantes.find((p) => p.eventoId === eventoId && p.usuarioId === usuarioId) ?? null
    );
  }
  async findOrganizador(eventoId: string) {
    return (
      this.participantes.find((p) => p.eventoId === eventoId && p.esOrganizador) ?? null
    );
  }
  async listByEvento(eventoId: string) {
    return this.participantes.filter((p) => p.eventoId === eventoId);
  }
  async listByUsuario(usuarioId: string) {
    return this.participantes.filter((p) => p.usuarioId === usuarioId);
  }

  async createAnonimo(data: R.CrearParticipanteAnonimoData) {
    return this.agregar({
      eventoId: data.eventoId,
      nombreDisplay: data.nombreDisplay,
      esAnonimo: true,
      tokenSesion: data.tokenSesion,
    });
  }

  async updateAsistencia(id: string, estado: D.AsistenciaEstado) {
    const p = this.participantes.find((x) => x.id === id)!;
    p.estadoAsistencia = estado;
    return p;
  }

  async marcarLeido(id: string, cuando: Date) {
    const p = this.participantes.find((x) => x.id === id)!;
    p.ultimaLecturaAt = cuando;
    return p;
  }

  async invalidarSesionesAnonimas(eventoId: string) {
    for (const p of this.participantes) {
      if (p.eventoId === eventoId && p.esAnonimo) p.tokenSesion = null;
    }
  }

  agregar(parcial: Partial<D.Participante> = {}): D.Participante {
    const participante: D.Participante = {
      id: nuevoId('part'),
      eventoId: 'evt-1',
      usuarioId: null,
      nombreDisplay: 'Participante',
      esAnonimo: false,
      esOrganizador: false,
      tokenSesion: null,
      estadoAsistencia: 'sin_confirmar',
      ultimaLecturaAt: null,
      createdAt: new Date('2026-07-28'),
      ...parcial,
    };
    this.participantes.push(participante);
    return participante;
  }
}

export class FakeGastoRepository implements R.GastoRepository {
  gastos: D.GastoCompleto[] = [];

  async create(data: R.CrearGastoData): Promise<D.GastoCompleto> {
    const gasto: D.GastoCompleto = {
      id: nuevoId('gst'),
      eventoId: data.eventoId,
      descripcion: data.descripcion,
      montoTotal: data.montoTotal,
      creadoPor: data.creadoPor,
      fecha: new Date('2026-07-28'),
      acreedores: data.acreedores,
      deudores: data.deudores,
    };
    this.gastos.push(gasto);
    return gasto;
  }

  async listByEvento(eventoId: string): Promise<R.GastoDetallado[]> {
    return this.gastos
      .filter((g) => g.eventoId === eventoId)
      .map((g) => ({ ...g, creador: { id: g.creadoPor, nombre: 'Creador' } }));
  }

  async listMontosByEvento(eventoId: string) {
    return this.gastos.filter((g) => g.eventoId === eventoId);
  }

  async contarPorEvento(eventoIds: string[]) {
    const conteo: Record<string, number> = {};
    for (const g of this.gastos) {
      if (eventoIds.includes(g.eventoId)) conteo[g.eventoId] = (conteo[g.eventoId] ?? 0) + 1;
    }
    return conteo;
  }
}

export class FakeDeudaRepository implements R.DeudaRepository {
  deudas: D.DeudaSimplificada[] = [];

  /**
   * Opcional: con el repo de participantes, las deudas resuelven el nombre y
   * el `usuarioId` reales de cada parte. Hace falta para probar la
   * compensación cruzada (FR9), que agrupa por usuario registrado.
   */
  constructor(private readonly participantes?: FakeParticipanteRepository) {}

  /** Atajo para armar una deuda en un test. */
  agregar(parcial: Partial<D.DeudaSimplificada> = {}): D.DeudaSimplificada {
    const deuda: D.DeudaSimplificada = {
      id: nuevoId('deu'),
      eventoId: 'evt-1',
      deudorParticipanteId: 'part-1',
      acreedorParticipanteId: 'part-2',
      monto: '100.00',
      estado: 'pendiente',
      saldadoEn: null,
      ...parcial,
    };
    this.deudas.push(deuda);
    return deuda;
  }

  async findById(id: string) {
    return this.deudas.find((d) => d.id === id) ?? null;
  }

  async listByEvento(eventoId: string): Promise<R.DeudaConPersonas[]> {
    return this.deudas.filter((d) => d.eventoId === eventoId).map(this.conPersonas);
  }

  async listByParticipantes(ids: string[]): Promise<R.DeudaConPersonas[]> {
    return this.deudas
      .filter(
        (d) =>
          ids.includes(d.deudorParticipanteId) || ids.includes(d.acreedorParticipanteId),
      )
      .map(this.conPersonas);
  }

  async reemplazarEvento(eventoId: string, nuevas: R.NuevaDeuda[]) {
    this.deudas = this.deudas.filter((d) => d.eventoId !== eventoId);
    for (const n of nuevas) {
      this.deudas.push({ id: nuevoId('deu'), eventoId, ...n });
    }
    return this.deudas.filter((d) => d.eventoId === eventoId);
  }

  async marcarSaldada(id: string, cuando: Date) {
    const deuda = this.deudas.find((d) => d.id === id)!;
    deuda.estado = 'saldado';
    deuda.saldadoEn = cuando;
    return deuda;
  }

  async marcarSaldadasEnLote(ids: string[], cuando: Date) {
    let saldadas = 0;
    for (const deuda of this.deudas) {
      if (ids.includes(deuda.id) && deuda.estado !== 'saldado') {
        deuda.estado = 'saldado';
        deuda.saldadoEn = cuando;
        saldadas++;
      }
    }
    return saldadas;
  }

  async contarPendientes(eventoId: string) {
    return this.deudas.filter((d) => d.eventoId === eventoId && d.estado !== 'saldado').length;
  }
  async contarTotal(eventoId: string) {
    return this.deudas.filter((d) => d.eventoId === eventoId).length;
  }

  private conPersonas = (d: D.DeudaSimplificada): R.DeudaConPersonas => ({
    ...d,
    deudor: this.persona(d.deudorParticipanteId),
    acreedor: this.persona(d.acreedorParticipanteId),
    eventoNombre: `Evento ${d.eventoId}`,
  });

  private persona(participanteId: string) {
    const p = this.participantes?.participantes.find((x) => x.id === participanteId);
    return {
      id: participanteId,
      nombre: p?.nombreDisplay ?? participanteId,
      usuarioId: p?.usuarioId ?? null,
    };
  }
}

export class FakeTareaRepository implements R.TareaRepository {
  tareas: D.Tarea[] = [];

  async findById(id: string) {
    return this.tareas.find((t) => t.id === id) ?? null;
  }

  async listByEvento(eventoId: string): Promise<R.TareaConAsignado[]> {
    return this.tareas
      .filter((t) => t.eventoId === eventoId)
      .map((t) => ({
        ...t,
        asignado: t.asignadoA ? { id: t.asignadoA, nombre: t.asignadoA } : null,
      }));
  }

  async contarPendientesPorEvento(eventoIds: string[]) {
    const conteo: Record<string, number> = {};
    for (const t of this.tareas) {
      if (eventoIds.includes(t.eventoId) && t.estado !== 'completado') {
        conteo[t.eventoId] = (conteo[t.eventoId] ?? 0) + 1;
      }
    }
    return conteo;
  }

  async create(eventoId: string, titulo: string, creadoPor: string): Promise<D.Tarea> {
    const tarea: D.Tarea = {
      id: nuevoId('tar'),
      eventoId,
      titulo,
      estado: 'no_asignado',
      asignadoA: null,
      creadoPor,
      createdAt: new Date('2026-07-28'),
    };
    this.tareas.push(tarea);
    return tarea;
  }

  async asignar(id: string, asignadoA: string): Promise<R.TareaConAsignado> {
    const tarea = this.tareas.find((t) => t.id === id)!;
    tarea.asignadoA = asignadoA;
    tarea.estado = 'pendiente';
    return { ...tarea, asignado: { id: asignadoA, nombre: asignadoA } };
  }

  async cambiarEstado(id: string, estado: D.TareaEstado) {
    const tarea = this.tareas.find((t) => t.id === id)!;
    tarea.estado = estado;
    return tarea;
  }
}

export class FakeLogActividadRepository implements R.LogActividadRepository {
  entradas: D.LogActividad[] = [];

  async create(data: R.CrearLogData): Promise<D.LogActividad> {
    const entrada: D.LogActividad = {
      id: nuevoId('log'),
      eventoId: data.eventoId,
      tipo: data.tipo,
      actorParticipanteId: data.actorParticipanteId,
      payload: data.payload ?? null,
      createdAt: new Date('2026-07-28T12:00:00Z'),
    };
    this.entradas.push(entrada);
    return entrada;
  }

  async listByEvento(eventoId: string): Promise<R.EntradaLog[]> {
    return this.entradas
      .filter((e) => e.eventoId === eventoId)
      .map((e) => ({
        ...e,
        actor: { id: e.actorParticipanteId, nombre: e.actorParticipanteId },
      }));
  }

  async listRecientesPorEventos(
    eventoIds: string[],
    limite: number,
  ): Promise<R.EntradaLogConEvento[]> {
    return this.entradas
      .filter((e) => eventoIds.includes(e.eventoId))
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
      .slice(0, limite)
      .map((e) => ({
        ...e,
        actor: { id: e.actorParticipanteId, nombre: e.actorParticipanteId },
        eventoNombre: 'Evento',
      }));
  }

  async contarNoLeidas(eventoId: string, participanteId: string, desde: Date | null) {
    return this.entradas.filter(
      (e) =>
        e.eventoId === eventoId &&
        e.actorParticipanteId !== participanteId &&
        (!desde || e.createdAt > desde),
    ).length;
  }

  /** Atajo para los tests: qué tipos de actividad se registraron. */
  tipos(): string[] {
    return this.entradas.map((e) => e.tipo);
  }
}

export class FakeInvitacionRepository implements R.InvitacionRepository {
  invitaciones: D.Invitacion[] = [];

  async create(eventoId: string, tokenUnico: string): Promise<D.Invitacion> {
    const invitacion: D.Invitacion = {
      id: nuevoId('inv'),
      eventoId,
      tokenUnico,
      expiraEn: null,
      usosMaximos: null,
    };
    this.invitaciones.push(invitacion);
    return invitacion;
  }

  async findByToken(tokenUnico: string) {
    return this.invitaciones.find((i) => i.tokenUnico === tokenUnico) ?? null;
  }
}

export class FakeDisponibilidadRepository implements R.DisponibilidadRepository {
  slots: { eventoId: string; participanteId: string; diaSemana: number; bloqueHora: number }[] =
    [];

  async replaceForParticipante(
    eventoId: string,
    participanteId: string,
    slots: R.SlotDisponibilidad[],
  ) {
    this.slots = this.slots.filter(
      (s) => !(s.eventoId === eventoId && s.participanteId === participanteId),
    );
    for (const slot of slots) {
      this.slots.push({ eventoId, participanteId, ...slot });
    }
  }

  async heatmapForEvento(eventoId: string): Promise<R.SlotHeatmap[]> {
    const conteo = new Map<string, number>();
    for (const s of this.slots.filter((x) => x.eventoId === eventoId)) {
      const clave = `${s.diaSemana}:${s.bloqueHora}`;
      conteo.set(clave, (conteo.get(clave) ?? 0) + 1);
    }
    return [...conteo.entries()].map(([clave, disponibles]) => {
      const [diaSemana, bloqueHora] = clave.split(':').map(Number);
      return { diaSemana, bloqueHora, disponibles };
    });
  }

  async findByParticipante(
    eventoId: string,
    participanteId: string,
  ): Promise<R.SlotDisponibilidad[]> {
    return this.slots
      .filter((s) => s.eventoId === eventoId && s.participanteId === participanteId)
      .map((s) => ({ diaSemana: s.diaSemana, bloqueHora: s.bloqueHora }));
  }
}

