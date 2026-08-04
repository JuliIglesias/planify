# Tanda 4 - UI/UX & Fixes

## 1. Inputs: mayúscula inicial automática + componente reutilizable
Se creó `AppTextField` centralizado en `mobile/lib/core/widgets/app_text_field.dart`.
Este componente usa `TextCapitalization.sentences` para la primera letra. Tiene variantes opcionales y se implementó a través de la app.

## 2. Formateo de Moneda
Se creó la clase utilitaria `MoneyFormat` en `mobile/lib/core/utils/money_format.dart` para aplicar el formato con puntos y comas según la notación `$ 5.666,99`. Este componente se integró en `BalancesScreen`, `PersonDetailSheet`, `EventDetailScreen` y el `ActivityFeed` para estandarizar la presentación visual de la moneda. 

## 3. Dialogs
Se implementó `AppDialog` con un diseño y estilo general estándar y se remplazaron los diálogos hardcodeados en el sistema por este componente.

## 4. Gasto Manual (Split)
Se modificó `ExpenseDialog` y `ExpenseScreen` para incluir una opción manual de división de gastos. Se envían los datos pertinentes al backend si es división manual.

## 5. Tareas: Swipe Actions
Se implementó `flutter_slidable` en las tareas de la pantalla de eventos (`mobile/lib/features/events/event_detail_screen.dart`). 
Deslizar a la derecha ofrece la acción "Completar"/"Descompletar" o "Tomar" dependiendo del estado, mientras deslizar a la izquierda revela las acciones secundarias ("Desasignar" y "Eliminar"). Las llamadas al backend correspondientes se agregaron al backend (`routes.ts`, `tasks.service.ts`). 

## 6. Balances: Toggle Size
Se modificó la vista `BalancesScreen` para envolver el `SegmentedButton` en un contenedor (`SizedBox(width: double.infinity, ...)`) asegurando que el toggle ahora cubra el 100% del ancho disponible de la pantalla.

## 7. Bug: Saldos - Cálculo
Se arregló el error de cálculo neto cruzado en el backend (`DebtsService`). Se cambió la lógica para deducir correctamente las deudas considerando qué participante debía y a quién. 
