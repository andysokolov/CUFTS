CREATE TABLE erm_keywords (
    id              SERIAL PRIMARY KEY,
    erm_main        INTEGER NOT NULL,
    keyword         VARCHAR(1024)
);

CREATE INDEX erm_keywords_main_idx ON erm_keywords (erm_main);
CREATE INDEX erm_keywords_keyword_idx ON erm_keywords (keyword);
