-- RADAR: per-user saved tracks ("Library → Saved").
-- user_id is the Neon Auth user id (the JWT `sub`). It is never accepted from a client;
-- the API always takes it from the verified token.
CREATE TABLE IF NOT EXISTS radar_saved_tracks (
  user_id  text        NOT NULL,
  track_id text        NOT NULL,
  saved_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, track_id)
);

CREATE INDEX IF NOT EXISTS radar_saved_tracks_user_saved_at
  ON radar_saved_tracks (user_id, saved_at DESC);
