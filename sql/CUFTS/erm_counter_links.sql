CREATE TABLE erm_counter_links (
    id              SERIAL PRIMARY KEY,
    identifier      TEXT,
    erm_main        INTEGER NOT NULL,
    counter_source  INTEGER NOT NULL
);
