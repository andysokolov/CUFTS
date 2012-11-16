CREATE TABLE erm_main_link (
    id          SERIAL PRIMARY KEY,
    erm_main    INTEGER NOT NULL,
    link_type   CHAR NOT NULL,
    link_id     INTEGER NOT NULL
);

CREATE INDEX erm_main_link_idx ON erm_main_link ( link_type, link_id );
CREATE INDEX erm_main_link_main_idx ON erm_main_link ( erm_main );
 