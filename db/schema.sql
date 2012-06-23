DROP TABLE IF EXISTS icons;
CREATE TABLE icons (
  id integer PRIMARY KEY AUTOINCREMENT,
  screen_name text,
  icon_url text,
  updated_at integer
);

DROP INDEX IF EXISTS screen_name_idx;
CREATE INDEX screen_name_idx on icons(screen_name);
