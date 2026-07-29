# Planify — Notas de implementación (trampas y pasos difíciles)

> Bitácora de los problemas concretos que aparecieron al construir el proyecto.
> El objetivo es que el equipo de desarrollo no pierda horas tropezando con lo mismo.
> Cada entrada dice: **qué pasó**, **por qué**, **cómo se resolvió**.

---

## 1. Versiones y herramientas

### 1.1 Prisma 7 rompe `datasource url` en el schema
**Qué pasó:** `npx prisma generate` falló con `P1012: The datasource property 'url' is no longer supported in schema files`.

**Por qué:** Prisma 7 movió la URL de conexión a `prisma.config.ts` y exige pasar un `adapter` al cliente. Es un cambio grande respecto de todos los tutoriales que hay dando vueltas.

**Cómo se resolvió:** se fijó Prisma en **6.19.3** (`--save-exact`), que usa el `datasource { url = env("DATABASE_URL") }` de toda la vida.

> ⚠️ **No corran `npm update` sobre Prisma sin querer.** Si aparece este error, revisen que `package.json` siga en `6.19.3`.

### 1.2 ESLint 9+ ignora `.eslintrc.json`
**Qué pasó:** `npx eslint` respondía `ESLint couldn't find an eslint.config.(js|mjs|cjs) file`, aunque el `.eslintrc.json` estaba ahí.

**Por qué:** desde ESLint 9 el formato por defecto es *flat config*.

**Cómo se resolvió:** se borró el `.eslintrc.json` y se creó `backend/eslint.config.js` con `typescript-eslint`.

### 1.3 TypeScript 6 marca `moduleResolution: node` como deprecado
**Qué pasó:** `tsc --noEmit` fallaba con `TS5107: Option 'moduleResolution=node10' is deprecated`.

**Cómo se resolvió:** se agregó `"ignoreDeprecations": "6.0"` en `tsconfig.json`. Es una solución temporal; en algún momento habrá que migrar a `"moduleResolution": "bundler"` o `"node16"`.

### 1.4 Jest no encuentra los tipos de `describe` / `it`
**Qué pasó:** los tests fallaban con `TS2593: Cannot find name 'describe'`, aunque `@types/jest` estaba instalado.

**Por qué:** el `tsconfig.json` principal excluye la carpeta `test/`, así que ts-jest compilaba sin esos tipos.

**Cómo se resolvió:** un `tsconfig.jest.json` aparte que incluye `test/**` y declara `"types": ["jest", "node"]`, referenciado desde `jest.config.js`.

---

## 2. Flutter y sus dependencias

### 2.1 El paquete sintético `flutter_gen` ya no existe
**Qué pasó:** `import 'package:flutter_gen/gen_l10n/app_localizations.dart'` no resolvía.

**Por qué:** Flutter eliminó el paquete sintético para las localizaciones. Casi todos los tutoriales de i18n siguen usándolo.

**Cómo se resolvió:** en `l10n.yaml` se define `output-dir: lib/l10n/generated` y se importa con ruta relativa:
```dart
import '../../l10n/generated/app_localizations.dart';
```
La opción `synthetic-package: false` también quedó deprecada — no hace falta ponerla.

### 2.2 Conflicto de versión con `intl`
**Qué pasó:** `flutter pub add flutter_localizations` fallaba: *"every version of flutter_localizations depends on intl 0.20.2 and planify depends on intl ^0.20.3"*.

**Por qué:** `flutter_localizations` fija `intl` a una versión exacta según el SDK de Flutter instalado.

**Cómo se resolvió:** fijar `intl: 0.20.2` (sin `^`) en `pubspec.yaml`, **antes** de agregar `flutter_localizations`.

### 2.3 Riverpod 3 sacó `StateProvider` y `valueOrNull`
**Qué pasó:** `The function 'StateProvider' isn't defined` y `The getter 'valueOrNull' isn't defined for AsyncValue`.

**Por qué:** Riverpod 3 limpió su API. Casi toda la documentación en internet es de Riverpod 2.

