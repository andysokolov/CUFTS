CREATE TABLE cjdb_journals_associations (
    id              SERIAL PRIMARY KEY,
    journal         INTEGER NOT NULL,
    association     INTEGER NOT NULL,
    site            INTEGER NOT NULL
);

CREATE INDEX cjdb_journals_associations_j_idx ON cjdb_journals_associations (journal);
CREATE INDEX cjdb_journals_associations_sa_idx ON cjdb_journals_associations (site, association);