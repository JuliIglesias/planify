# Planify — Entendimiento del Project Charter

> Fuente: `entrega 2 PC (1).pdf` (31 páginas). Este documento es un resumen estructurado, no reemplaza al charter original.

## 1. Objetivo

Desarrollar y desplegar una aplicación **mobile Android** que permita la creación y gestión de **eventos grupales**, priorizando:
1. Coordinación de disponibilidad
2. Confirmación de asistencia

E incorporando, **en iteraciones posteriores al MVP**:
3. Registro y división de gastos

## 2. Visión del producto

> "Para grupos de personas que buscan organizar juntadas sin perder tiempo en chats interminables, Planify es una aplicación mobile que permite coordinar horarios, confirmar asistencia y el control de gastos en un solo lugar."

Posicionamiento: alternativa integrada a usar **When2Meet + Splitwise** por separado.

**Problema actual:** coordinación fragmentada (mensajes dispersos, encuestas improvisadas, cálculos manuales de gastos, confirmación por múltiples canales, falta de trazabilidad).

**Solución propuesta:** espacio único con disponibilidad visible, confirmación sin idas y vueltas, gastos automáticos, información centralizada.

## 3. Métricas de éxito

| Métrica | Objetivo |
|---|---|
| Eventos concretados con horario y lugar confirmados | ≥ 70% |
| Eventos que finalizan con cuentas saldadas | ≥ 60% |
| Tiempo promedio para definir horario del evento | < 10 min |
| Invitados que cargan su disponibilidad | ≥ 60% |
| Usuarios activos y recurrencia | Crecimiento sostenido (sin cifra objetivo) |

## 4. Stakeholders

1. **Usuarios finales**: amigos, grupos, organizadores de juntadas
2. **Equipo del proyecto**: dirección de proyecto, testers/QA, desarrolladores
3. Cátedra de Dirección de Proyectos y Laboratorio 4
4. Cátedra de Laboratorio 2
5. La facultad
6. Plataforma de distribución: Play Store

## 5. Requerimientos funcionales (de mayor a menor prioridad)

| # | Requerimiento | Notas |
|---|---|---|
| 1 | Creación de cuenta anónima | Máxima prioridad — sugiere que el MVP no depende de registro tradicional |
| 2 | Creación de eventos | |
| 3 | Configuración de disponibilidad semanal | |
| 4 | Confirmación de asistencia | |
| 5 | Creación de grupos | |
| 6 | Invitación a evento | |
| 7 | Registro de gastos por evento | Soporta **múltiples acreedores** y **múltiples deudores** |
| 8 | Registro de tareas | |
| 9 | Cálculo de deudas entre eventos | Implica agregación de saldos cross-evento |
| 10 | Espacio de chat por grupo | Ver tensión con "fuera de alcance" (sección 8) |
| 11 | Registro de cuenta | Cuenta "completa" (no anónima) |
| 12 | Gestión de identidad en la plataforma | |
| 13 | Gestión de amigos | |
| 14 | Notificaciones de actividad | Ver NFR#8 (SLA 60s) |
| 15 | Coincidencias de disponibilidad entre usuarios amigos | |
| 16 | Almacenamiento de ubicaciones usuales | |
| 17 | Historial de reuniones pasadas | |
| 18 | IA para auto-generación de eventos | Menor prioridad — no confundir con los "Agentes IA" de desarrollo (sección 12) |

## 6. Requerimientos no funcionales (de mayor a menor prioridad)

| # | Requerimiento |
|---|---|
| 1 | Lanzamiento en Play Store |
| 2 | Restricción de funcionalidades dependiendo del **tipo de usuario** |
| 3 | Creación de evento en **2 pasos** |
| 4 | El cálculo de deudas debe garantizar exactitud financiera en todas las transacciones |
| 5 | La UI debe ser compatible con las guidelines de **Android y iOS** |
| 6 | Compatibilidad con múltiples idiomas |
| 7 | Cifrado en tránsito y en reposo de información sensible (disponibilidad semanal, historial de gastos, mensajes de chat) |
| 8 | Notificaciones de actividad entregadas al 99% de usuarios en < 60 segundos |
| 9 | Soportar hasta 2.000 usuarios activos concurrentes/día sin degradación |

