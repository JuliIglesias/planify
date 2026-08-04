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

export class FakePushNotifier implements R.PushNotifier {
  /** Registro de envíos, para verificar en tests. */
  enviados: { tokens: string[]; mensaje: R.MensajePush }[] = [];
  async enviar(deviceTokens: string[], mensaje: R.MensajePush): Promise<void> {
    this.enviados.push({ tokens: deviceTokens, mensaje });
  }
}

export class FakeDeviceRegistry implements R.DeviceRegistry {
  private readonly porUsuario = new Map<string, Set<string>>();
  async registrar(usuarioId: string, deviceToken: string): Promise<void> {
    const set = this.porUsuario.get(usuarioId) ?? new Set<string>();
    set.add(deviceToken);
    this.porUsuario.set(usuarioId, set);
  }
  async tokensDe(usuarioIds: string[]): Promise<string[]> {
    const tokens: string[] = [];
    for (const id of usuarioIds) for (const t of this.porUsuario.get(id) ?? []) tokens.push(t);
    return tokens;
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
  async findByUsername(username: string) {
    return this.usuarios.find((u) => u.username === username) ?? null;
  }
  async findManyByIds(ids: string[]) {
    return this.usuarios.filter((u) => ids.includes(u.id));
  }

  async create(data: R.CrearUsuarioData): Promise<D.Usuario> {
    return this.agregar({
      username: data.username,
      email: data.email,
      passwordHash: data.passwordHash,
    });
  }

  async updateProfile(id: string, data: R.ActualizarPerfilData): Promise<D.Usuario> {
    const u = this.usuarios.find((x) => x.id === id)!;
    if (data.username !== undefined) u.username = data.username;
    if (data.avatarUrl !== undefined) u.avatarUrl = data.avatarUrl;
    if (data.idiomaPreferido !== undefined) u.idiomaPreferido = data.idiomaPreferido;
    return u;
  }

  async updatePassword(id: string, passwordHash: string): Promise<void> {
    const u = this.usuarios.find((x) => x.id === id)!;
    u.passwordHash = passwordHash;
  }

  async search(query: string, exceptoUsuarioId: string): Promise<D.PersonaBusqueda[]> {
    const q = query.toLowerCase();
    return this.usuarios
      .filter(
        (u) =>
          u.id !== exceptoUsuarioId &&
          (u.username.toLowerCase().includes(q) || u.email.toLowerCase().includes(q)),
      )
      .map((u) => ({ id: u.id, username: u.username, email: u.email }));
  }

  agregar(parcial: Partial<D.Usuario> = {}): D.Usuario {
    const usuario: D.Usuario = {
      id: nuevoId('usr'),
      username: nuevoId('usuario'),
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

export class FakeAmistadRepository implements R.AmistadRepository {
  amistades: D.Amistad[] = [];
  constructor(private readonly usuarios?: FakeUsuarioRepository) {}

  private usernameDe(usuarioId: string): string {
    return this.usuarios?.usuarios.find((u) => u.id === usuarioId)?.username ?? usuarioId;
  }

  private emailDe(usuarioId: string): string {
    return this.usuarios?.usuarios.find((u) => u.id === usuarioId)?.email ?? '';
  }

  async crear(solicitanteId: string, receptorId: string): Promise<D.Amistad> {
    const amistad: D.Amistad = {
      id: nuevoId('ami'),
      usuarioId1: solicitanteId,
      usuarioId2: receptorId,
      estado: 'pendiente',
      createdAt: new Date('2026-01-01'),
    };
    this.amistades.push(amistad);
    return amistad;
  }

  async findById(id: string) {
    return this.amistades.find((a) => a.id === id) ?? null;
  }

  async findEntre(a: string, b: string) {
    return (
      this.amistades.find(
        (x) =>
          (x.usuarioId1 === a && x.usuarioId2 === b) ||
          (x.usuarioId1 === b && x.usuarioId2 === a),
      ) ?? null
    );
  }

  async aceptar(id: string) {
    const amistad = this.amistades.find((a) => a.id === id)!;
    amistad.estado = 'aceptada';
    return amistad;
  }

  async listAmigos(usuarioId: string): Promise<D.PersonaBusqueda[]> {
    return this.amistades
      .filter(
        (a) =>
          a.estado === 'aceptada' &&
          (a.usuarioId1 === usuarioId || a.usuarioId2 === usuarioId),
      )
      .map((a) => {
        const otro = a.usuarioId1 === usuarioId ? a.usuarioId2 : a.usuarioId1;
        return { id: otro, username: this.usernameDe(otro), email: this.emailDe(otro) };
      });
  }

  async listSolicitudesRecibidas(usuarioId: string): Promise<R.SolicitudAmistad[]> {
    return this.amistades
      .filter((a) => a.estado === 'pendiente' && a.usuarioId2 === usuarioId)
      .map((a) => ({
        amistadId: a.id,
        de: {
          id: a.usuarioId1,
          username: this.usernameDe(a.usuarioId1),
          email: this.emailDe(a.usuarioId1),
        },
      }));
  }
}

export class FakeGrupoRepository implements R.GrupoRepository {
  grupos: D.Grupo[] = [];
  miembros: { grupoId: string; usuarioId: string }[] = [];

  // Opcional: resuelve el nombre real de cada miembro a partir de los usuarios.
  constructor(private readonly usuarios?: FakeUsuarioRepository) {}

  private usernameDe(usuarioId: string): string {
    return this.usuarios?.usuarios.find((u) => u.id === usuarioId)?.username ?? usuarioId;
  }

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
          .map((m) => ({ id: m.usuarioId, username: this.usernameDe(m.usuarioId) })),
      }));
  }

