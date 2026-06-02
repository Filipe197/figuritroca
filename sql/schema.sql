-- ============================================================
-- FiguriTroca — Schema Supabase
-- Execute no SQL Editor do Supabase (supabase.com)
-- ============================================================

-- Extensão para UUIDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- PROFILES (estende auth.users do Supabase)
-- ============================================================
CREATE TABLE profiles (
  id           UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username     TEXT UNIQUE NOT NULL,
  full_name    TEXT,
  avatar_url   TEXT,
  city         TEXT,
  state        TEXT DEFAULT 'PE',
  bio          TEXT,
  reputation   NUMERIC(3,2) DEFAULT 5.0,
  total_trades INTEGER DEFAULT 0,
  points       INTEGER DEFAULT 0,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ALBUMS & STICKERS
-- ============================================================
CREATE TABLE albums (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name       TEXT NOT NULL,
  year       INTEGER NOT NULL,
  total      INTEGER NOT NULL DEFAULT 640,
  cover_url  TEXT,
  active     BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO albums (name, year, total, active) VALUES
  ('Copa do Mundo 2026', 2026, 640, TRUE),
  ('Copa do Mundo 2022', 2022, 670, FALSE);

CREATE TABLE user_stickers (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  album_id   UUID NOT NULL REFERENCES albums(id),
  number     INTEGER NOT NULL,
  quantity   INTEGER DEFAULT 1,  -- >1 = repetida
  status     TEXT DEFAULT 'have' CHECK (status IN ('have','need')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, album_id, number, status)
);

-- ============================================================
-- MATCHES AUTOMÁTICOS (view)
-- ============================================================
CREATE OR REPLACE VIEW sticker_matches AS
SELECT
  a.user_id   AS user_a,
  b.user_id   AS user_b,
  a.album_id,
  a.number    AS sticker_a_gives,
  b.number    AS sticker_b_gives
FROM user_stickers a
JOIN user_stickers b
  ON a.album_id = b.album_id
  AND a.user_id <> b.user_id
  AND a.status = 'have' AND a.quantity > 1
  AND b.status = 'have' AND b.quantity > 1
WHERE EXISTS (
  SELECT 1 FROM user_stickers n
  WHERE n.user_id = b.user_id AND n.album_id = a.album_id
    AND n.number = a.number AND n.status = 'need'
)
AND EXISTS (
  SELECT 1 FROM user_stickers n2
  WHERE n2.user_id = a.user_id AND n2.album_id = a.album_id
    AND n2.number = b.number AND n2.status = 'need'
);

-- ============================================================
-- TRADES (trocas)
-- ============================================================
CREATE TABLE trades (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  proposer_id     UUID NOT NULL REFERENCES profiles(id),
  receiver_id     UUID NOT NULL REFERENCES profiles(id),
  album_id        UUID NOT NULL REFERENCES albums(id),
  sticker_give    INTEGER NOT NULL,
  sticker_get     INTEGER NOT NULL,
  status          TEXT DEFAULT 'pending' CHECK (status IN ('pending','accepted','rejected','completed','cancelled')),
  meet_point_id   UUID REFERENCES meet_points(id),
  meet_date       DATE,
  proposer_confirmed BOOLEAN DEFAULT FALSE,
  receiver_confirmed BOOLEAN DEFAULT FALSE,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- MEET POINTS (pontos de troca)
-- ============================================================
CREATE TABLE meet_points (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  creator_id   UUID NOT NULL REFERENCES profiles(id),
  name         TEXT NOT NULL,
  description  TEXT,
  address      TEXT NOT NULL,
  city         TEXT NOT NULL,
  state        TEXT NOT NULL,
  lat          NUMERIC(10,7),
  lng          NUMERIC(10,7),
  type         TEXT DEFAULT 'informal' CHECK (type IN ('event','informal')),
  schedule     TEXT,
  active       BOOLEAN DEFAULT TRUE,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE meet_confirmations (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  point_id     UUID NOT NULL REFERENCES meet_points(id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  event_date   DATE,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(point_id, user_id, event_date)
);

-- ============================================================
-- CHAT (mensagens diretas e grupos)
-- ============================================================
CREATE TABLE conversations (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  type         TEXT DEFAULT 'direct' CHECK (type IN ('direct','group','community')),
  name         TEXT,
  icon         TEXT,
  created_by   UUID REFERENCES profiles(id),
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE conversation_members (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  joined_at       TIMESTAMPTZ DEFAULT NOW(),
  last_read_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(conversation_id, user_id)
);

CREATE TABLE messages (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id       UUID NOT NULL REFERENCES profiles(id),
  content         TEXT,
  type            TEXT DEFAULT 'text' CHECK (type IN ('text','image','emoji','system')),
  image_url       TEXT,
  reactions       JSONB DEFAULT '{}',
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Index para performance
CREATE INDEX idx_messages_conv ON messages(conversation_id, created_at DESC);
CREATE INDEX idx_user_stickers_user ON user_stickers(user_id, album_id);
CREATE INDEX idx_trades_users ON trades(proposer_id, receiver_id);
CREATE INDEX idx_meet_conf ON meet_confirmations(point_id);

-- ============================================================
-- COMUNIDADE — POSTS
-- ============================================================
CREATE TABLE posts (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  author_id   UUID NOT NULL REFERENCES profiles(id),
  content     TEXT NOT NULL,
  type        TEXT DEFAULT 'general' CHECK (type IN ('general','tip','question','achievement')),
  image_url   TEXT,
  likes       INTEGER DEFAULT 0,
  helpful     INTEGER DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE post_likes (
  post_id    UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  PRIMARY KEY (post_id, user_id)
);

CREATE TABLE post_comments (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id    UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  author_id  UUID NOT NULL REFERENCES profiles(id),
  content    TEXT NOT NULL,
  likes      INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- CONQUISTAS (badges)
-- ============================================================
CREATE TABLE achievements (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  key         TEXT UNIQUE NOT NULL,
  name        TEXT NOT NULL,
  description TEXT,
  points      INTEGER DEFAULT 100,
  icon        TEXT
);

INSERT INTO achievements (key, name, description, points, icon) VALUES
  ('first_trade',     'Primeira troca!',          'Complete sua primeira troca', 100, '🤝'),
  ('ten_trades',      'Colecionador dedicado',     'Complete 10 trocas',          200, '🌟'),
  ('fifty_trades',    'Mestre das trocas',         'Complete 50 trocas',          500, '🏅'),
  ('five_stars',      'Reputação 5 estrelas',      'Receba 5 avaliações máximas', 150, '⭐'),
  ('first_event',     'Presença confirmada',       'Confirme presença em evento', 50,  '📍'),
  ('five_events',     'Embaixador da comunidade',  'Confirme em 5 eventos',       300, '🎖️'),
  ('album_complete',  'Álbum completo!',           'Complete um álbum inteiro',   1000,'🏆'),
  ('fast_reply',      'Resposta rápida',           'Responda em menos de 1h',     75,  '⚡');

CREATE TABLE user_achievements (
  user_id        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  achievement_id UUID NOT NULL REFERENCES achievements(id),
  earned_at      TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, achievement_id)
);

-- ============================================================
-- STORAGE BUCKETS (execute no Dashboard > Storage)
-- ============================================================
-- Bucket: "avatars"    → públic, max 2MB, images/*
-- Bucket: "chat-images" → públic, max 5MB, images/*
-- Bucket: "post-images" → públic, max 5MB, images/*

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE profiles              ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_stickers         ENABLE ROW LEVEL SECURITY;
ALTER TABLE trades                ENABLE ROW LEVEL SECURITY;
ALTER TABLE meet_points           ENABLE ROW LEVEL SECURITY;
ALTER TABLE meet_confirmations    ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations         ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_members  ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages              ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_likes            ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_comments         ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements     ENABLE ROW LEVEL SECURITY;

-- Profiles: todos leem, só o dono edita
CREATE POLICY "profiles_read"   ON profiles FOR SELECT USING (TRUE);
CREATE POLICY "profiles_insert" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_update" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Stickers: todos leem, só dono edita
CREATE POLICY "stickers_read"   ON user_stickers FOR SELECT USING (TRUE);
CREATE POLICY "stickers_write"  ON user_stickers FOR ALL  USING (auth.uid() = user_id);

-- Trades: participantes leem
CREATE POLICY "trades_read"  ON trades FOR SELECT USING (auth.uid() IN (proposer_id, receiver_id));
CREATE POLICY "trades_write" ON trades FOR INSERT WITH CHECK (auth.uid() = proposer_id);
CREATE POLICY "trades_update" ON trades FOR UPDATE USING (auth.uid() IN (proposer_id, receiver_id));

-- Meet points: todos leem, autenticados criam
CREATE POLICY "points_read"   ON meet_points FOR SELECT USING (TRUE);
CREATE POLICY "points_insert" ON meet_points FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "points_update" ON meet_points FOR UPDATE USING (auth.uid() = creator_id);

-- Confirmações: todos leem, autenticados criam
CREATE POLICY "confirm_read"  ON meet_confirmations FOR SELECT USING (TRUE);
CREATE POLICY "confirm_write" ON meet_confirmations FOR ALL USING (auth.uid() = user_id);

-- Mensagens: membros da conversa leem
CREATE POLICY "msgs_read"   ON messages FOR SELECT
  USING (EXISTS (SELECT 1 FROM conversation_members m WHERE m.conversation_id = messages.conversation_id AND m.user_id = auth.uid()));
CREATE POLICY "msgs_insert" ON messages FOR INSERT
  WITH CHECK (auth.uid() = sender_id AND EXISTS (SELECT 1 FROM conversation_members m WHERE m.conversation_id = messages.conversation_id AND m.user_id = auth.uid()));

-- Membros: participantes leem
CREATE POLICY "members_read" ON conversation_members FOR SELECT
  USING (auth.uid() = user_id OR EXISTS (SELECT 1 FROM conversation_members m WHERE m.conversation_id = conversation_members.conversation_id AND m.user_id = auth.uid()));

-- Posts: todos leem, autenticados criam
CREATE POLICY "posts_read"   ON posts FOR SELECT USING (TRUE);
CREATE POLICY "posts_insert" ON posts FOR INSERT WITH CHECK (auth.uid() = author_id);
CREATE POLICY "posts_update" ON posts FOR UPDATE USING (auth.uid() = author_id);

-- Conquistas: todos leem
CREATE POLICY "ach_read" ON achievements       FOR SELECT USING (TRUE);
CREATE POLICY "ua_read"  ON user_achievements  FOR SELECT USING (TRUE);

-- ============================================================
-- REALTIME (ative no Dashboard > Database > Replication)
-- ============================================================
-- Ative as tabelas: messages, trades, meet_confirmations, posts

-- ============================================================
-- TRIGGER: criar profile automático após signup
-- ============================================================
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, username, full_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ============================================================
-- FUNÇÃO: atualizar updated_at em trades
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trades_updated_at BEFORE UPDATE ON trades
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
