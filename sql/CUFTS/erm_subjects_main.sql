CREATE TABLE erm_subjects_main (
    id          SERIAL PRIMARY KEY,
    erm_main    INTEGER NOT NULL,
    subject     INTEGER NOT NULL,
    rank        INTEGER,
    description TEXT
);

CREATE INDEX erm_subjects_main_m_idx ON erm_subjects_main ( erm_main );
CREATE UNIQUE INDEX erm_subjects_main_sm_idx ON erm_subjects_main ( subject, erm_main );
 