  async listMiembros(grupoId: string): Promise<D.PersonaRef[]> {
    return this.miembros
      .filter((m) => m.grupoId === grupoId)
      .map((m) => ({ id: m.usuarioId, username: this.usernameDe(m.usuarioId) }));
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

  async actualizar(id: string, data: { nombre?: string, avatarUrl?: string | null }): Promise<D.Grupo> {
    const grupo = this.grupos.find((g) => g.id === id)!;
    if (data.nombre !== undefined) grupo.nombre = data.nombre;
    if (data.avatarUrl !== undefined) grupo.avatarUrl = data.avatarUrl;
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
      rangoInicio: data.rangoInicio,
      rangoFin: data.rangoFin,
      extensionesRango: 0,
      fechaHoraFin: null,
      creadoPor: '',
      createdAt: new Date('2026-07-28T10:00:00Z'),
    };
    this.eventos.push(evento);

    const organizador = this.participantes!.agregar({
      eventoId: evento.id,
      usuarioId: data.organizadorUsuarioId,
      username: data.organizadorUsername,
      esOrganizador: true,
      estadoAsistencia: 'confirmado',
    });
    evento.creadoPor = organizador.id;

    // H-01: los demás miembros del grupo también participan del evento.
    for (const m of data.otrosMiembros ?? []) {
      if (m.usuarioId === data.organizadorUsuarioId) continue;
      this.participantes!.agregar({
        eventoId: evento.id,
        usuarioId: m.usuarioId,
        username: m.username,
      });
    }

    return { evento, organizador };
  }

  async updateEstado(id: string, estado: D.EventoEstado) {
    const evento = this.eventos.find((e) => e.id === id)!;
    evento.estado = estado;
    return evento;
  }

  async confirmarHorario(id: string, fechaHoraInicio: Date, fechaHoraFin: Date) {
    const evento = this.eventos.find((e) => e.id === id)!;
    evento.estado = 'confirmado';
    evento.fechaHoraInicio = fechaHoraInicio;
    evento.fechaHoraFin = fechaHoraFin;
    return evento;
  }

  async extenderRango(id: string, nuevoRangoFin: Date) {
    const evento = this.eventos.find((e) => e.id === id)!;
    evento.rangoFin = nuevoRangoFin;
    evento.extensionesRango += 1;
    return evento;
  }

  async listUpcomingForUsuario(usuarioId: string, ahora: Date): Promise<R.EventoConResumen[]> {
    return this.paraUsuario(usuarioId)
      .filter(
        (e) =>
          e.estado === 'planificacion' ||
          (e.estado === 'confirmado' &&
            (e.fechaHoraInicio === null || e.fechaHoraInicio >= ahora)),
      )
      .map((e) => this.toResumen(e));
  }

  async listPastForUsuario(usuarioId: string, ahora: Date): Promise<R.EventoConResumen[]> {
    return this.paraUsuario(usuarioId)
      .filter(
        (e) =>
          e.estado === 'finalizado' ||
          e.estado === 'cancelado' ||
          (e.estado === 'confirmado' &&
            e.fechaHoraInicio !== null &&
            e.fechaHoraInicio < ahora),
      )
      .map((e) => this.toResumen(e));
  }

