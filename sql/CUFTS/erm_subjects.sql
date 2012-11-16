CREATE TABLE erm_subjects (
    id              SERIAL PRIMARY KEY,
    site            INTEGER,
    subject         VARCHAR(1024),
    description     TEXT
);

CREATE INDEX erm_subjects_site_idx ON erm_subjects (site);