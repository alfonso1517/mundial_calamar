-- ============================================================
-- JUEGO DEL CALAMAR — MUNDIAL 2026
-- Schema completo de Supabase
-- Ejecutar en: Supabase Dashboard → SQL Editor → New query
-- ============================================================


-- ============================================================
-- 1. TABLAS
-- ============================================================

-- Perfil público de cada usuario (nombre visible en clasificación)
CREATE TABLE IF NOT EXISTS profiles (
  id         UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username   TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ligas (grupos de juego independientes)
CREATE TABLE IF NOT EXISTS leagues (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  creator_id  UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  invite_code TEXT UNIQUE NOT NULL DEFAULT UPPER(SUBSTR(MD5(gen_random_uuid()::TEXT), 1, 6)),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Miembros de cada liga
CREATE TABLE IF NOT EXISTS league_members (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  league_id UUID NOT NULL REFERENCES leagues(id) ON DELETE CASCADE,
  user_id   UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(league_id, user_id)
);

-- Selecciones de equipos (2 por bloque por jugador por liga)
CREATE TABLE IF NOT EXISTS selections (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  league_id  UUID NOT NULL REFERENCES leagues(id) ON DELETE CASCADE,
  block      INTEGER NOT NULL CHECK (block BETWEEN 1 AND 6),
  team1      TEXT NOT NULL,
  team2      TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, league_id, block)
);

-- Resultados: el organizador marca ganadores desde el dashboard de Supabase
CREATE TABLE IF NOT EXISTS results (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  block     INTEGER NOT NULL,
  team_code TEXT NOT NULL,
  won       BOOLEAN DEFAULT FALSE,
  UNIQUE(block, team_code)
);


-- ============================================================
-- 2. ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE profiles      ENABLE ROW LEVEL SECURITY;
ALTER TABLE leagues        ENABLE ROW LEVEL SECURITY;
ALTER TABLE league_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE selections     ENABLE ROW LEVEL SECURITY;
ALTER TABLE results        ENABLE ROW LEVEL SECURITY;

-- PROFILES: visibles por todos los usuarios autenticados
CREATE POLICY "profiles_select" ON profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "profiles_insert" ON profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_update" ON profiles FOR UPDATE TO authenticated USING (auth.uid() = id);

-- LEAGUES: visibles por todos (necesario para unirse por invite_code antes de ser miembro)
CREATE POLICY "leagues_select" ON leagues FOR SELECT TO authenticated USING (true);
CREATE POLICY "leagues_insert" ON leagues FOR INSERT TO authenticated WITH CHECK (auth.uid() = creator_id);
CREATE POLICY "leagues_update" ON leagues FOR UPDATE TO authenticated USING (auth.uid() = creator_id);
CREATE POLICY "leagues_delete" ON leagues FOR DELETE TO authenticated USING (auth.uid() = creator_id);

-- LEAGUE MEMBERS
CREATE POLICY "league_members_select" ON league_members FOR SELECT TO authenticated USING (
  user_id = auth.uid()
  OR league_id IN (SELECT id FROM leagues WHERE creator_id = auth.uid())
);
CREATE POLICY "league_members_insert" ON league_members FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "league_members_delete" ON league_members FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- SELECTIONS: cada usuario solo ve las suyas (privacidad — la clasificación usa una función aparte)
CREATE POLICY "selections_select" ON selections FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "selections_insert" ON selections FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "selections_update" ON selections FOR UPDATE TO authenticated USING (auth.uid() = user_id);

-- RESULTS: lectura pública para calcular clasificación
CREATE POLICY "results_select" ON results FOR SELECT TO authenticated USING (true);
-- Los resultados solo se modifican desde el dashboard de Supabase (service_role, bypasa RLS)


-- ============================================================
-- 3. TRIGGERS
-- ============================================================

-- Al registrarse un usuario, crear su perfil automáticamente
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO profiles (id, username)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', 'jugador_' || SUBSTR(NEW.id::TEXT, 1, 6))
  )
  ON CONFLICT DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Al crear una liga, añadir al creador como primer miembro
CREATE OR REPLACE FUNCTION handle_new_league()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO league_members (league_id, user_id)
  VALUES (NEW.id, NEW.creator_id)
  ON CONFLICT DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER on_league_created
  AFTER INSERT ON leagues
  FOR EACH ROW EXECUTE FUNCTION handle_new_league();


-- ============================================================
-- 4. FUNCIÓN DE CLASIFICACIÓN
-- SECURITY DEFINER para leer selecciones de todos sin exponer datos
-- ============================================================