  async listHistoryForUsuario(usuarioId: string, finDeMesActual: Date): Promise<R.EventoConResumen[]> {
    return this.listPastForUsuario(usuarioId, finDeMesActual);
  }

  private paraUsuario(usuarioId: string): D.Evento[] {
    const idsDelUsuario = new Set(
      (this.participantes?.participantes ?? [])
        .filter((p) => p.usuarioId === usuarioId)
        .map((p) => p.eventoId),
    );
    return this.eventos.filter((e) => idsDelUsuario.has(e.id));
  }

  private toResumen(e: D.Evento): R.EventoConResumen {
    const parts = (this.participantes?.participantes ?? []).filter((p) => p.eventoId === e.id);
    return {
      ...e,
      grupoNombre: '',
      participantes: parts.map((p) => ({
        id: p.id,
        username: p.username,
        estadoAsistencia: p.estadoAsistencia,
      })),
      confirmados: parts.filter((p) => p.estadoAsistencia === 'confirmado').length,
    };
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
      rangoInicio: new Date('2026-07-28T10:00:00Z'),
      rangoFin: new Date('2026-08-11T10:00:00Z'),
      extensionesRango: 0,
      fechaHoraFin: null,
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
      username: data.username,
      esAnonimo: true,
      tokenSesion: data.tokenSesion,
    });
  }

  async createParaUsuario(data: R.CrearParticipanteRegistradoData) {
    const existente = this.participantes.find(
      (p) => p.eventoId === data.eventoId && p.usuarioId === data.usuarioId,
    );
    if (existente) return existente;
    return this.agregar({
      eventoId: data.eventoId,
      usuarioId: data.usuarioId,
      username: data.username,
      esAnonimo: false,
      esOrganizador: false,
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

  async existsUsernameAnonimo(username: string) {
    return this.participantes.some(
      (p) => p.esAnonimo && p.username.toLowerCase() === username.toLowerCase(),
    );
  }

  agregar(parcial: Partial<D.Participante> = {}): D.Participante {
    const participante: D.Participante = {
      id: nuevoId('part'),
      eventoId: 'evt-1',
      usuarioId: null,
      username: 'Participante',
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
      .map((g) => ({ ...g, creador: { id: g.creadoPor, username: 'Creador' } }));
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
      username: p?.username ?? participanteId,
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
        asignado: t.asignadoA ? { id: t.asignadoA, username: t.asignadoA } : null,
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
    const t = this.tareas.find((x) => x.id === id);
    if (!t) throw new Error('not found');
    t.asignadoA = asignadoA;
    t.estado = 'pendiente';
    return { ...t, asignado: { id: asignadoA, username: asignadoA } };
  }

  async desasignar(id: string): Promise<R.TareaConAsignado> {
    const t = this.tareas.find((x) => x.id === id);
    if (!t) throw new Error('not found');
    t.asignadoA = null;
    t.estado = 'no_asignado';
    return { ...t, asignado: null };
  }

  async cambiarEstado(id: string, estado: D.TareaEstado): Promise<D.Tarea> {
    const t = this.tareas.find((x) => x.id === id);
    if (!t) throw new Error('not found');
    t.estado = estado;
    return t;
  }

  async eliminar(id: string): Promise<void> {
    this.tareas = this.tareas.filter((t) => t.id !== id);
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
      // Cada entrada un segundo más tarde que la anterior: así el orden y la
      // paginación por cursor (Tanda 6, Item 2) son deterministas en los tests.
      createdAt: new Date(new Date('2026-07-28T12:00:00Z').getTime() + this.entradas.length * 1000),
    };
    this.entradas.push(entrada);
    return entrada;
  }

  async listByEvento(eventoId: string): Promise<R.EntradaLog[]> {
    return this.entradas
      .filter((e) => e.eventoId === eventoId)
      .map((e) => ({
        ...e,
        actor: { id: e.actorParticipanteId, username: e.actorParticipanteId },
      }));
  }

  async listRecientesPorEventos(
    eventoIds: string[],
    limite: number,
    before?: Date,
  ): Promise<R.EntradaLogConEvento[]> {
    return this.entradas
      .filter((e) => eventoIds.includes(e.eventoId))
      .filter((e) => !before || e.createdAt.getTime() < before.getTime())
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
      .slice(0, limite)
      .map((e) => ({
        ...e,
        actor: { id: e.actorParticipanteId, username: e.actorParticipanteId },
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
  /**
   * Item 4 — necesita saber el estado de asistencia de cada participante para
   * excluir a quien dijo "No voy" del heatmap, igual que hace el repositorio
   * real con el join a `participante` en Prisma.
   */
  constructor(private readonly participantes?: FakeParticipanteRepository) {}

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
      const participante = this.participantes?.participantes.find(
        (p) => p.id === s.participanteId,
      );
      // Sin repositorio de participantes (tests que no lo necesitan) no se
      // filtra nada, igual que si nadie hubiera dicho "No voy".
      if (participante?.estadoAsistencia === 'rechazado') continue;

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

  async disponiblesEnRango(
    eventoId: string,
    diaSemana: number,
    bloqueHoraInicio: number,
    bloqueHoraFin: number,
  ): Promise<R.DisponibilidadEnRango> {
    const bloquesPorParticipante = new Map<string, Set<number>>();
    for (const s of this.slots.filter(
      (x) =>
        x.eventoId === eventoId &&
        x.diaSemana === diaSemana &&
        x.bloqueHora >= bloqueHoraInicio &&
        x.bloqueHora < bloqueHoraFin,
    )) {
      const participante = this.participantes?.participantes.find(
        (p) => p.id === s.participanteId,
      );
      if (participante?.estadoAsistencia === 'rechazado') continue;

      const bloques = bloquesPorParticipante.get(s.participanteId) ?? new Set<number>();
      bloques.add(s.bloqueHora);
      bloquesPorParticipante.set(s.participanteId, bloques);
    }

    const bloquesNecesarios = bloqueHoraFin - bloqueHoraInicio;
    const disponibles = [...bloquesPorParticipante.values()].filter(
      (bloques) => bloques.size >= bloquesNecesarios,
    ).length;

    const total = (this.participantes?.participantes ?? []).filter(
      (p) => p.eventoId === eventoId && p.estadoAsistencia !== 'rechazado',
    ).length;

    return { disponibles, total };
  }
}

export class FakeProfileAvailabilityRepository implements R.ProfileAvailabilityRepository {
  slots: R.SlotDeUsuario[] = [];

  async replaceForUsuario(usuarioId: string, slots: R.SlotDisponibilidad[]): Promise<void> {
    this.slots = this.slots.filter((s) => s.usuarioId !== usuarioId);
    for (const s of slots) this.slots.push({ usuarioId, ...s });
  }

  async findByUsuario(usuarioId: string): Promise<R.SlotDisponibilidad[]> {
    return this.slots
      .filter((s) => s.usuarioId === usuarioId)
      .map((s) => ({ diaSemana: s.diaSemana, bloqueHora: s.bloqueHora }));
  }

  async slotsDeUsuarios(usuarioIds: string[]): Promise<R.SlotDeUsuario[]> {
    return this.slots.filter((s) => usuarioIds.includes(s.usuarioId));
  }
}

/** Tanda 6, Item 5 — no sube nada de verdad, solo registra qué se "subió". */
export class FakeImageStorageRepository implements R.ImageStorageRepository {
  subidas: { carpeta: string; mimeType: string }[] = [];

  async subir(carpeta: string, _buffer: Buffer, mimeType: string): Promise<string> {
    this.subidas.push({ carpeta, mimeType });
    const extension = mimeType.split('/')[1] ?? 'bin';
    return `https://fake-bucket.local/${carpeta}/${this.subidas.length}.${extension}`;
  }
}

export class FakeLocationRepository implements R.LocationRepository {
  ubicaciones: R.UbicacionFavorita[] = [];

  async listByUsuario(usuarioId: string): Promise<R.UbicacionFavorita[]> {
    return this.ubicaciones.filter((u) => u.usuarioId === usuarioId);
  }

  async create(usuarioId: string, etiqueta: string, texto: string): Promise<R.UbicacionFavorita> {
    const u: R.UbicacionFavorita = { id: nuevoId('ubi'), usuarioId, etiqueta, texto };
    this.ubicaciones.push(u);
    return u;
  }

  async findById(id: string): Promise<R.UbicacionFavorita | null> {
    return this.ubicaciones.find((u) => u.id === id) ?? null;
  }

  async delete(id: string): Promise<void> {
    this.ubicaciones = this.ubicaciones.filter((u) => u.id !== id);
  }
}

