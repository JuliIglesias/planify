# Planify

App mobile Android para coordinar juntadas grupales: disponibilidad, confirmación de asistencia y (desde el producto final) registro y división de gastos.

Proyecto académico — Dirección de Proyectos / Laboratorio 4, Universidad Austral.

## Documentación

Toda la documentación de producto, arquitectura y decisiones vive en [`docs/`](docs/):

- [`docs/00-entendimiento.md`](docs/00-entendimiento.md) — resumen del Project Charter
- [`docs/00-ui-entendimiento.md`](docs/00-ui-entendimiento.md) — análisis de la referencia de UI
- [`docs/01-plan-de-ejecucion.md`](docs/01-plan-de-ejecucion.md) — arquitectura, modelo de datos, backlog y plan por épicas (alineado a Jira)
- [`docs/02-decisiones.md`](docs/02-decisiones.md) — bitácora de decisiones
- [`docs/03-design-system.md`](docs/03-design-system.md) — mini design system

Backlog y fechas: [Jira — proyecto SCRUM](https://planify2026.atlassian.net).

## Estructura del repo

```
mobile/    App Flutter (Android)
backend/   API Node + Express + Prisma
infra/     Docker compose, scripts y docs de despliegue en AWS
docs/      Documentación de producto y arquitectura
```

## Estado actual

| Épica Jira | Estado |
|---|---|
| SCRUM-6 Setup infraestructura | Código listo; falta provisionar AWS |
| SCRUM-7 Acceso anónimo | Backend + Login funcional |
| SCRUM-8 Creación de eventos | Backend + wizard de 2 pasos |
| SCRUM-9 Disponibilidad | Backend + grilla y heatmap |
| SCRUM-10 Confirmación asistencia | Backend + UI |
| SCRUM-11 Gastos y deudas | Motor con 17 tests, alta de gasto, saldar y cerrar |
| SCRUM-12 Tareas | Backend + UI (incluye asignar a terceros) |
| SCRUM-13 Log de actividad | Backend + UI, 12 tipos de actividad |
| SCRUM-16 Historial | Backend + UI |
| SCRUM-14 Gestión de grupos | Renombrar, agregar miembro y abandonar |
| SCRUM-14 Auth completa (Cognito) | Pendiente |
| SCRUM-15 Notificaciones | Pendiente (endpoint 501) |
| SCRUM-17 IA (Gemini) | Pendiente (endpoint 501) |

**Verificación:** 58 tests de backend + 24 de mobile, todos en verde, sin necesidad de base de datos.

Nada se ejecutó todavía contra una base de datos real — ver [`infra/README.md`](infra/README.md).

## Arquitectura

Está desacoplada siguiendo SOLID: los servicios dependen de interfaces, no de Prisma ni de Dio. La tabla **"dónde tocar según qué cambie"** está en [`docs/01-plan-de-ejecucion.md`](docs/01-plan-de-ejecucion.md#4-estructura-de-carpetas), y la receta para agregar funcionalidad nueva en [`docs/04-notas-de-implementacion.md`](docs/04-notas-de-implementacion.md).

> 📌 **Antes de arrancar, leé [`docs/04-notas-de-implementacion.md`](docs/04-notas-de-implementacion.md).** Documenta las trampas concretas ya encontradas (versiones que rompen, gotchas de Flutter/Express/Prisma) para no perder horas repitiéndolas.

## Setup rápido

### Backend
```bash
cd backend
npm install
cp .env.example .env   # completar DATABASE_URL
npx prisma migrate dev
npm run dev
```

### Mobile
```bash
cd mobile
flutter pub get
flutter run
```

Ver [`infra/README.md`](infra/README.md) para levantar Postgres local con Docker y para el provisioning de AWS (EC2 + RDS + Cognito).
