-- Picks especiales: Balón de Oro, Bota de Oro, Mejor Jugador Joven
CREATE TABLE IF NOT EXISTS special_picks (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  award      TEXT NOT NULL CHECK (award IN ('balon_oro','bota_oro','mejor_joven')),
  player     TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, award)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON special_picks TO anon, authenticated;

-- Tabla para que el organizador registre los ganadores reales
CREATE TABLE IF NOT EXISTS special_results (
  award  TEXT PRIMARY KEY CHECK (award IN ('balon_oro','bota_oro','mejor_joven')),
  player TEXT NOT NULL
);

GRANT SELECT ON special_results TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON special_results TO authenticated;
