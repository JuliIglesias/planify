import { Router } from 'express';
import { notImplemented } from '../../common/notImplemented';

// SCRUM-17 (29/10-11/11) — OBLIGATORIA (no backlog opcional, ver docs/02-decisiones.md
// Duda #20/#22), aunque es la primera en caerse si hay atraso general del proyecto.
// HU-42/HU-43/HU-44b: el organizador describe el evento en lenguaje natural y Gemini API
// (gratis vía facultad, Duda #21) genera evento + grupo/participantes + tareas sugeridas,
// siempre como borrador editable antes de confirmar (nunca auto-creación ciega).
// TODO: cliente Gemini API + diseño de prompt con salida JSON estructurada + fallback
// manual a HU-06 si el modelo no logra extraer datos suficientes.
export const aiEventsRouter = Router();

aiEventsRouter.post('/events/generate-from-text', notImplemented('SCRUM-17', 'HU-42/43/44b generación por IA (Gemini)'));
