CREATE TABLE cjdb_subjects (
    id              SERIAL PRIMARY KEY,
    subject         VARCHAR(1024) NOT NULL,
    search_subject  VARCHAR(1024) NOT NULL
);

CREATE INDEX cjdb_subjects_st_exact_idx ON cjdb_subjects (search_subject);
CREATE INDEX cjdb_subjects_st_idx ON cjdb_subjects (search_subject varchar_pattern_ops);