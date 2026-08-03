# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Planify — Android app (Flutter) for coordinating group meetups: availability, attendance confirmation, expense splitting. Academic project (Universidad Austral, Dirección de Proyectos / Laboratorio 4). Backlog lives in Jira (`planify2026.atlassian.net`, project `SCRUM`), which — together with the Project Charter PDF — is the source of truth over any doc in this repo.

Monorepo: `backend/` (Node + Express + Prisma API), `mobile/` (Flutter app), `infra/` (Docker + AWS deploy), `docs/` (product/architecture docs).

## Commands

### Backend (`cd backend`)
```bash
npm run dev              # ts-node-dev, hot reload
npm run build             # tsc type-check + compile
npm run lint               # eslint src/**/*.ts
npm test                    # jest (all suites, no DB needed — uses in-memory fakes)
npm test -- test/debt-engine.test.ts   # single test file
npm run test:watch
npx prisma migrate dev     # apply migrations (needs DATABASE_URL, see infra/README.md)
npm run seed                # seed the organizer user
```

### Mobile (`cd mobile`)
```bash
flutter pub get
flutter analyze
flutter test                                    # all tests, no network needed — uses fakes
flutter test test/login_screen_test.dart        # single test file
flutter run
flutter gen-l10n                                # regenerate after editing .arb files
```

### Infra
```bash
docker compose -f infra/docker-compose.yml up --build   # local Postgres + backend
```

CI (GitHub Actions, `.github/workflows/`) runs `lint` → `build` → `test` per PR, scoped by path (`backend-ci.yml` / `mobile-ci.yml`). Deploy to EC2 is manual-only (`workflow_dispatch`), never automatic.

## Architecture

Backend is layered with dependency inversion (SOLID) so a change lands in exactly one place:

```
routes.ts → modules/<area>/*.service.ts → domain/repositories/ (interfaces) ⇠impl⇢ infrastructure/prisma/
```

- `src/domain/` — pure types (`entities.ts`) and repository **interfaces**. Depends on nothing.
- `src/infrastructure/` — the only layer that knows Prisma (`prisma/`) or other externals (`servicios-externos.ts`: bcrypt, JWT, clock, uuid).
- `src/modules/<area>/` — business logic, one service per area (`auth`, `participants`, `invitations`, `events` — commands vs. `events.queries.ts` split — `availability`, `groups`, `tasks`, `expenses`, `debts` incl. `debt-engine.ts`, `activity-log`).
- `src/container.ts` — **composition root**: the only file that wires which concrete implementation (Prisma repo, Cognito, etc.) each service uses. Swapping ORM/auth provider means touching this file plus `infrastructure/`, never a service.
- `src/routes.ts` — all routes, grouped by Jira epic; every async handler must be wrapped in `asyncHandler` (`middlewares/`) or thrown errors don't reach the error middleware.

Mobile mirrors this: `lib/core/` (theme tokens, domain models, Dio client, `TokenStorage` interface, shared widgets) and `lib/features/<feature>/data/` (one repository interface + Dio implementation per feature — not a single monolithic API class). Expenses/tasks/activity-log have no top-level feature folder; they live inside `features/events/` because they're always used in an event's context. Screens depend on repository interfaces, never on `Dio`/`DioException` directly (`core/data/api_exception.dart` translates network errors).

**"What to touch when X changes"** (see [`docs/01-plan-de-ejecucion.md`](docs/01-plan-de-ejecucion.md#4-estructura-de-carpetas) for the full table):
| Change | Touch |
|---|---|
| A business rule | `backend/src/modules/<area>/*.service.ts` |
| How data is persisted | `backend/src/infrastructure/prisma/` |
| Auth/hash/token provider | `backend/src/infrastructure/servicios-externos.ts` + `container.ts` |
| An endpoint | `backend/src/routes.ts` |
| A color/spacing/typography token | `mobile/lib/core/theme/` |
| Visible text | both `.arb` files in `mobile/lib/l10n/` |
| How the API is called | `mobile/lib/features/<feature>/data/` |

## Conventions

- Domain concepts are named in **Spanish** end-to-end (entities, DB fields, service/repository names — `Usuario`, `Evento`, `Gasto`, `Deuda`, `Participante`) even though code/comments/identifiers otherwise follow normal TS/Dart style. Don't anglicize domain names.
- File naming: kebab-case with role suffixes — `*.service.ts`, `*.repository.ts` (interface), `*.prisma.repository.ts` (impl), `*.queries.ts`.
- Money is **never** a float. Backend entities carry amounts as decimal strings (`"1234.56"`); the debt engine (`debt-engine.ts`) converts to integer cents via `toCents` (string-based, never `* 100`) and remainder-splits with `splitEvenlyCents`. Any new money-handling code must follow the same pattern (NFR#4 — financial accuracy).
- Every platform-touching mobile dependency (secure storage, GPS, notifications) must sit behind an app-owned interface (see `TokenStorage`) — otherwise it can't be faked in widget tests.
- Backend and mobile tests never hit a real DB/network: they run against hand-written in-memory fakes (`backend/test/fakes.ts`, `mobile/test/helpers/fake_repositories.dart`) that implement the same interfaces as the real implementations. Adding a repository method means updating the interface, the real impl, **and** the fake.
- New text must go in both `.arb` files (`es`, `en`) — no hardcoded UI strings.

Full "how to add a new feature" recipe: [`docs/04-notas-de-implementacion.md §5.7`](docs/04-notas-de-implementacion.md). That doc also logs concrete version/tooling traps already hit (Prisma pinned to 6.19.3 — don't let `npm update` touch it; ESLint flat config; Riverpod 3 API changes; widget-test gotchas with `flutter_secure_storage` and lazy `ListView`) — check it before fighting a problem that's already been solved.

## Branches / PRs / Definition of Done

- Work merges to `main` via Pull Request with at least one approval.
- CI (lint + build + test) must be green before merge.
- Manually verified against the demo environment — "works on my machine" isn't sufficient.
- If a story touches visible text, it must be in the `.arb` files, not hardcoded.
- Relevant docs (module README, architecture note) updated alongside the change.
- Deploy to EC2 is manual (`workflow_dispatch`) — never wire it to auto-trigger on push.

## Further reading

- [`docs/00-entendimiento.md`](docs/00-entendimiento.md) — Project Charter summary (requirements, scope)
- [`docs/00-ui-entendimiento.md`](docs/00-ui-entendimiento.md) — UI reference analysis
- [`docs/01-plan-de-ejecucion.md`](docs/01-plan-de-ejecucion.md) — architecture, data model, full backlog by Jira epic, DoR/DoD
- [`docs/02-decisiones.md`](docs/02-decisiones.md) — decision log (read before assuming an open question is actually open)
- [`docs/03-design-system.md`](docs/03-design-system.md) — mini design system (mobile)
- [`docs/04-notas-de-implementacion.md`](docs/04-notas-de-implementacion.md) — known traps/gotchas, recipe for adding a feature
- [`infra/README.md`](infra/README.md) — local Docker + AWS provisioning
