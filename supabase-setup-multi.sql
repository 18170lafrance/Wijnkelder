-- ============================================================
-- WIJNBIBLIOTHEEK MULTI-USER v1.67 — COMPLEET DATABASE SCRIPT
-- Voer dit uit in Supabase SQL Editor (kqlpttcqepzyhzdkndxa)
-- Dit script is idempotent: je kunt het veilig meerdere keren draaien
-- ============================================================

-- ── 1. EXTRA KOLOMMEN OP WIJNEN ──
ALTER TABLE wijnen ADD COLUMN IF NOT EXISTS formaat TEXT DEFAULT 'standard';
ALTER TABLE wijnen ADD COLUMN IF NOT EXISTS drink_van INTEGER;
ALTER TABLE wijnen ADD COLUMN IF NOT EXISTS drink_tot INTEGER;
ALTER TABLE wijnen ADD COLUMN IF NOT EXISTS kaart_locatie_id UUID;

-- ── 2. LOCATIES TABEL ──
CREATE TABLE IF NOT EXISTS locaties (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  naam TEXT NOT NULL,
  beschrijving TEXT DEFAULT '',
  user_id UUID NOT NULL DEFAULT auth.uid(),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Zorg dat user_id kolom bestaat (als tabel al bestond zonder)
ALTER TABLE locaties ADD COLUMN IF NOT EXISTS user_id UUID;

-- Vul lege user_id's in met de huidige auth user (voor bestaande rijen)
-- (Dit faalt niet als er geen rijen zonder user_id zijn)
UPDATE locaties SET user_id = auth.uid() WHERE user_id IS NULL;

-- Maak user_id NOT NULL + default
ALTER TABLE locaties ALTER COLUMN user_id SET DEFAULT auth.uid();
DO $$ BEGIN
  ALTER TABLE locaties ALTER COLUMN user_id SET NOT NULL;
EXCEPTION WHEN others THEN NULL;
END $$;

-- ── 3. WIJN_LOCATIES TABEL ──
CREATE TABLE IF NOT EXISTS wijn_locaties (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  wijn_id UUID NOT NULL REFERENCES wijnen(id) ON DELETE CASCADE,
  locatie_id UUID NOT NULL REFERENCES locaties(id) ON DELETE CASCADE,
  voorraad INTEGER DEFAULT 0,
  positie TEXT DEFAULT '',
  user_id UUID NOT NULL DEFAULT auth.uid(),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Zorg dat alle kolommen bestaan (als tabel al bestond)
ALTER TABLE wijn_locaties ADD COLUMN IF NOT EXISTS user_id UUID;
ALTER TABLE wijn_locaties ADD COLUMN IF NOT EXISTS positie TEXT DEFAULT '';

-- Vul lege user_id's
UPDATE wijn_locaties SET user_id = auth.uid() WHERE user_id IS NULL;

ALTER TABLE wijn_locaties ALTER COLUMN user_id SET DEFAULT auth.uid();
DO $$ BEGIN
  ALTER TABLE wijn_locaties ALTER COLUMN user_id SET NOT NULL;
EXCEPTION WHEN others THEN NULL;
END $$;

-- ── 4. RLS INSCHAKELEN ──
ALTER TABLE locaties ENABLE ROW LEVEL SECURITY;
ALTER TABLE wijn_locaties ENABLE ROW LEVEL SECURITY;

-- ── 5. RLS POLICIES (verwijder oude + maak nieuwe) ──

-- Locaties policies
DROP POLICY IF EXISTS "Users select own locaties" ON locaties;
DROP POLICY IF EXISTS "Users insert own locaties" ON locaties;
DROP POLICY IF EXISTS "Users update own locaties" ON locaties;
DROP POLICY IF EXISTS "Users delete own locaties" ON locaties;
DROP POLICY IF EXISTS "Users manage own locaties" ON locaties;

CREATE POLICY "Users select own locaties" ON locaties
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users insert own locaties" ON locaties
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users update own locaties" ON locaties
  FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users delete own locaties" ON locaties
  FOR DELETE USING (auth.uid() = user_id);

-- Wijn_locaties policies
DROP POLICY IF EXISTS "Users select own wijn_locaties" ON wijn_locaties;
DROP POLICY IF EXISTS "Users insert own wijn_locaties" ON wijn_locaties;
DROP POLICY IF EXISTS "Users update own wijn_locaties" ON wijn_locaties;
DROP POLICY IF EXISTS "Users delete own wijn_locaties" ON wijn_locaties;
DROP POLICY IF EXISTS "Users manage own wijn_locaties" ON wijn_locaties;

CREATE POLICY "Users select own wijn_locaties" ON wijn_locaties
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users insert own wijn_locaties" ON wijn_locaties
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users update own wijn_locaties" ON wijn_locaties
  FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users delete own wijn_locaties" ON wijn_locaties
  FOR DELETE USING (auth.uid() = user_id);

-- ── 6. INDEX VOOR PERFORMANCE ──
CREATE INDEX IF NOT EXISTS idx_wijn_locaties_wijn ON wijn_locaties(wijn_id);
CREATE INDEX IF NOT EXISTS idx_wijn_locaties_locatie ON wijn_locaties(locatie_id);
CREATE INDEX IF NOT EXISTS idx_wijn_locaties_user ON wijn_locaties(user_id);
CREATE INDEX IF NOT EXISTS idx_locaties_user ON locaties(user_id);

-- ── 7. VERIFICATIE ──
-- Na uitvoeren kun je dit draaien om te controleren:
-- SELECT table_name, column_name, data_type FROM information_schema.columns
-- WHERE table_name IN ('wijnen','locaties','wijn_locaties') ORDER BY table_name, ordinal_position;
--
-- SELECT schemaname, tablename, policyname, cmd FROM pg_policies
-- WHERE tablename IN ('locaties','wijn_locaties');

-- ============================================================
-- KLAAR! Locaties opslaan in de multi-user versie zou nu werken.
-- ============================================================