**Cómo se resolvió:**
- `StateProvider<T>` → `NotifierProvider<MiNotifier, T>` con una clase `Notifier<T>` que expone métodos con nombre (más explícito que `state = x` desde afuera).
- `asyncValue.valueOrNull` → `asyncValue.value` (ya es nullable).

### 2.4 `flutter_secure_storage` v10 cambió las firmas
**Qué pasó:** al intentar hacer un fake para tests: *"The parameter 'iOptions' has type 'IOSOptions?', which does not match 'AppleOptions?'"*.

**Por qué:** la v10 unificó `IOSOptions` y `MacOsOptions` en `AppleOptions`. Implementar la interfaz del paquete ata el código a su versión.

**Cómo se resolvió — y es la lección importante:** se creó una abstracción propia en `lib/core/network/token_storage.dart`:
```dart
abstract interface class TokenStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}
```
La app depende de esa interfaz; `SecureTokenStorage` la implementa usando el paquete. Ventajas: los tests usan un fake de 3 líneas, y si el paquete vuelve a cambiar su API, se toca **un solo archivo**.

### 2.5 Los widget tests se colgaban con `pumpAndSettle timed out`
**Qué pasó:** el test de la pantalla de Login se colgaba y después fallaba con *"Found 0 widgets with text 'Ingresar'"*.

**Por qué:** dos problemas encadenados:
1. `flutter_secure_storage` usa canales de plataforma que **no existen** en un widget test, así que el `Future` nunca resolvía.
2. Como la sesión quedaba en estado `loading`, el botón mostraba un spinner en vez del texto — por eso "no encontraba" el texto.

**Cómo se resolvió:** inyectar un `FakeTokenStorage` con `ProviderScope(overrides: [...])`. Además, se monta `LoginScreen` directamente en vez de `PlanifyApp`, porque el router raíz también lee el storage.

> 💡 **Regla general:** todo lo que toque plataforma (storage, GPS, cámara, notificaciones) tiene que estar detrás de una interfaz propia, o los tests son imposibles.

### 2.6 Mapas `const` con claves de clase propia
**Qué pasó:** `const_map_key_not_primitive_equality` al armar `const {AvailabilitySlot(0, 10): 3}`.

**Por qué:** Dart no permite claves `const` en clases que sobrescriben `==` / `hashCode`.

**Cómo se resolvió:** sacar el `const` del mapa y dejarlo solo en las claves: `{const AvailabilitySlot(0, 10): 3}`.

### 2.7 En los widget tests, lo que está debajo del pliegue NO existe
**Qué pasó:** varios tests de la pantalla de evento fallaban con *"Found 0 widgets with text 'Comprar carne'"*, aunque el widget claramente estaba en el código.

**Por qué:** la ventana de prueba mide **800x600** por defecto, y `ListView` construye de forma perezosa. Todo lo que queda más abajo simplemente no se construye, así que `find.text` no lo encuentra.

**Cómo se resolvió:** el helper `usarPantallaAlta(tester)` en `test/helpers/test_app.dart`, que agranda la ventana antes de montar la pantalla:
```dart
tester.view.physicalSize = const Size(1000, 3000);
tester.view.devicePixelRatio = 1.0;
```
(La alternativa es hacer `tester.scrollUntilVisible`, más fiel pero mucho más verboso.)

### 2.8 `find.byType(GestureDetector).first` casi nunca es lo que uno cree
**Qué pasó:** un test tocaba la primera celda de la grilla de disponibilidad y el resultado era `guardar:0` — es decir, no se había seleccionado nada.

**Por qué:** había otros `GestureDetector` antes en el árbol (dentro de cards, botones, etc.), así que `.first` tocaba cualquier otra cosa.

**Cómo se resolvió:** acotar la búsqueda al widget correcto:
```dart
find.descendant(
  of: find.byType(WeeklyAvailabilityGrid).first,
  matching: find.byType(GestureDetector),
).first
```

