# Tanda 5 - Mejoras de navegación, componentes reutilizables y UI Mobile

## Item 3: Componente EventCard Unificado
- Se rediseñó el componente `EventCard` en `mobile/lib/core/widgets/event_card.dart` para utilizar `Container` con bordes redondeados, sombras suaves y elevación cero (`elevation: 0`).
- Se añadieron nuevas propiedades como `width`, `topBadge` y `trailing` para aumentar su flexibilidad y permitir su reutilización.
- Se refactorizó `EventoResumenCard` para aprovechar estas nuevas propiedades (`topBadge` para la fecha y el ícono en `trailing`), alineándolo al diseño del carrusel y unificando su estructura sin duplicar componentes.

## Item 1: Home Carrusel y Backend Historial
- **Backend:** Se modificó la consulta en `backend/src/infrastructure/prisma/evento.prisma.repository.ts` (renombrando el método a `listHistoryForUsuario`) para incluir eventos confirmados y pendientes cuya fecha sea menor o igual al final del mes en curso, cumpliendo con la regla de negocio. Se actualizó el repositorio e interfaces para enviar el límite temporal del mes actual.
- **Frontend (Home):** Se actualizó el layout de los "Próximos eventos" en `HomeScreen`. Se pasó de una lista vertical (`Column`) a un carrusel horizontal estático de altura fija usando `ListView.separated`.
- Se añadió un `TextButton` alineado a la derecha que dice "Ver todos" y que navega hacia el `HistoryScreen`.

## Item 2: Navbar Flotante con efecto Glassmorphism
- **AppBottomNav:** Se reemplazó el `NavigationBar` de Material3 por un diseño a medida en `mobile/lib/core/widgets/app_scaffold.dart`.
- El nuevo widget utiliza `ClipRRect` con un `BackdropFilter` de tipo blur y bordes redondeados, además de un sutil borde blanco semitransparente.
- **Estados:** Se creó `_NavItem` para gestionar los íconos inactivos (outline, sin fondo) y activos (filled, con fondo `primary.withOpacity(0.15)`).
- **Integración Scaffold:** Se actualizó `AppShell` activando la propiedad `extendBody: true` del `Scaffold` y desactivando el `SafeArea` inferior para que el fondo del listado fluya orgánicamente por debajo de la Navbar, mejorando notablemente el efecto *glassmorphism*.
