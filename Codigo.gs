/*************************************************************
 * 🦑 JUEGO DEL CALAMAR DEL MUNDIAL 2026 — Fase de grupos
 * Backend (Google Apps Script) + Google Sheets como "Excel"
 *
 * Funciona así:
 *   - doGet()  -> sirve la página web (Index.html)
 *   - getConfig() -> envía equipos por bloque, fechas límite, jugadores
 *   - getDatos(nombre) -> envía todas las selecciones guardadas
 *   - guardar(nombre, bloque, equipos) -> valida y guarda en la hoja
 *
 * Cada fila de la hoja "Selecciones" = un jugador en un bloque.
 *************************************************************/

// ====== AJUSTES QUE PUEDES TOCAR ======

// Nombres de los jugadores (recomendado rellenarlos para evitar
// que la misma persona se escriba de dos formas distintas).
// Si lo dejas vacío [], cada uno escribe su nombre a mano.
var JUGADORES = [
  "Arias", "Miguel Jaime", "Alvaro R", "Sergio", "Miguel Cruz", "Rafa Galadi",
  "Motilla", "Juan Merino", "Pablo Iglesias", "Andres", "Fran Segura",
  "Josema Ropero", "Iosu", "Filippo", "Edu", "Carlos", "Juanma"
];

// Fecha y hora límite de cada bloque (zona horaria España, +02:00 en verano).
// A partir de esa hora el bloque se CIERRA y ya no se puede tocar.
// Ajústalas si las horas de tu cartel son distintas.
var FECHAS_LIMITE = {
  1: "2026-06-11T21:00:00+02:00",
  2: "2026-06-15T00:00:00+02:00",
  3: "2026-06-19T00:00:00+02:00",
  4: "2026-06-23T00:00:00+02:00",
  5: "2026-06-25T00:00:00+02:00",
  6: "2026-06-27T00:00:00+02:00"
};

// ====== EQUIPOS (código -> nombre, bandera, grupo) ======
// Grupo H = ESP, CPV, Arabia Saudí (KSA), URU.
// Grupo I = FRA, SEN, NOR, Irak (IRQ).
var TEAMS = {
  MEX:{n:"México",f:"🇲🇽",g:"A"}, RSA:{n:"Sudáfrica",f:"🇿🇦",g:"A"}, KOR:{n:"Corea del Sur",f:"🇰🇷",g:"A"}, CZE:{n:"Chequia",f:"🇨🇿",g:"A"},
  CAN:{n:"Canadá",f:"🇨🇦",g:"B"}, BIH:{n:"Bosnia",f:"🇧🇦",g:"B"}, QAT:{n:"Catar",f:"🇶🇦",g:"B"}, SUI:{n:"Suiza",f:"🇨🇭",g:"B"},
  BRA:{n:"Brasil",f:"🇧🇷",g:"C"}, MAR:{n:"Marruecos",f:"🇲🇦",g:"C"}, HAI:{n:"Haití",f:"🇭🇹",g:"C"}, SCO:{n:"Escocia",f:"🏴",g:"C"},
  USA:{n:"EE. UU.",f:"🇺🇸",g:"D"}, PAR:{n:"Paraguay",f:"🇵🇾",g:"D"}, AUS:{n:"Australia",f:"🇦🇺",g:"D"}, TUR:{n:"Turquía",f:"🇹🇷",g:"D"},
  GER:{n:"Alemania",f:"🇩🇪",g:"E"}, CUW:{n:"Curazao",f:"🇨🇼",g:"E"}, CIV:{n:"Costa de Marfil",f:"🇨🇮",g:"E"}, ECU:{n:"Ecuador",f:"🇪🇨",g:"E"},
  NED:{n:"Países Bajos",f:"🇳🇱",g:"F"}, JPN:{n:"Japón",f:"🇯🇵",g:"F"}, SWE:{n:"Suecia",f:"🇸🇪",g:"F"}, TUN:{n:"Túnez",f:"🇹🇳",g:"F"},
  BEL:{n:"Bélgica",f:"🇧🇪",g:"G"}, EGY:{n:"Egipto",f:"🇪🇬",g:"G"}, IRN:{n:"Irán",f:"🇮🇷",g:"G"}, NZE:{n:"Nueva Zelanda",f:"🇳🇿",g:"G"},
  ESP:{n:"España",f:"🇪🇸",g:"H"}, CPV:{n:"Cabo Verde",f:"🇨🇻",g:"H"}, KSA:{n:"Arabia Saudí",f:"🇸🇦",g:"H"}, URU:{n:"Uruguay",f:"🇺🇾",g:"H"},
  FRA:{n:"Francia",f:"🇫🇷",g:"I"}, SEN:{n:"Senegal",f:"🇸🇳",g:"I"}, NOR:{n:"Noruega",f:"🇳🇴",g:"I"}, IRQ:{n:"Irak",f:"🇮🇶",g:"I"},
  ARG:{n:"Argentina",f:"🇦🇷",g:"J"}, ALG:{n:"Argelia",f:"🇩🇿",g:"J"}, AUT:{n:"Austria",f:"🇦🇹",g:"J"}, JOR:{n:"Jordania",f:"🇯🇴",g:"J"},
  POR:{n:"Portugal",f:"🇵🇹",g:"K"}, COD:{n:"R. D. Congo",f:"🇨🇩",g:"K"}, UZB:{n:"Uzbekistán",f:"🇺🇿",g:"K"}, COL:{n:"Colombia",f:"🇨🇴",g:"K"},
  ENG:{n:"Inglaterra",f:"🏴",g:"L"}, CRO:{n:"Croacia",f:"🇭🇷",g:"L"}, GHA:{n:"Ghana",f:"🇬🇭",g:"L"}, PAN:{n:"Panamá",f:"🇵🇦",g:"L"}
};

