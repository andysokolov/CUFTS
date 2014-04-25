CREATE TABLE erm_counter_titles (
    id              SERIAL PRIMARY KEY,
    title           VARCHAR(1024) NOT NULL,
    issn            VARCHAR(8),
    e_issn          VARCHAR(8),
    doi             VARCHAR(1024),
    journal_auth    INTEGER
);

CREATE INDEX erm_counter_titles_ja_idx ON erm_counter_titles (journal_auth) WHERE journal_auth IS NOT NULL;
CREATE INDEX erm_counter_titles_issn_idx ON erm_counter_titles (issn) WHERE issn IS NOT NULL;
CREATE INDEX erm_counter_titles_e_issn_idx ON erm_counter_titles (e_issn) WHERE e_issn IS NOT NULL;
