CREATE TABLE cjdb_links (
    id                SERIAL PRIMARY KEY,
    journal           INTEGER NOT NULL,
    local_journal     INTEGER,
    print_coverage    VARCHAR(2048),
    citation_coverage VARCHAR(2048),
    fulltext_coverage VARCHAR(2048),
    embargo	          VARCHAR(2048),
    current	          VARCHAR(2048),
    URL               VARCHAR(2048),
    link_type         INTEGER NOT NULL,
    resource          INTEGER,
    site              INTEGER,
    rank              INTEGER
);

CREATE INDEX cjdb_links_journal ON cjdb_links (journal);