// ====== FECHAS DE CADA BLOQUE ======
var BLOQUES = {
  1:{ fechas:"11–14 jun" }, 2:{ fechas:"15–18 jun" }, 3:{ fechas:"19–22 jun" },
  4:{ fechas:"23–24 jun" }, 5:{ fechas:"25–26 jun" }, 6:{ fechas:"27–28 jun" }
};

// ====== PARTIDOS DE CADA BLOQUE (emparejamientos) ======
// Cada elemento es un partido [local, visitante]. Fuente: cartel del Mundial.
var PARTIDOS = {
  1: [["MEX","RSA"],["KOR","CZE"],["CAN","BIH"],["USA","PAR"],["QAT","SUI"],["BRA","MAR"],["HAI","SCO"],["AUS","TUR"],["GER","CUW"],["NED","JPN"]],
  2: [["CIV","ECU"],["SWE","TUN"],["ESP","CPV"],["BEL","EGY"],["KSA","URU"],["IRN","NZE"],["FRA","SEN"],["IRQ","NOR"],["ARG","ALG"],["AUT","JOR"],["POR","COD"],["ENG","CRO"],["GHA","PAN"],["UZB","COL"],["RSA","CZE"],["BIH","SUI"]],
  3: [["CAN","QAT"],["MEX","KOR"],["USA","AUS"],["SCO","MAR"],["BRA","HAI"],["TUR","PAR"],["NED","SWE"],["GER","CIV"],["ECU","CUW"],["TUN","JPN"],["ESP","KSA"],["BEL","IRN"],["URU","CPV"],["NZE","EGY"],["ARG","AUT"],["FRA","IRQ"]],
  4: [["NOR","SEN"],["JOR","ALG"],["POR","UZB"],["ENG","GHA"],["PAN","CRO"],["COL","COD"],["BIH","QAT"],["SUI","CAN"]],
  5: [["SCO","BRA"],["MAR","HAI"],["RSA","KOR"],["CZE","MEX"],["ECU","GER"],["CUW","CIV"],["JPN","SWE"],["TUN","NED"],["TUR","USA"],["PAR","AUS"],["SEN","IRQ"],["NOR","FRA"]],
  6: [["URU","ESP"],["CPV","KSA"],["NZE","BEL"],["EGY","IRN"],["CRO","GHA"],["PAN","ENG"],["COL","POR"],["COD","UZB"],["JOR","ARG"],["ALG","AUT"]]
};

