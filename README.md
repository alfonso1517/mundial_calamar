# 🦑 Juego del Calamar del Mundial 2026

Web para jugar la porra "Juego del Calamar" del Mundial 2026 con amigos: cada jugador
elige 2 equipos por bloque, gana quien sume más victorias. Hecho con **Google Apps
Script + Google Sheets** (la hoja hace de base de datos / "Excel"), así que es gratis,
sin servidor y con un único enlace para todos.

## ¿Qué hace?
- Identificación por **nombre + PIN** (nadie puede suplantar a otro).
- **Privacidad:** cada jugador solo ve sus propias elecciones.
- Selección **por partidos** (ej: *México vs Sudáfrica*), 2 equipos por bloque.
- Reglas automáticas: no repetir equipo, solo equipos del bloque, cierre por fecha límite.
- **Clasificación** en vivo: 1 punto por cada equipo tuyo que gana su partido.
- Todo se guarda en una hoja de Google (pestaña `Selecciones`).

## Archivos
| Archivo | Qué es |
|---|---|
| `Codigo.gs` | Backend (Google Apps Script): lógica, validaciones y guardado en la hoja. |
| `Index.html` | La página web que ven los jugadores (móvil). |
| `INSTRUCCIONES.md` | **Guía paso a paso** para montarlo y publicarlo (empieza por aquí). |
| `navas.jpeg` | Imagen usada de fondo (referencia). |

## Cómo ponerlo en marcha
Sigue **[INSTRUCCIONES.md](INSTRUCCIONES.md)**. Resumen:
1. Crea una hoja en Google Sheets → **Extensiones → Apps Script**.
2. Pega `Codigo.gs` y crea un archivo HTML llamado `Index` con el contenido de `Index.html`.
3. **Implementar → Aplicación web** (Ejecutar como: Yo · Acceso: Cualquier usuario).
4. Comparte el enlace `/exec` con tu grupo.

## Personalizar
En `Codigo.gs` (arriba del todo) puedes editar:
- `JUGADORES`: la lista de nombres.
- `FECHAS_LIMITE`: cuándo se cierra cada bloque.
- `PARTIDOS`: los emparejamientos de cada bloque.

El fondo se cambia en `Index.html` (línea `body::before`, propiedad `url(...)`).
