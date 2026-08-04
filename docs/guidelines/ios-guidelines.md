# iOS Design Guidelines

Guía de referencia para diseñar interfaces que se sientan nativas en iOS, basada en las Apple Human Interface Guidelines (HIG).

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
11. [Navigation Bar](#11-navigation-bar)
12. [Tab Bar (navegación inferior)](#12-tab-bar-navegación-inferior)
13. [Colores](#13-colores)
14. [Accesibilidad](#14-accesibilidad)
15. [Gestos](#15-gestos)
16. [Frame de referencia](#16-frame-de-referencia)
17. [Recursos oficiales](#17-recursos-oficiales)

---

## 1. Tipografía

Apple recomienda usar **Dynamic Type** con la familia tipográfica **SF Pro**, para que el texto escale automáticamente según la preferencia de accesibilidad del usuario.

Escala de texto (Text Styles):

| Estilo      | Tamaño |
| ----------- | ------ |
| Large Title | 34 pt  |
| Title 1     | 28 pt  |
| Title 2     | 22 pt  |
| Title 3     | 20 pt  |
| Headline    | 17 pt  |
| Body        | 17 pt  |
| Callout     | 16 pt  |
| Subheadline | 15 pt  |
| Footnote    | 13 pt  |
| Caption 1   | 12 pt  |
| Caption 2   | 11 pt  |

Referencia general: el texto de cuerpo estándar es **17 pt**; el tamaño mínimo recomendado para cualquier texto legible es **11 pt**.

## 2. Tamaño mínimo táctil

**44 × 44 pt** es el mínimo recomendado por Apple para que cualquier elemento interactivo (botón, ícono tocable, control) pueda presionarse cómodamente con el dedo.

## 3. Márgenes y espaciado

Apple no impone una grilla estricta, pero trabaja de forma consistente en múltiplos de 8.

| Uso                    | Valor |
| ----------------------- | ----- |
| Margen de pantalla      | 16 pt |
| Separación pequeña      | 8 pt  |
| Separación media        | 16 pt |
| Separación grande       | 24 pt |
| Separación entre secciones | 32 pt |
| Separación de bloques importantes | 48 pt |

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
| Botones (vertical)  | 10–14 pt             |
| Botones (horizontal)| 16–24 pt             |
| Cards               | 16 pt                |
| Inputs               | 16 pt                |
| Bottom Sheets        | 24 pt                |

## 5. Botones

Buenas prácticas:

- Un botón primario por pantalla.
- Texto corto, en forma de verbo ("Guardar", "Continuar").
- Evitar botones de ancho completo salvo que el layout lo justifique.
- Respetar siempre el área segura (Safe Area).

Tipos de botón:

- **Filled** — acción principal.
- **Tinted** — acción secundaria con énfasis medio.
- **Plain** — acción de bajo énfasis.
- **Borderless** — acciones terciarias o de texto.

## 6. Radio de bordes

Apple no fija un valor único. En la práctica se usa generalmente entre **10 y 14 pt**, manteniendo coherencia con los componentes nativos del sistema (botones, cards, sheets).

## 7. Inputs

Buenas prácticas:

- Label siempre visible.
- Placeholder opcional (nunca como único indicador del campo).
- Mensaje de error debajo del campo.
- Helper text cuando agregue contexto útil.
- Íconos solo cuando aportan valor real.

Altura habitual: **56 pt**.

## 8. Iconografía

Apple utiliza el sistema **SF Symbols**.

Tamaños frecuentes: **20, 24, 28, 32 pt**.

## 9. Cards

| Propiedad               | Valor      |
| ------------------------ | ---------- |
| Padding interno           | 16 pt      |
| Separación entre cards    | 16 pt      |
| Radio de bordes           | 12–16 pt   |
| Elevación                  | mínima / sutil |

## 10. Listas

Alturas típicas según contenido:

| Contenido de la fila         | Altura |
| ------------------------------ | ------ |
| Solo texto                       | 56 pt  |
| Texto + subtítulo                | 72 pt  |
| Texto + avatar/ícono grande       | 88 pt  |

## 11. Navigation Bar

Altura estándar: **44 pt**, más el alto correspondiente de la Safe Area (notch / Dynamic Island / home indicator).

## 12. Tab Bar (navegación inferior)

Altura estándar: **49 pt**, más Safe Area.

## 13. Colores

Apple recomienda apoyarse siempre en los colores semánticos del sistema en lugar de valores fijos, para que la interfaz se adapte automáticamente a modo claro/oscuro y a configuraciones de accesibilidad.

Roles principales:

- System Background
- Label / Secondary Label
- Tint Color
- Fill
- Separator

## 14. Accesibilidad

- Contraste mínimo de **4.5:1** para texto normal.
- Soporte completo para **modo oscuro**.
- Soporte para **Dynamic Type** (escalado de texto).
- Áreas táctiles de al menos 44×44 pt.
- No depender únicamente del color para comunicar estado (usar íconos/texto también).
- Etiquetas accesibles (`accessibilityLabel`) para VoiceOver.

## 15. Gestos

- Swipe back (volver atrás deslizando desde el borde).
- Pull to refresh.
- Long press.
- Context menu (menú contextual con long press / 3D touch).
- Navegación por Tab Bar.

## 16. Frame de referencia

Ancho de diseño recomendado: **375 pt** (iPhone estándar), verificando luego el comportamiento en tamaños más chicos (SE) y más grandes (Pro Max, iPad).

## 17. Recursos oficiales

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)
- [Apple Design Resources (Figma y Sketch)](https://developer.apple.com/design/resources/)