// Lista de equipos que juegan en un bloque (derivada de los partidos, sin repetir).
function equiposDeBloque_(b) {
  var visto = {}, out = [];
  PARTIDOS[b].forEach(function(p) {
    p.forEach(function(c) { if (!visto[c]) { visto[c] = 1; out.push(c); } });
  });
  return out;
}

var NOMBRE_HOJA = "Selecciones";
var CABECERAS = ["Jugador","Bloque","Equipo 1","Equipo 2","Equipos (nombres)","Última edición"];
var NOMBRE_HOJA_PINS = "Jugadores"; // guarda el PIN (cifrado) de cada jugador
var NOMBRE_HOJA_RES = "Resultados";  // una casilla por equipo+bloque: marcada = ganó

// ====== SERVIR LA WEB ======
function doGet() {
  return HtmlService.createHtmlOutputFromFile("Index")
    .setTitle("🦑 Juego del Calamar — Mundial 2026")
    .addMetaTag("viewport", "width=device-width, initial-scale=1")
    .setSandboxMode(HtmlService.SandboxMode.IFRAME);
}

// ====== CONFIG PARA EL FRONT ======
function getConfig() {
  // ¿Está abierto cada bloque?
  var ahora = new Date();
  var bloques = {};
  for (var b = 1; b <= 6; b++) {
    var limite = new Date(FECHAS_LIMITE[b]);
    bloques[b] = {
      fechas: BLOQUES[b].fechas,
      equipos: equiposDeBloque_(b),
      partidos: PARTIDOS[b],
      limite: FECHAS_LIMITE[b],
      abierto: ahora.getTime() < limite.getTime()
    };
  }
  return { teams: TEAMS, bloques: bloques, jugadores: JUGADORES, ahora: ahora.toISOString() };
}

// ====== LEER SOLO LAS SELECCIONES DEL PROPIO JUGADOR ======
// (Privacidad: nadie recibe las elecciones de los demás, ni siquiera por debajo.)
function getDatos(nombre, pin) {
  nombre = (nombre || "").trim();
  if (!nombre) return [];
  if (!pinOk_(nombre, pin)) return [];
  var hoja = getHoja_();
  var valores = hoja.getDataRange().getValues();
  var out = [];
  for (var i = 1; i < valores.length; i++) {
    var fila = valores[i];
    if (!fila[0]) continue;
    if (String(fila[0]).toLowerCase() !== nombre.toLowerCase()) continue;
    out.push({
      jugador: String(fila[0]),
      bloque: Number(fila[1]),
      equipos: [String(fila[2]), String(fila[3])],
      fecha: fila[5] ? new Date(fila[5]).toISOString() : ""
    });
  }
  return out;
}