## 7. Requerimientos del proyecto (de mayor a menor prioridad)

1. MVP al inicio de la 2da semana del 2do sprint
2. Desarrolladores con conocimientos intermedios de programación
3. Capacitar al equipo en el stack tecnológico
4. Definición clara de la arquitectura a utilizar
5. Desarrollar el flujo central sin desbordar el alcance
6. Trabajar dentro de los costos del presupuesto
7. Probar cada funcionalidad de forma incremental
8. Publicar una versión funcional y documentada
9. Asegurar trazabilidad de tareas, tiempos y entregables
10. Mantener el proyecto dentro del plazo académico de 4 meses
11. Metodología **híbrida**: sprints + entrega de valor + planificación predictiva de fases

## 8. Alcance / Fuera de alcance / Supuestos

**Alcance (alto nivel):**
1. Diseño y definición del producto y su solución
2. Diseño UX/UI
3. Definición de arquitectura técnica
4. Desarrollo de app mobile Android
5. Coordinación y gestión de eventos
6. Desarrollo iterativo (incl. gastos)
7. Testing y validación iterativa
8. Capacitación del equipo
9. Despliegue de versiones funcionales, incl. MVP inicial

**Fuera de alcance (explícito):**
- Versión iOS o web
- Pasarelas de pago / transacciones reales de dinero
- Mensajería avanzada en tiempo real
- Red social abierta / gestión de usuarios a gran escala
- Sistema de recomendación
- Escalabilidad masiva más allá del alcance académico

**Supuestos declarados:**
- Desarrollo entre **agosto y mediados de noviembre**, equipo de 3-4 devs + dirección/QA
- Usuarios con Android, internet y disposición a usar app móvil
- Equipo con equipamiento propio (dev + testing)
- Herramientas accesibles de bajo costo
- Distribución vía Play Store sin restricciones externas significativas

## 9. Entregables

**Producto:** MVP funcional Android desplegado · coordinación de disponibilidad y gestión de eventos · confirmación de asistencia · iteración con gastos.

**Proyecto:** Project Charter · Planificación (alcance/cronograma/costos) · Diseño UX/UI (wireframes y prototipos) · Arquitectura de la solución y modelo de datos · Repositorio documentado · Informe final.

## 10. WBS (resumen)

1. **Gestión del proyecto**: planificación inicial, seguimiento y control, cierre
2. **Análisis y Diseño**: requerimientos, UX/UI, arquitectura, modelo de datos
3. **Capacitación y Setup**: stack mobile, entorno dev, repo (Git + CI/CD)
4. **Desarrollo MVP**: acceso anónimo, creación de evento, disponibilidad, confirmación asistencia, módulo de gastos, tareas, chat de grupo, autenticación/usuarios, notificaciones, historial, IA de auto-generación
5. **Testing**: funcional, integración, corrección de bugs
6. **Despliegue**: preparación release, publicación Play Store
7. **Cierre**: documentación final, entrega final

## 11. Hitos

| Fecha | Hito |
|---|---|
| 15/06 | Aprobación de Project Charter |
| 13/08 | Desarrolladores capacitados |
| 21/08 | Setup de infraestructura completo (repos + workflows) |
| 09/09 | Finalización MVP |
| 16/09 | Despliegue MVP |
| 12/11 | Finalización de proyecto |

**Cronograma:** 3 sprints. Camino crítico (marcado en azul en el Gantt): Capacitación → Setup Infraestructura → Creación de eventos → Gestión de disponibilidad → Deploy Android → Módulo de gastos → Autenticación/usuarios → Despliegue Android 3 → Historial → Despliegue Android Final.

## 12. Recursos y equipo

