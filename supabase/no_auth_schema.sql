-- ============================================================
-- JUEGO DEL CALAMAR — MUNDIAL 2026
-- Schema sin Supabase Auth: tabla users propia, sin rate limits
-- ============================================================

-- Limpiar funciones y tablas anteriores
DROP FUNCTION IF EXISTS get_leaderboard(UUID) CASCADE;
DROP FUNCTION IF EXISTS get_global_leaderboard() CASCADE;
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS handle_new_league() CASCADE;

DROP TABLE IF EXISTS selections CASCADE;
DROP TABLE IF EXISTS league_members CASCADE;
DROP TABLE IF EXISTS leagues CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

ALTER TABLE IF EXISTS results DISABLE ROW LEVEL SECURITY;

-- ============================================================
-- TABLAS
-- ============================================================

-- Usuarios propios (sin dependencia de auth.users)
CREATE TABLE IF NOT EXISTS users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username      TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- Ligas
CREATE TABLE IF NOT EXISTS leagues (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  creator_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  invite_code TEXT UNIQUE NOT NULL DEFAULT UPPER(SUBSTR(MD5(gen_random_uuid()::TEXT), 1, 6)),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Miembros de liga
CREATE TABLE IF NOT EXISTS league_members (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  league_id UUID NOT NULL REFERENCES leagues(id) ON DELETE CASCADE,
  user_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(league_id, user_id)
);

-- Picks globales (un set por usuario, compite en todas sus ligas)
CREATE TABLE IF NOT EXISTS selections (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  block      INTEGER NOT NULL CHECK (block BETWEEN 1 AND 6),
  team1      TEXT NOT NULL,
  team2      TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, block)
);

-- ============================================================
-- PERMISOS: acceso total con la clave anon (sin RLS)
-- ============================================================
GRANT SELECT, INSERT, UPDATE, DELETE ON users TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON leagues TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON league_members TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON selections TO anon, authenticated;
GRANT SELECT ON results TO anon, authenticated;

-- ============================================================
-- TRIGGER: al crear una liga, añadir al creador como miembro
-- ============================================================
CREATE OR REPLACE FUNCTION handle_new_league()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO league_members (league_id, user_id)
  VALUES (NEW.id, NEW.creator_id)
  ON CONFLICT DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_league_created ON leagues;
CREATE TRIGGER on_league_created
  AFTER INSERT ON leagues
  FOR EACH ROW EXECUTE FUNCTION handle_new_league();

-- ============================================================
-- FUNCIONES DE CLASIFICACIÓN
-- ============================================================

CREATE OR REPLACE FUNCTION get_leaderboard(p_league_id UUID)
RETURNS TABLE(user_id UUID, username TEXT, points BIGINT)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT
    lm.user_id,
    u.username,
    COALESCE(SUM(
      (CASE WHEN r1.won IS TRUE THEN 1 ELSE 0 END) +
      (CASE WHEN r2.won IS TRUE THEN 1 ELSE 0 END)
    ), 0)::BIGINT AS points
  FROM league_members lm
  JOIN users u ON u.id = lm.user_id
  LEFT JOIN selections s ON s.user_id = lm.user_id
  LEFT JOIN results r1 ON r1.block = s.block AND r1.team_code = s.team1
  LEFT JOIN results r2 ON r2.block = s.block AND r2.team_code = s.team2
  WHERE lm.league_id = p_league_id
  GROUP BY lm.user_id, u.username
  ORDER BY points DESC, username ASC;
$$;

CREATE OR REPLACE FUNCTION get_global_leaderboard()
RETURNS TABLE(user_id UUID, username TEXT, points BIGINT)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT
    u.id AS user_id,
    u.username,
    COALESCE(SUM(
      (CASE WHEN r1.won IS TRUE THEN 1 ELSE 0 END) +
      (CASE WHEN r2.won IS TRUE THEN 1 ELSE 0 END)
    ), 0)::BIGINT AS points
  FROM users u
  LEFT JOIN selections s ON s.user_id = u.id
  LEFT JOIN results r1 ON r1.block = s.block AND r1.team_code = s.team1
  LEFT JOIN results r2 ON r2.block = s.block AND r2.team_code = s.team2
  GROUP BY u.id, u.username
  ORDER BY points DESC, username ASC;
$$;

GRANT EXECUTE ON FUNCTION get_leaderboard(UUID) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_global_leaderboard() TO anon, authenticated;