// ====== GUARDAR (upsert con validación) ======
function guardar(nombre, pin, bloque, equipos) {
  nombre = (nombre || "").trim();
  bloque = Number(bloque);
  if (!nombre) return { ok:false, error:"Escribe tu nombre." };
  if (!pinOk_(nombre, pin)) return { ok:false, error:"Sesión no válida. Vuelve a entrar con tu PIN." };
  if (!(bloque >= 1 && bloque <= 6)) return { ok:false, error:"Bloque no válido." };
  if (!equipos || equipos.length !== 2) return { ok:false, error:"Tienes que elegir exactamente 2 equipos." };
  if (equipos[0] === equipos[1]) return { ok:false, error:"No puedes elegir dos veces el mismo equipo." };

  // Bloque abierto
  var limite = new Date(FECHAS_LIMITE[bloque]);
  if (new Date().getTime() >= limite.getTime()) {
    return { ok:false, error:"⏰ El bloque " + bloque + " ya está cerrado. Te quedas sin equipos en este bloque." };
  }

  // Equipos válidos para ese bloque
  var validos = equiposDeBloque_(bloque);
  for (var i = 0; i < 2; i++) {
    if (validos.indexOf(equipos[i]) === -1) {
      return { ok:false, error:"Ese equipo no juega en el bloque " + bloque + "." };
    }
  }

  var lock = LockService.getScriptLock();
  lock.waitLock(20000);
  try {
    var hoja = getHoja_();
    var valores = hoja.getDataRange().getValues();

    // Regla: no repetir un equipo usado en OTRO bloque
    var usados = {};
    var filaExistente = -1;
    for (var r = 1; r < valores.length; r++) {
      var jug = String(valores[r][0]);
      var blq = Number(valores[r][1]);
      if (jug.toLowerCase() !== nombre.toLowerCase()) continue;
      if (blq === bloque) { filaExistente = r + 1; continue; }
      usados[String(valores[r][2])] = blq;
      usados[String(valores[r][3])] = blq;
    }
    for (var j = 0; j < 2; j++) {
      if (usados[equipos[j]]) {
        return { ok:false, error:"Ya usaste " + nombreEquipo_(equipos[j]) + " en el bloque " + usados[equipos[j]] + ". No se puede repetir." };
      }
    }

    var nombresTxt = nombreEquipo_(equipos[0]) + " + " + nombreEquipo_(equipos[1]);
    var fila = [nombre, bloque, equipos[0], equipos[1], nombresTxt, new Date()];

    if (filaExistente > 0) {
      hoja.getRange(filaExistente, 1, 1, fila.length).setValues([fila]);
    } else {
      hoja.appendRow(fila);
    }
    return { ok:true };
  } finally {
    lock.releaseLock();
  }
}

// ====== CLASIFICACIÓN ======
// Puntos = nº de equipos elegidos cuya casilla "¿Ganó?" está marcada.
// Es pública (solo muestra nombre + puntos, NO los equipos de cada uno).
function getClasificacion() {
  var gana = {};
  var res = getResultadosSheet_();
  var rv = res.getDataRange().getValues();
  for (var i = 1; i < rv.length; i++) {
    if (rv[i][3] === true) gana[rv[i][0] + "|" + rv[i][1]] = true; // "bloque|código"
  }

  var sel = getHoja_();
  var sv = sel.getDataRange().getValues();
  var porNombre = {};
  for (var j = 1; j < sv.length; j++) {
    var fila = sv[j];
    if (!fila[0]) continue;
    var n = String(fila[0]);
    var b = Number(fila[1]);
    if (!porNombre[n]) porNombre[n] = { jugador: n, puntos: 0, elecciones: 0 };
    [String(fila[2]), String(fila[3])].forEach(function(c) {
      if (!c) return;
      porNombre[n].elecciones++;
      if (gana[b + "|" + c]) porNombre[n].puntos++;
    });
  }

  var arr = Object.keys(porNombre).map(function(k) { return porNombre[k]; });
  arr.sort(function(a, b) {
    return (b.puntos - a.puntos) || a.jugador.toLowerCase().localeCompare(b.jugador.toLowerCase());
  });
  return arr;
}

// Crea (si no existe) la pestaña Resultados con una casilla por equipo y bloque.
function getResultadosSheet_() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var hoja = ss.getSheetByName(NOMBRE_HOJA_RES);
  if (hoja) return hoja;
  hoja = ss.insertSheet(NOMBRE_HOJA_RES);
  hoja.appendRow(["Bloque", "Código", "Equipo", "¿Ganó? (marca la casilla)"]);
  hoja.getRange(1, 1, 1, 4).setFontWeight("bold");
  hoja.setFrozenRows(1);
  var rows = [];
  for (var b = 1; b <= 6; b++) {
    equiposDeBloque_(b).forEach(function(c) { rows.push([b, c, nombreEquipo_(c), false]); });
  }
  hoja.getRange(2, 1, rows.length, 4).setValues(rows);
  hoja.getRange(2, 4, rows.length, 1).insertCheckboxes();
  hoja.setColumnWidth(3, 180);
  return hoja;
}

