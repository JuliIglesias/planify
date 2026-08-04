import { Request, Response, Router } from 'express';
import { Container } from './container';
import { BadRequestError, UnauthorizedError } from './common/errors';
import { asyncHandler } from './middlewares/asyncHandler';
import { OrganizerRequest, ParticipantRequest } from './middlewares/guards';

/**
 * Todas las rutas de la API, agrupadas por épica de Jira.
 *
 * Los handlers son delgados a propósito: leen la request, delegan en un
 * servicio y responden. La lógica de negocio vive en `src/modules/*`, así que
 * cambiar una regla no obliga a tocar este archivo.
 */
export function createRoutes(c: Container): Router {
  const router = Router();
  const { soloOrganizador, soloParticipante } = c.guards;

  const exigirUsuario = (req: OrganizerRequest): string => {
    if (!req.usuarioId) throw new UnauthorizedError();
    return req.usuarioId;
  };

  const exigirParticipante = (req: ParticipantRequest): string => {
    if (!req.participanteId) throw new UnauthorizedError();
    return req.participanteId;
  };

  router.get('/health', (_req, res) => res.json({ status: 'ok' }));

  // ── SCRUM-7 · Acceso anónimo y login del organizador ────────────────────
  router.post(
    '/auth/login',
    asyncHandler(async (req: Request, res: Response) => {
      const { email, username, password } = req.body ?? {};
      const identificador = email ?? username;
      if (!identificador || !password) {
        throw new BadRequestError('email (o username) y password son requeridos');
      }
      res.json(await c.auth.login(identificador, password));
    }),
  );

  // ── SCRUM-14 · Registro, recuperación y perfil ──────────────────────────
  router.post(
    '/auth/register',
    asyncHandler(async (req: Request, res: Response) => {
      const { username, email, password } = req.body ?? {};
      res.status(201).json(await c.auth.register(username, email, password));
    }),
  );

  router.post(
    '/auth/reset/request',
    asyncHandler(async (req: Request, res: Response) => {
      const { email } = req.body ?? {};
      if (!email) throw new BadRequestError('email es requerido');
      // Siempre 200: no se revela si el email existe. En prod el token se
      // envía por correo (no se devuelve acá) — ver docs/06-estado-final.md.
      const { token } = await c.auth.solicitarReset(email);
      res.json({ ok: true, ...(process.env.NODE_ENV !== 'production' ? { token } : {}) });
    }),
  );

  router.post(
    '/auth/reset/confirm',
    asyncHandler(async (req: Request, res: Response) => {
      const { token, password } = req.body ?? {};
      if (!token) throw new BadRequestError('token es requerido');
      await c.auth.confirmarReset(token, password);
      res.json({ ok: true });
    }),
  );

  router.get(
    '/me/profile',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      res.json(await c.users.miPerfil(exigirUsuario(req)));
    }),
  );

  router.patch(
    '/me/profile',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      res.json(await c.users.actualizar(exigirUsuario(req), req.body ?? {}));
    }),
  );

  // ── SCRUM-14 · Disponibilidad de perfil (H-14) y coincidencias (HU-B4) ───
  router.get(
    '/me/availability',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      res.json(await c.profileAvailability.obtener(exigirUsuario(req)));
    }),
  );

  router.put(
    '/me/availability',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      await c.profileAvailability.guardar(exigirUsuario(req), req.body?.slots ?? []);
      res.status(204).send();
    }),
  );

  router.get(
    '/me/availability/friend-matches',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      res.json(await c.profileAvailability.coincidenciasConAmigos(exigirUsuario(req)));
    }),
  );

  // ── HU-B5 · Ubicaciones favoritas ────────────────────────────────────────
  router.get(
    '/me/locations',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      res.json(await c.locations.listar(exigirUsuario(req)));
    }),
  );

  router.post(
    '/me/locations',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      const { etiqueta, texto } = req.body ?? {};
      res.status(201).json(await c.locations.crear(exigirUsuario(req), etiqueta, texto));
    }),
  );

  router.delete(
    '/me/locations/:id',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      await c.locations.eliminar(exigirUsuario(req), String(req.params.id));
      res.status(204).send();
    }),
  );

  // ── SCRUM-14 · Amigos (HU-31/HU-32) ─────────────────────────────────────
  router.get(
    '/users/search',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      res.json(await c.friends.buscar(exigirUsuario(req), String(req.query.q ?? '')));
    }),
  );

  router.get(
    '/friends',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      res.json(await c.friends.listar(exigirUsuario(req)));
    }),
  );

  router.get(
    '/friends/requests',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      res.json(await c.friends.solicitudesPendientes(exigirUsuario(req)));
    }),
  );

  router.post(
    '/friends/request',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      const { usuarioId } = req.body ?? {};
      if (!usuarioId) throw new BadRequestError('usuarioId es requerido');
      await c.friends.enviarSolicitud(exigirUsuario(req), usuarioId);
      res.status(201).json({ ok: true });
    }),
  );

  router.post(
    '/friends/:id/accept',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      await c.friends.aceptar(exigirUsuario(req), String(req.params.id));
      res.json({ ok: true });
    }),
  );

  // Item 4 (Fase 5) — perfil de solo lectura de un amigo: disponibilidad
  // comparada (solo esa dupla) + eventos y grupos en común.
  router.get(
    '/friends/:id/profile',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      res.json(await c.friendProfile.obtener(exigirUsuario(req), String(req.params.id)));
    }),
  );

  router.post(
    '/participants/anonymous',
    asyncHandler(async (req: Request, res: Response) => {
      const { eventoId, username } = req.body ?? {};
      if (!eventoId) throw new BadRequestError('eventoId es requerido');
      res.status(201).json(await c.participants.unirseComoAnonimo(eventoId, username));
    }),
  );

  router.post(
    '/invitations',
    soloOrganizador,
    asyncHandler(async (req: Request, res: Response) => {
      const { eventoId } = req.body ?? {};
      if (!eventoId) throw new BadRequestError('eventoId es requerido');
      res.status(201).json(await c.invitations.crear(eventoId));
    }),
  );

  router.get(
    '/invitations/:token',
    asyncHandler(async (req: Request, res: Response) => {
      res.json(await c.invitations.resolver(String(req.params.token)));
    }),
  );

  // Item 2 — un usuario registrado (logueado) se une por su cuenta, en vez de
  // entrar como anónimo. Requiere estar autenticado; el token de invitación
  // solo dice a qué evento/grupo se une.
  router.post(
    '/invitations/:token/join',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      res.json(
        await c.groups.unirsePorInvitacion(String(req.params.token), exigirUsuario(req)),
      );
    }),
  );

  // ── SCRUM-8 · Eventos y grupos ──────────────────────────────────────────
  // Las rutas literales van antes de '/:id' para que no las capture el comodín.
  router.get(
    '/events/upcoming',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      res.json(await c.eventsQuery.proximosDe(exigirUsuario(req)));
    }),
  );

  router.get(
    '/events/history',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      res.json(await c.eventsQuery.historialDe(exigirUsuario(req)));
    }),
  );

  router.post(
    '/events',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      res.status(201).json(await c.events.crear(exigirUsuario(req), req.body ?? {}));
    }),
  );

  router.get(
    '/events/:id',
    soloParticipante,
    asyncHandler(async (req: ParticipantRequest, res: Response) => {
      // Item 1: chequea (y extiende si corresponde) el rango de fechas antes
      // de armar la vista, así el detalle siempre refleja el rango vigente.
      await c.events.chequearExtensionRango(String(req.params.id));
      res.json(await c.eventsQuery.detalle(String(req.params.id), req.participanteId));
    }),
  );

  router.patch(
    '/events/:id/cancel',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      res.json(await c.events.cancelar(exigirUsuario(req), String(req.params.id)));
    }),
  );

  // ── SCRUM-10 · Confirmación de asistencia ───────────────────────────────
  router.patch(
    '/events/:id/attendance',
    soloParticipante,
    asyncHandler(async (req: ParticipantRequest, res: Response) => {
      const { estado } = req.body ?? {};
      if (estado !== 'confirmado' && estado !== 'rechazado') {
        throw new BadRequestError('estado debe ser "confirmado" o "rechazado"');
      }
      res.json(await c.events.responderAsistencia(exigirParticipante(req), estado));
    }),
  );

  // ── SCRUM-9 · Disponibilidad, heatmap y horario ─────────────────────────
  router.post(
    '/events/:id/availability',
    soloParticipante,
    asyncHandler(async (req: ParticipantRequest, res: Response) => {
      await c.availability.guardar(
        String(req.params.id),
        exigirParticipante(req),
        req.body?.slots ?? [],
      );
      res.status(204).send();
    }),
  );

  router.get(
    '/events/:id/availability/me',
    soloParticipante,
    asyncHandler(async (req: ParticipantRequest, res: Response) => {
      res.json(
        await c.availability.obtenerDeParticipante(
          String(req.params.id),
          exigirParticipante(req),
        ),
      );
    }),
  );

  router.get(
    '/events/:id/availability/heatmap',
    soloParticipante,
    asyncHandler(async (req: Request, res: Response) => {
      res.json(await c.availability.heatmap(String(req.params.id)));
    }),
  );

  // Item 5 — cuánta gente está libre en TODO un rango horario propuesto (no
  // en un bloque suelto), para que el organizador elija el fin con esa info.
  router.get(
    '/events/:id/availability/range',
    soloParticipante,
    asyncHandler(async (req: Request, res: Response) => {
      const { diaSemana, horaInicio, horaFin } = req.query;
      res.json(
        await c.availability.disponiblesEnRango(
          String(req.params.id),
          Number(diaSemana),
          Number(horaInicio),
          Number(horaFin),
        ),
      );
    }),
  );

  router.patch(
    '/events/:id/confirm',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      const { fechaHoraInicio, fechaHoraFin } = req.body ?? {};
      if (!fechaHoraInicio) throw new BadRequestError('fechaHoraInicio es requerido');
      if (!fechaHoraFin) throw new BadRequestError('fechaHoraFin es requerido');
      res.json(
        await c.availability.confirmarHorario(
          exigirUsuario(req),
          String(req.params.id),
          new Date(fechaHoraInicio),
          new Date(fechaHoraFin),
        ),
      );
    }),
  );

  // ── Grupos (SCRUM-8) y gestión de miembros (SCRUM-14, Duda #12.2) ───────
  router.get(
    '/groups/mine',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      res.json(await c.groups.listarDe(exigirUsuario(req)));
    }),
  );

  router.get(
    '/groups/overview',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      res.json(await c.groups.resumenPara(exigirUsuario(req)));
    }),
  );

  router.patch(
    '/groups/:id',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      res.json(
        await c.groups.actualizar(String(req.params.id), exigirUsuario(req), {
          nombre: req.body?.nombre,
          avatarUrl: req.body?.avatarUrl,
        }),
      );
    }),
  );

  router.post(
    '/groups/:id/members',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      const { usuarioId } = req.body ?? {};
      if (!usuarioId) throw new BadRequestError('usuarioId es requerido');
      await c.groups.agregarMiembro(String(req.params.id), exigirUsuario(req), usuarioId);
      res.status(204).send();
    }),
  );

  router.delete(
    '/groups/:id/members/me',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      await c.groups.abandonar(String(req.params.id), exigirUsuario(req));
      res.status(204).send();
    }),
  );

  // ── SCRUM-12 · Tareas del evento ────────────────────────────────────────
  router.get(
    '/events/:id/tasks',
    soloParticipante,
    asyncHandler(async (req: Request, res: Response) => {
      res.json(await c.tasks.listar(String(req.params.id)));
    }),
  );

  router.post(
    '/events/:id/tasks',
    soloParticipante,
    asyncHandler(async (req: ParticipantRequest, res: Response) => {
      res
        .status(201)
        .json(
          await c.tasks.crear(
            String(req.params.id),
            exigirParticipante(req),
            req.body?.titulo,
          ),
        );
    }),
  );

  router.patch(
    '/events/:id/tasks/:taskId/assign',
    soloParticipante,
    asyncHandler(async (req: ParticipantRequest, res: Response) => {
      const actor = exigirParticipante(req);
      // Sin `asignadoA`, el participante se está tomando la tarea (HU-21).
      const asignadoA = req.body?.asignadoA ?? actor;
      res.json(await c.tasks.asignar(String(req.params.taskId), actor, asignadoA));
    }),
  );

  router.patch(
    '/events/:id/tasks/:taskId/complete',
    soloParticipante,
    asyncHandler(async (req: ParticipantRequest, res: Response) => {
      res.json(await c.tasks.completar(String(req.params.taskId), exigirParticipante(req)));
    }),
  );

  router.patch(
    '/events/:id/tasks/:taskId/uncomplete',
    soloParticipante,
    asyncHandler(async (req: ParticipantRequest, res: Response) => {
      res.json(await c.tasks.descompletar(String(req.params.taskId), exigirParticipante(req)));
    }),
  );

  router.patch(
    '/events/:id/tasks/:taskId/unassign',
    soloParticipante,
    asyncHandler(async (req: ParticipantRequest, res: Response) => {
      res.json(await c.tasks.desasignar(String(req.params.taskId), exigirParticipante(req)));
    }),
  );

  router.delete(
    '/events/:id/tasks/:taskId',
    soloParticipante,
    asyncHandler(async (req: ParticipantRequest, res: Response) => {
      await c.tasks.eliminar(String(req.params.taskId), exigirParticipante(req));
      res.status(204).send();
    }),
  );

  // ── SCRUM-11 · Gastos, deudas y balances ────────────────────────────────
  router.get(
    '/events/:id/expenses',
    soloParticipante,
    asyncHandler(async (req: Request, res: Response) => {
      res.json(await c.expenses.listar(String(req.params.id)));
    }),
  );

  router.post(
    '/events/:id/expenses',
    soloParticipante,
    asyncHandler(async (req: ParticipantRequest, res: Response) => {
      res
        .status(201)
        .json(
          await c.expenses.crear(String(req.params.id), exigirParticipante(req), req.body ?? {}),
        );
    }),
  );

  router.patch(
    '/events/:id/expenses/close',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      await c.expenses.cerrar(String(req.params.id), exigirUsuario(req));
      res.status(204).send();
    }),
  );

  router.get(
    '/events/:id/debts',
    soloParticipante,
    asyncHandler(async (req: Request, res: Response) => {
      res.json(await c.debts.listarDelEvento(String(req.params.id)));
    }),
  );

  router.patch(
    '/events/:id/debts/:debtId/settle',
    soloParticipante,
    asyncHandler(async (req: ParticipantRequest, res: Response) => {
      res.json(await c.debts.saldar(String(req.params.debtId), exigirParticipante(req)));
    }),
  );

  router.get(
    '/me/balance',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      res.json(await c.debts.balanceDe(exigirUsuario(req)));
    }),
  );

  // FR9 — compensación cruzada: el desglose por evento de la relación con una
  // persona, y saldarla completa. Solo desde Balances; dentro de un evento se
  // opera sobre las deudas de ese evento ([Duda #26](docs/02-decisiones.md)).
  router.get(
    '/me/balance/:personaId',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      res.json(
        await c.debts.detalleConPersona(exigirUsuario(req), String(req.params.personaId)),
      );
    }),
  );

  router.post(
    '/me/balance/:personaId/settle',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      res.json(
        await c.debts.saldarConPersona(exigirUsuario(req), String(req.params.personaId)),
      );
    }),
  );

  // ── SCRUM-13 · Log de actividad del evento ──────────────────────────────
  router.get(
    '/events/:id/activity-log',
    soloParticipante,
    asyncHandler(async (req: ParticipantRequest, res: Response) => {
      const eventoId = String(req.params.id);
      const entradas = await c.activityLog.listar(eventoId);
      // Abrir el log marca el evento como leído (HU-25).
      if (req.participanteId) await c.activityLog.marcarLeido(req.participanteId);
      res.json(entradas);
    }),
  );

  router.get(
    '/me/unread',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      res.json(await c.activityLog.contarNoLeidasPorEvento(exigirUsuario(req)));
    }),
  );

  // Feed de "Actividad reciente" de la pantalla Home (mockup de Figma).
  router.get(
    '/me/activity',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      res.json(await c.activityLog.recientesDe(exigirUsuario(req)));
    }),
  );

  // ── SCRUM-15 · Notificaciones push (HU-35) ──────────────────────────────
  router.post(
    '/notifications/register-device',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      const { deviceToken } = req.body ?? {};
      if (!deviceToken) throw new BadRequestError('deviceToken es requerido');
      await c.notifications.registrarDevice(exigirUsuario(req), String(deviceToken));
      res.status(201).json({ ok: true });
    }),
  );

  // ── SCRUM-17 · IA: generar un borrador de evento desde texto (HU-42/43/44b) ─
  router.post(
    '/events/generate-from-text',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      const { descripcion } = req.body ?? {};
      if (!descripcion) throw new BadRequestError('descripcion es requerida');
      res.json(await c.aiEvents.generarDesdeTexto(exigirUsuario(req), String(descripcion)));
    }),
  );

  return router;
}
