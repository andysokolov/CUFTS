CREATE TABLE erm_files (
    id              SERIAL PRIMARY KEY,
    linked_id       INTEGER NOT NULL,
    link_type       CHAR(1),
    description     TEXT,
    ext             VARCHAR(64),
    UUID            VARCHAR(36),
    created         TIMESTAMP DEFAULT NOW()
);

CREATE INDEX erm_files_linked_idx ON erm_files (linked_id);