CREATE OR REPLACE FUNCTION get_leaderboard(p_league_id UUID)
RETURNS TABLE(user_id UUID, username TEXT, points BIGINT)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT
    s.user_id,
    p.username,
    COALESCE(SUM(
      (CASE WHEN r1.won IS TRUE THEN 1 ELSE 0 END) +
      (CASE WHEN r2.won IS TRUE THEN 1 ELSE 0 END)
    ), 0)::BIGINT AS points
  FROM selections s
  JOIN profiles p ON p.id = s.user_id
  LEFT JOIN results r1 ON r1.block = s.block AND r1.team_code = s.team1
  LEFT JOIN results r2 ON r2.block = s.block AND r2.team_code = s.team2
  WHERE s.league_id = p_league_id
  GROUP BY s.user_id, p.username
  ORDER BY points DESC, username ASC;
$$;

GRANT EXECUTE ON FUNCTION get_leaderboard(UUID) TO authenticated;


-- ============================================================
-- 5. PRE-POBLAR TABLA RESULTS (todos los equipos por bloque)
-- El organizador marca "won = true" desde el dashboard de Supabase
-- ============================================================

INSERT INTO results (block, team_code, won) VALUES
-- Bloque 1 (11-14 jun): 20 equipos
(1,'MEX',false),(1,'RSA',false),(1,'KOR',false),(1,'CZE',false),
(1,'CAN',false),(1,'BIH',false),(1,'USA',false),(1,'PAR',false),
(1,'QAT',false),(1,'SUI',false),(1,'BRA',false),(1,'MAR',false),
(1,'HAI',false),(1,'SCO',false),(1,'AUS',false),(1,'TUR',false),
(1,'GER',false),(1,'CUW',false),(1,'NED',false),(1,'JPN',false),
-- Bloque 2 (15-18 jun): 32 equipos
(2,'CIV',false),(2,'ECU',false),(2,'SWE',false),(2,'TUN',false),
(2,'ESP',false),(2,'CPV',false),(2,'BEL',false),(2,'EGY',false),
(2,'KSA',false),(2,'URU',false),(2,'IRN',false),(2,'NZE',false),
(2,'FRA',false),(2,'SEN',false),(2,'IRQ',false),(2,'NOR',false),
(2,'ARG',false),(2,'ALG',false),(2,'AUT',false),(2,'JOR',false),
(2,'POR',false),(2,'COD',false),(2,'ENG',false),(2,'CRO',false),
(2,'GHA',false),(2,'PAN',false),(2,'UZB',false),(2,'COL',false),
(2,'RSA',false),(2,'CZE',false),(2,'BIH',false),(2,'SUI',false),
-- Bloque 3 (19-22 jun): 32 equipos
(3,'CAN',false),(3,'QAT',false),(3,'MEX',false),(3,'KOR',false),
(3,'USA',false),(3,'AUS',false),(3,'SCO',false),(3,'MAR',false),
(3,'BRA',false),(3,'HAI',false),(3,'TUR',false),(3,'PAR',false),
(3,'NED',false),(3,'SWE',false),(3,'GER',false),(3,'CIV',false),
(3,'ECU',false),(3,'CUW',false),(3,'TUN',false),(3,'JPN',false),
(3,'ESP',false),(3,'KSA',false),(3,'BEL',false),(3,'IRN',false),
(3,'URU',false),(3,'CPV',false),(3,'NZE',false),(3,'EGY',false),
(3,'ARG',false),(3,'AUT',false),(3,'FRA',false),(3,'IRQ',false),
-- Bloque 4 (23-24 jun): 16 equipos
(4,'NOR',false),(4,'SEN',false),(4,'JOR',false),(4,'ALG',false),
(4,'POR',false),(4,'UZB',false),(4,'ENG',false),(4,'GHA',false),
(4,'PAN',false),(4,'CRO',false),(4,'COL',false),(4,'COD',false),
(4,'BIH',false),(4,'QAT',false),(4,'SUI',false),(4,'CAN',false),
-- Bloque 5 (25-26 jun): 24 equipos
(5,'SCO',false),(5,'BRA',false),(5,'MAR',false),(5,'HAI',false),
(5,'RSA',false),(5,'KOR',false),(5,'CZE',false),(5,'MEX',false),
(5,'ECU',false),(5,'GER',false),(5,'CUW',false),(5,'CIV',false),
(5,'JPN',false),(5,'SWE',false),(5,'TUN',false),(5,'NED',false),
(5,'TUR',false),(5,'USA',false),(5,'PAR',false),(5,'AUS',false),
(5,'SEN',false),(5,'IRQ',false),(5,'NOR',false),(5,'FRA',false),
-- Bloque 6 (27-28 jun): 20 equipos
(6,'URU',false),(6,'ESP',false),(6,'CPV',false),(6,'KSA',false),
(6,'NZE',false),(6,'BEL',false),(6,'EGY',false),(6,'IRN',false),
(6,'CRO',false),(6,'GHA',false),(6,'PAN',false),(6,'ENG',false),
(6,'COL',false),(6,'POR',false),(6,'COD',false),(6,'UZB',false),
(6,'JOR',false),(6,'ARG',false),(6,'ALG',false),(6,'AUT',false)
ON CONFLICT DO NOTHING;
