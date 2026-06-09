# 🦑 Juego del Calamar del Mundial 2026 — Cómo ponerlo en marcha

Vas a tener **un único link** que pasas al grupo. Cada uno entra, escribe su nombre y
elige 2 equipos por bloque. Todo cae automáticamente en una **hoja de Google (tu "Excel")**.

Tienes 2 archivos:
- `Codigo.gs` → el "motor" (servidor).
- `Index.html` → la página que ven tus amigos.

---

## Paso a paso (se hace UNA vez, ~10 min)

### 1. Crea la hoja de cálculo
1. Ve a https://sheets.google.com y crea una hoja nueva.
2. Ponle nombre, p. ej. **"Mundial Calamar"**.
   *(No hace falta crear pestañas ni cabeceras: el programa crea la hoja "Selecciones" sola.)*

### 2. Abre el editor de Apps Script
1. En esa hoja, menú **Extensiones → Apps Script**.
2. Se abre el editor de código.

### 3. Pega el código
1. Borra todo lo que haya en el archivo `Código.gs` que aparece y pega **todo** el contenido de `Codigo.gs`.
2. Crea el archivo HTML: pulsa el **+** (arriba a la izquierda) → **HTML** → llámalo exactamente **`Index`** (sin `.html`).
3. Borra lo que traiga y pega **todo** el contenido de `Index.html`.
4. Pulsa el icono de **guardar** (💾).

### 4. Publica la web
1. Arriba a la derecha: **Implementar → Nueva implementación**.
2. En el engranaje ⚙ (tipo) elige **Aplicación web**.
3. Configura:
   - **Ejecutar como:** *Yo* (tu cuenta).
   - **Quién tiene acceso:** **Cualquier usuario** *(para que tus amigos entren sin pedir permiso)*.
4. **Implementar**. La primera vez te pedirá **autorizar permisos**: acepta
   (sale un aviso de "Google no ha verificado la app" → *Configuración avanzada → Ir a (no seguro)* → Permitir. Es tu propia app, es seguro).
5. Copia la **URL de la aplicación web**. **Ese es el link que pasas al grupo.** ✅

> Cada vez que cambies el código, repite: **Implementar → Gestionar implementaciones → editar (lápiz) → Versión: Nueva → Implementar**. Así el link no cambia.

---

## Antes de pasar el link, revisa esto en `Codigo.gs`

1. **Fechas límite** (`FECHAS_LIMITE`): a partir de esa hora el bloque se **cierra** y
   nadie puede tocarlo (regla del plazo). Ajusta las horas si las de tu cartel difieren.

2. **Jugadores** (`JUGADORES`): ya están cargados los 14 nombres, así que cada uno
   elige el suyo en un desplegable (sin líos de mayúsculas/tildes). Si falta o sobra
   alguien, edita esa lista.

> Grupos confirmados: **H** = ESP, CPV, Arabia Saudí, URU · **I** = FRA, SEN, NOR, Irak.

---

## Reglas que la web ya aplica sola
- ✅ 2 equipos por bloque (ni más ni menos).
- ✅ No puedes repetir un equipo usado en otro bloque (sale en rojo).
- ✅ Solo equipos que juegan en ese bloque.
- ✅ Bloque cerrado tras su fecha límite → no se puede enviar.
- ✅ **Identidad con PIN:** la 1ª vez que alguien entra con su nombre, crea un PIN (4–8 dígitos) y ese nombre queda suyo. Sin ese PIN, nadie puede suplantarle ni ver/editar sus equipos (la comprobación está en el servidor).
- ✅ **Privacidad:** cada jugador solo ve **sus propias** elecciones; nadie ve las de los demás (ni por debajo). Tú, en la hoja, lo ves todo.
- ✅ **Clasificación:** botón "🏆 Ver clasificación" con los puntos de todos (1 punto por cada equipo tuyo que gana). Muestra nombre + puntos, sin desvelar los equipos de cada uno.

## Lo que NO hace (de momento)
- Eliminatorias (dieciseisavos, octavos…): se añaden cuando se conozcan los equipos.

---

### La hoja "Selecciones"
Cada fila es **un jugador en un bloque**: Jugador · Bloque · Equipo 1 · Equipo 2 · Nombres · Última edición.
Es tu Excel: ahí ves todo de un vistazo y puedes ordenar/filtrar.

### La hoja "Jugadores" (PINs)
Se crea sola con los PINs **cifrados** (no se ven en claro). Úsala solo para esto:
- **Reiniciar un PIN** (si alguien lo olvida): borra su fila en esa hoja. La próxima vez
  que entre con su nombre, creará un PIN nuevo.
- **Evitar que se "pillen" nombres:** como el primero que entra con un nombre se queda
  con él, lo ideal es mandar el link y que cada uno cree su PIN cuanto antes.

### La hoja "Resultados" (marcar ganadores) ⭐
Se crea sola la primera vez que alguien abre la clasificación. Tiene una fila por
**equipo y bloque** y una columna **"¿Ganó?"** con una **casilla**:
- Cuando un equipo **gana** su partido, **marca su casilla** ✅.
- **Empate o derrota** → déjala vacía (cuentan 0).
- No hace falta meter resultados ni emparejamientos: solo marcar a los ganadores.

La clasificación de la web suma sola: cada equipo elegido con su casilla marcada = **1 punto**.
Puedes ordenar/filtrar esa hoja por "Bloque" para encontrar rápido los partidos del día.
