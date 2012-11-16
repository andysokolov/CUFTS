CREATE TABLE erm_names (
    id              SERIAL PRIMARY KEY,
    erm_main        INTEGER NOT NULL,
    name            VARCHAR(1024),
    search_name     VARCHAR(1024),
    main            INTEGER DEFAULT 0
);

CREATE INDEX erm_names_main_idx ON erm_names (erm_main);
CREATE INDEX erm_names_sn_idx ON erm_names (search_name);