// ====== IDENTIDAD CON PIN ======
// La 1ª vez que un nombre entra, su PIN queda registrado (cifrado).
// Después hay que meter ese PIN para entrar o cambiar elecciones.
function login(nombre, pin) {
  nombre = (nombre || "").trim();
  pin = (pin || "").trim();
  if (!nombre) return { ok:false, error:"Elige tu nombre." };
  if (!nombreValido_(nombre)) return { ok:false, error:"Ese nombre no está en la lista de jugadores." };
  if (!/^\d{4,8}$/.test(pin)) return { ok:false, error:"El PIN debe tener entre 4 y 8 dígitos." };

  var lock = LockService.getScriptLock();
  lock.waitLock(20000);
  try {
    var hoja = getPinSheet_();
    var reg = buscarPin_(hoja, nombre);
    var h = hashPin_(nombre, pin);
    if (!reg) {                              // nadie ha reclamado este nombre todavía
      hoja.appendRow([nombre, h, new Date()]);
      return { ok:true, nuevo:true };
    }
    if (reg.hash === h) return { ok:true, nuevo:false };
    return { ok:false, error:"PIN incorrecto para " + nombre + "." };
  } finally {
    lock.releaseLock();
  }
}

function pinOk_(nombre, pin) {
  nombre = (nombre || "").trim();
  pin = (pin || "").trim();
  if (!nombre || !pin) return false;
  var reg = buscarPin_(getPinSheet_(), nombre);
  return !!reg && reg.hash === hashPin_(nombre, pin);
}

function nombreValido_(nombre) {
  if (!JUGADORES || !JUGADORES.length) return true; // si la lista está vacía, nombre libre
  for (var i = 0; i < JUGADORES.length; i++) {
    if (JUGADORES[i].toLowerCase().trim() === nombre.toLowerCase().trim()) return true;
  }
  return false;
}

function buscarPin_(hoja, nombre) {
  var v = hoja.getDataRange().getValues();
  for (var i = 1; i < v.length; i++) {
    if (String(v[i][0]).toLowerCase().trim() === nombre.toLowerCase().trim()) {
      return { fila: i + 1, hash: String(v[i][1]) };
    }
  }
  return null;
}

function hashPin_(nombre, pin) {
  var raw = "juego-calamar::" + String(nombre).toLowerCase().trim() + "::" + String(pin);
  var bytes = Utilities.computeDigest(Utilities.DigestAlgorithm.SHA_256, raw);
  var s = "";
  for (var i = 0; i < bytes.length; i++) {
    var val = (bytes[i] + 256) % 256;
    s += ("0" + val.toString(16)).slice(-2);
  }
  return s;
}

function getPinSheet_() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var hoja = ss.getSheetByName(NOMBRE_HOJA_PINS);
  if (!hoja) {
    hoja = ss.insertSheet(NOMBRE_HOJA_PINS);
    hoja.appendRow(["Jugador", "PIN (cifrado)", "Creado"]);
    hoja.getRange(1, 1, 1, 3).setFontWeight("bold");
    hoja.setFrozenRows(1);
  }
  return hoja;
}

// ====== AUXILIARES ======
function getHoja_() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var hoja = ss.getSheetByName(NOMBRE_HOJA);
  if (!hoja) {
    hoja = ss.insertSheet(NOMBRE_HOJA);
    hoja.appendRow(CABECERAS);
    hoja.getRange(1, 1, 1, CABECERAS.length).setFontWeight("bold");
    hoja.setFrozenRows(1);
  }
  return hoja;
}

function nombreEquipo_(cod) {
  return TEAMS[cod] ? (TEAMS[cod].f + " " + TEAMS[cod].n) : cod;
}