> 💡 Ante un test que "no hace nada", sospechar del finder antes que del código.

### 2.9 `DateFormat` con locale español necesita inicialización
**Qué pasó:** formatear fechas en español tira `LocaleDataException` si no se inicializa.

**Cómo se resolvió:** en `main()`, antes de `runApp`:
```dart
await initializeDateFormatting('es');
```

---

## 3. Express y TypeScript

### 3.1 Los errores en handlers `async` no llegan al middleware de error
**Qué pasó:** cuando un `await` fallaba dentro de una ruta, la request quedaba colgada y aparecía un *unhandled rejection*.

**Por qué:** Express no captura promesas rechazadas automáticamente.

**Cómo se resolvió:** el wrapper `asyncHandler` en `src/middlewares/asyncHandler.ts`. **Toda ruta async tiene que ir envuelta**:
```ts
router.get('/algo', asyncHandler(async (req, res) => { ... }));
```

### 3.2 `req.params` tipa como `string | string[]`
**Qué pasó:** `Argument of type 'string | string[]' is not assignable to parameter of type 'string'`.

**Cómo se resolvió:** envolver siempre con `String(req.params.id)`.

### 3.3 El orden de las rutas importa
**Qué pasó:** `GET /events/upcoming` respondía "Evento no encontrado".

**Por qué:** `GET /events/:id` estaba declarada antes y capturaba `upcoming` como si fuera un id.

**Cómo se resolvió:** declarar siempre las rutas literales **antes** que las que tienen parámetros.

---

## 4. Modelo de datos y reglas de negocio

### 4.1 Referencia circular entre Evento y Participante
**Qué pasó:** un `Evento` necesita `creadoPor` (el participante organizador), pero un `Participante` necesita `eventoId`. No se puede crear ninguno primero.

**Cómo se resolvió:** una transacción en `PrismaEventoRepository.createWithOrganizer`: crea el evento con `creadoPor` vacío, crea el participante, y actualiza el evento. Todo atómico, porque un evento sin organizador sería un estado inválido (nadie podría cancelarlo).

### 4.2 La plata NUNCA se calcula con `double`
**Qué pasó (o mejor dicho, qué se evitó):** `0.1 + 0.2 !== 0.3` en punto flotante, y `19.99 * 100 === 1998.9999999999998`.

**Por qué importa:** el NFR#4 del charter exige exactitud financiera. Con floats, los errores se acumulan en eventos con muchos gastos y las deudas terminan mal.

**Cómo se resolvió:** todo el motor de deudas trabaja en **centavos enteros**. La conversión (`toCents`) pasa por string para no tocar floats nunca:
```ts
toCents('19.99') === 1999   // sin multiplicar por 100
```

### 4.3 Repartir un monto sin perder centavos
**Qué pasó:** dividir $100 entre 3 da $33.33 cada uno = $99.99. Falta un centavo.

**Cómo se resolvió:** `splitEvenlyCents` reparte el resto de a un centavo entre los primeros participantes: `[3334, 3333, 3333]`. Hay un test que verifica que la suma cierre exacta para **todas** las combinaciones de 0 a 200 centavos entre 1 y 7 personas.

### 4.4 Un pago no se debe "revivir" al agregar otro gasto
**Qué pasó:** al recalcular las deudas después de un gasto nuevo, las deudas ya saldadas volvían a aparecer como pendientes.

**Por qué:** el recálculo borra y regenera todas las deudas del evento.

**Cómo se resolvió:** antes de reemplazar, se guarda qué pares deudor→acreedor estaban saldados. Si la deuda regenerada es idéntica (mismo par, mismo monto), conserva el estado `saldado`.

### 4.5 Consultas N+1 en la pantalla Groups
**Qué pasó:** la primera versión de `resumenPara` hacía una consulta de eventos, tareas y gastos **por cada grupo**, dentro de un `map`.

