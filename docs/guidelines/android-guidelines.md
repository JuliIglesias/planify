# Android Design Guidelines

Guía de referencia para diseñar interfaces que se sientan nativas en Android, basada en Material Design 3.

## Tabla de contenidos

1. [Tipografía](#1-tipografía)
2. [Tamaño mínimo táctil](#2-tamaño-mínimo-táctil)
3. [Márgenes y espaciado](#3-márgenes-y-espaciado)
4. [Padding interno](#4-padding-interno)
5. [Botones](#5-botones)
6. [Radio de bordes](#6-radio-de-bordes)
7. [Inputs](#7-inputs)
8. [Iconografía](#8-iconografía)
9. [Cards](#9-cards)
10. [Listas](#10-listas)
11. [Top App Bar](#11-top-app-bar)
12. [Bottom Navigation](#12-bottom-navigation)
13. [Colores](#13-colores)
14. [Accesibilidad](#14-accesibilidad)
15. [Gestos](#15-gestos)
16. [Frame de referencia](#16-frame-de-referencia)
17. [Recursos oficiales](#17-recursos-oficiales)

---

## 1. Tipografía

Material 3 usa las familias **Roboto** o **Google Sans**, con una escala tipográfica basada en tokens.

| Token           | Tamaño |
| --------------- | ------ |
| Display Large   | 57 sp  |
| Display Medium  | 45 sp  |
| Display Small   | 36 sp  |
| Headline Large  | 32 sp  |
| Headline Medium | 28 sp  |
| Headline Small  | 24 sp  |
| Title Large     | 22 sp  |
| Title Medium    | 16 sp  |
| Title Small     | 14 sp  |
| Body Large      | 16 sp  |
| Body Medium     | 14 sp  |
| Body Small      | 12 sp  |
| Label Large     | 14 sp  |
| Label Medium    | 12 sp  |
| Label Small     | 11 sp  |

## 2. Tamaño mínimo táctil

**48 × 48 dp** es el mínimo recomendado por Material Design para cualquier control interactivo.

## 3. Márgenes y espaciado

En Android casi todo el sistema se apoya en una **grilla de 8dp**.

| Uso                    | Valor |
| ----------------------- | ----- |
| Margen de pantalla      | 16 dp |
| Separación pequeña      | 8 dp  |
| Separación media        | 16 dp |
| Separación grande       | 24 dp |
| Separación entre secciones | 32 dp |
| Separación de bloques importantes | 48 dp |

Escala general de espaciado:

```
4   micro
8   pequeño
12  medio
16  estándar
24  sección
32  separación importante
48  bloques grandes
64  pantallas
```

## 4. Padding interno

| Componente        | Padding             |
| ------------------ | -------------------- |
| Botones (vertical)  | 10–14 dp             |
| Botones (horizontal)| 16–24 dp             |
| Cards               | 16 dp                |
| Inputs               | 16 dp                |
| Bottom Sheets        | 24 dp                |

## 5. Botones

Material define cinco jerarquías, de mayor a menor énfasis visual:

- **Filled** — acción principal.
- **Filled Tonal** — acción secundaria con énfasis medio-alto.
- **Elevated** — acción secundaria sobre fondos planos.
- **Outlined** — acción secundaria de menor énfasis.
- **Text** — acción terciaria o de bajo énfasis.

Regla general: a mayor importancia de la acción, mayor énfasis visual del botón.

## 6. Radio de bordes

Material 3 favorece esquinas bastante redondeadas. Valores típicos:

**8dp · 12dp · 16dp · 20dp · 28dp**

## 7. Inputs

Buenas prácticas:

- Label siempre visible.
- Placeholder opcional (nunca como único indicador del campo).
- Mensaje de error debajo del campo.
- Helper text cuando agregue contexto útil.
- Íconos solo cuando aportan valor real.

Altura habitual: **56 dp**.

## 8. Iconografía

Android utiliza el sistema **Material Symbols**.

Tamaño estándar: **24 dp**.

## 9. Cards

| Propiedad               | Valor      |
| ------------------------ | ---------- |
| Padding interno           | 16 dp      |
| Separación entre cards    | 16 dp      |
| Radio de bordes           | 12–16 dp   |
| Elevación                  | muy baja (Material 3 favorece superficies planas con color) |

## 10. Listas

Alturas típicas según contenido:

| Contenido de la fila         | Altura |
| ------------------------------ | ------ |
| Solo texto                       | 56 dp  |
| Texto + subtítulo                | 72 dp  |
| Texto + avatar/ícono grande       | 88 dp  |

## 11. Top App Bar

Altura estándar: **64 dp** aproximadamente.

## 12. Bottom Navigation

- Entre **3 y 5 items**.
- Altura aproximada: **80 dp**.
- Uso de Floating Action Button (FAB) cuando la pantalla tiene una acción principal destacada.

## 13. Colores

Material 3 se basa en un sistema de roles de color dinámicos (Material You), no en valores fijos:

- Primary / Secondary / Tertiary
- Surface / Surface Container
- Error
- Outline

Se recomienda siempre usar estos roles semánticos en lugar de colores hardcodeados, para soportar modo claro/oscuro y temas dinámicos automáticamente.

## 14. Accesibilidad

- Contraste mínimo de **4.5:1** para texto normal.
- Soporte completo para **modo oscuro**.
- Soporte para escalado dinámico de tipografía.
- Áreas táctiles de al menos 48×48 dp.
- No depender únicamente del color para comunicar estado (usar íconos/texto también).
- Etiquetas de contenido accesibles (`contentDescription`) para TalkBack.

## 15. Gestos

- Back gesture (deslizar desde el borde para volver).
- Edge swipe.
- Bottom sheet (deslizar para expandir/cerrar).
- Pull to refresh.
- Floating Action Button para la acción principal, cuando aplica.

## 16. Frame de referencia

Ancho de diseño recomendado: **412 dp** (equivalente a un Pixel estándar), verificando luego el comportamiento en pantallas más chicas y más grandes (tablets, foldables).

## 17. Recursos oficiales

- [Material Design 3 Guidelines](https://m3.material.io)
- [Material Design Figma Kit](https://www.figma.com/community/file/1035203688168086460/material-3-design-kit)
