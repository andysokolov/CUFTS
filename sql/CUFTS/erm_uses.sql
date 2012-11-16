CREATE TABLE erm_uses (
    id                 SERIAL PRIMARY KEY,
    erm_main           INTEGER NOT NULL,
    date               TIMESTAMP DEFAULT NOW()
);

CREATE INDEX erm_uses_main_idx ON erm_uses (erm_main);
