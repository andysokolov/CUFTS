CREATE TABLE cjdb_journals_titles (
    id              SERIAL PRIMARY KEY,
    journal         INTEGER NOT NULL,
    title           INTEGER NOT NULL,
    site            INTEGER NOT NULL,
    main            INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX journ_ttl_j_idx ON cjdb_journals_titles (journal);
CREATE INDEX journ_ttl_s_t_idx ON cjdb_journals_titles (site, title);