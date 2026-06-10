-- Picks globales: una selección por usuario+bloque, no por liga
-- Las ligas son solo grupos de competición, no cambian los picks

DROP TABLE IF EXISTS selections;

CREATE TABLE selections (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  block      INTEGER NOT NULL CHECK (block BETWEEN 1 AND 6),
  team1      TEXT NOT NULL,
  team2      TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, block)
);

ALTER TABLE selections ENABLE ROW LEVEL SECURITY;
CREATE POLICY "selections_select" ON selections FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "selections_insert" ON selections FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "selections_update" ON selections FOR UPDATE TO authenticated USING (auth.uid() = user_id);

-- get_leaderboard: todos los miembros de la liga con sus puntos (0 si no han elegido)
CREATE OR REPLACE FUNCTION get_leaderboard(p_league_id UUID)
RETURNS TABLE(user_id UUID, username TEXT, points BIGINT)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT
    lm.user_id,
    p.username,
    COALESCE(SUM(
      (CASE WHEN r1.won IS TRUE THEN 1 ELSE 0 END) +
      (CASE WHEN r2.won IS TRUE THEN 1 ELSE 0 END)
    ), 0)::BIGINT AS points
  FROM league_members lm
  JOIN profiles p ON p.id = lm.user_id
  LEFT JOIN selections s ON s.user_id = lm.user_id
  LEFT JOIN results r1 ON r1.block = s.block AND r1.team_code = s.team1
  LEFT JOIN results r2 ON r2.block = s.block AND r2.team_code = s.team2
  WHERE lm.league_id = p_league_id
  GROUP BY lm.user_id, p.username
  ORDER BY points DESC, username ASC;
$$;

-- get_global_leaderboard: todos los usuarios de la app
CREATE OR REPLACE FUNCTION get_global_leaderboard()
RETURNS TABLE(user_id UUID, username TEXT, points BIGINT)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT
    pr.id AS user_id,
    pr.username,
    COALESCE(SUM(
      (CASE WHEN r1.won IS TRUE THEN 1 ELSE 0 END) +
      (CASE WHEN r2.won IS TRUE THEN 1 ELSE 0 END)
    ), 0)::BIGINT AS points
  FROM profiles pr
  LEFT JOIN selections s ON s.user_id = pr.id
  LEFT JOIN results r1 ON r1.block = s.block AND r1.team_code = s.team1
  LEFT JOIN results r2 ON r2.block = s.block AND r2.team_code = s.team2
  GROUP BY pr.id, pr.username
  ORDER BY points DESC, username ASC;
$$;

GRANT EXECUTE ON FUNCTION get_leaderboard(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_global_leaderboard() TO authenticated;
