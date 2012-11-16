CREATE TABLE cjdb_journals_subjects (
    id              SERIAL PRIMARY KEY,
    journal         INTEGER NOT NULL,
    subject         INTEGER NOT NULL,
    site            INTEGER NOT NULL,
    level           INTEGER NOT NULL DEFAULT 0,
    origin          VARCHAR(1024)
);

CREATE INDEX cjdb_journals_subjects_j_idx ON cjdb_journals_subjects (journal);
CREATE INDEX cjdb_journals_subjects_ss_idx ON cjdb_journals_subjects (site, subject);