**Cómo se resolvió:** juntar los ids primero y hacer una sola consulta agregada para todos (`contarPendientesPorEvento(ids)`). Con 10 grupos pasa de ~31 consultas a 4.

> 💡 Ojo con hacer `await` adentro de un `.map()` — casi siempre es un N+1 escondido.

---

## 5. Arquitectura (por qué está desacoplado así)

### 5.1 Los servicios no conocen Prisma
Cada servicio recibe **interfaces** (`EventoRepository`, `PasswordHasher`…) por constructor, definidas en `src/domain/repositories/`. Las implementaciones concretas viven en `src/infrastructure/`.

**Para qué sirve en la práctica:**
- Los tests corren **sin base de datos**, usando los fakes de `test/fakes.ts`.
- Migrar el login a Cognito (SCRUM-14) es escribir un `CognitoTokenService` y cambiar **una línea** en `container.ts`.
- Cambiar de ORM no toca ni un servicio.

### 5.2 `container.ts` es el único lugar donde se decide qué implementación se usa
Si hay que reemplazar algo, se busca ahí. No hay `new` de infraestructura desperdigado por el código.

### 5.3 Comandos y consultas separados
`EventsService` (crear, cancelar, confirmar asistencia) está separado de `EventsQueryService` (armar las vistas de Home e Historial). Mezclarlos hace que la clase crezca sin control.

### 5.4 El log de actividad se escribe desde un solo servicio
Ningún servicio escribe en `LogActividadRepository` directamente: todos pasan por `ActivityLogService.registrar()`. Cuando haya que disparar además una notificación push (SCRUM-15), se agrega **en un solo lugar**.

### 5.5 En mobile, un repositorio por feature (no un "PlanifyApi" gigante)
La primera versión tenía una sola clase `PlanifyApi` con todos los endpoints. Se dividió en `AuthRepository`, `EventsRepository`, `TasksRepository`, `ExpensesRepository`, `BalancesRepository`, `ActivityLogRepository`, `AvailabilityRepository` y `GroupsRepository`, cada uno con su interfaz y su implementación con Dio.

**Para qué sirve:** cada pantalla declara exactamente de qué depende, y los tests reemplazan solo eso. Con la clase gigante había que falsear 20 métodos para probar una pantalla que usaba dos.

### 5.6 Las pantallas nunca ven un `DioException`
`core/data/api_exception.dart` traduce los errores de red a una `ApiException` propia. Ventajas: no se le muestran al usuario mensajes tipo "connection refused", y cambiar de cliente HTTP no toca la UI.

### 5.7 Cómo agregar una funcionalidad nueva (receta)
1. **Dominio:** si hace falta, agregar el método a la interfaz del repositorio en `backend/src/domain/repositories/`.
2. **Infraestructura:** implementarlo en `backend/src/infrastructure/prisma/`.
3. **Servicio:** poner la regla de negocio en `backend/src/modules/<modulo>/*.service.ts`.
4. **Ruta:** agregar el endpoint en `backend/src/routes.ts` (siempre con `asyncHandler`).
5. **Test de backend:** usar los fakes de `test/fakes.ts` — no hace falta base de datos.
6. **Mobile:** agregar el método al repositorio de la feature, crear/usar un provider, y consumirlo desde la pantalla.
7. **Test de mobile:** agregar el método al fake correspondiente en `test/helpers/fake_repositories.dart`.
8. **Textos:** agregarlos a **los dos** `.arb` (es y en) y correr `flutter gen-l10n`.

---

## 6. Pendientes conocidos

| Tema | Estado |
|---|---|
| Nada se probó todavía contra una base de datos real | Falta Docker + `prisma migrate dev` |
| AWS sin provisionar | Ver `infra/README.md` |
| `moduleResolution: node10` deprecado | Funciona con `ignoreDeprecations`, migrar antes de TS 7 |
| Alta de gasto asume un solo pagador | Falta selector de múltiples acreedores (FR7 completo) |
| SCRUM-15 (notificaciones) y SCRUM-17 (IA) | Endpoints devuelven 501 |
