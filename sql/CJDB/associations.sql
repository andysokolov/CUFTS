CREATE TABLE cjdb_associations (
    id                  SERIAL PRIMARY KEY,
    association         VARCHAR(512) NOT NULL,
    search_association  VARCHAR(512) NOT NULL
);

CREATE INDEX cjdb_associations_sa_exact_idx ON cjdb_associations (search_association);
CREATE INDEX cjdb_associations_sa_idx ON cjdb_associations (search_association varchar_pattern_ops);
