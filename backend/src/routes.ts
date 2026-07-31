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
      const { email, password } = req.body ?? {};
      if (!email || !password) throw new BadRequestError('email y password son requeridos');
      res.json(await c.auth.login(email, password));
    }),
  );

  router.post(
    '/participants/anonymous',
    asyncHandler(async (req: Request, res: Response) => {
      const { eventoId, nombreDisplay } = req.body ?? {};
      if (!eventoId) throw new BadRequestError('eventoId es requerido');
      res.status(201).json(await c.participants.unirseComoAnonimo(eventoId, nombreDisplay));
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
    asyncHandler(async (req: Request, res: Response) => {
      res.json(await c.eventsQuery.detalle(String(req.params.id)));
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


  router.patch(
    '/events/:id/confirm',
    soloOrganizador,
    asyncHandler(async (req: OrganizerRequest, res: Response) => {
      const { fechaHoraInicio } = req.body ?? {};
      if (!fechaHoraInicio) throw new BadRequestError('fechaHoraInicio es requerido');
      res.json(
        await c.availability.confirmarHorario(
          exigirUsuario(req),
          String(req.params.id),
          new Date(fechaHoraInicio),
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
        await c.groups.renombrar(String(req.params.id), exigirUsuario(req), req.body?.nombre),
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

  // ── SCRUM-15 y SCRUM-17 · comprometidos en Jira, todavía sin implementar ─
  const noImplementado = (epica: string, detalle: string) => (_req: Request, res: Response) =>
    res.status(501).json({ error: 'Not implemented yet', epica, detalle });

  router.post(
    '/notifications/register-device',
    noImplementado('SCRUM-15', 'HU-35 registrar device para push (SNS/Pinpoint)'),
  );

  router.post(
    '/events/generate-from-text',
    noImplementado('SCRUM-17', 'HU-42/43/44b generación de evento por IA (Gemini)'),
  );

  return router;
}