**Roles del proyecto (no son roles/tipos de usuario de la app):**
- Equipo Central (Dirección de proyecto): PM, PO, Agent Engineer (AE), UX/UI Designer, QA
- Equipo de Desarrollo (Laboratorio 4): Backend Dev, Frontend Dev

**Hardware:** notebooks/computadoras (desarrollo) + celulares físicos con Android (testing)

**Adquisiciones:** APIs externas (horarios/notificaciones), servicios de IA en backend/código, cuenta de desarrollador Google Play Store, IDEs, herramientas de prototipado

**Agentes IA de desarrollo** (proceso interno del equipo, no features de producto):
1. UI/UX — consistencia estética y modularización de componentes
2. Backend — lógica de servidor, persistencia, seguridad de APIs
3. QA — tests, coverage, verificación de criterios de aceptación
4. CI/CD — infraestructura de despliegue, empaquetado automatizado
5. Contexto — fuente de conocimiento del proyecto

## 13. Presupuesto

| Tipo | Concepto | Cantidad | P.U. (USD) | Total (USD) |
|---|---|---|---|---|
| CAPEX | Equipo de Dirección (PM/UX/QA/PO combinados) | 4×144 hs | 10 | 5.760 |
| CAPEX | Desarrollo Mobile (4 devs) | 4×144 hs | 8 | 4.608 |
| CAPEX | Capacitación **Flutter** (Udemy, 4 devs) | 4 cursos | 30 | 120 |
| CAPEX | Fondo de contingencia (15%) | - | - | 1.592 |
| OPEX | Hosting (estimado) | 6 meses | 12/mes | 72 |
| OPEX | Publicación Play Store (pago único) | 1 | 25 | 25 |
| OPEX | IA / APIs básicas | - | - | 30 |
| **TOTAL** | | | | **12.207** |

> ⚠️ El ítem "Capacitación Flutter" es la única mención explícita de stack tecnológico en todo el charter — ver duda #1 en la lista de preguntas.

## 14. Riesgos negativos

| # | Riesgo | Prob. | Imp. | Exposición | Respuesta |
|---|---|---|---|---|---|
| 1 | Proyectos paralelos que sacan recursos comprometidos | Alta | Alto | 9 | Evitar |
| 2 | Subestimación del esfuerzo necesario | Media | Alto | 6 | Evitar |
| 3 | Falta de ambientes para el despliegue | Baja | Alto | 3 | Mitigar |
| 4 | Falta de experiencia y habilidades del equipo técnico | Media | Medio | 4 | Mitigar |
| 5 | Concentración de conocimiento en pocas personas | Baja | Bajo | 1 | Aceptar |

## 15. Riesgos positivos (oportunidades)

| # | Riesgo | Prob. | Imp. | Exposición | Respuesta |
|---|---|---|---|---|---|
| 1 | Aprendizaje acelerado del stack mobile con IA | Alta | Alto | 9 | Explotar |
| 2 | Desarrollo más rápido por reutilización de componentes/librerías/IA | Media | Alto | 6 | Explotar |
| 3 | Menor esfuerzo de desarrollo al estimado | Baja | Alto | 3 | Mejorar |
| 4 | Menos defectos por testing incremental | Media | Medio | 4 | Mejorar |
| 5 | Mejor coordinación y productividad del equipo | Baja | Bajo | 1 | Mejorar |

## 16. Análisis de factibilidad

| Dimensión | Resultado |
|---|---|
| Político | Factible |
| Económico | Factible |
| Social | Factible |
| Tecnológico | Factible con mitigaciones |
| Ecológico | Factible |
| Legal | Factible con consideraciones (protección de datos, guidelines Play Store) |

**Conclusión:** Avanzar, priorizando en el MVP el flujo central (creación de evento, disponibilidad, confirmación de asistencia), dejando gastos para iteración posterior, mitigando riesgos técnicos vía capacitación, arquitectura clara, testing incremental y despliegues controlados.
