CREATE TABLE cjdb_issns (
	id		SERIAL PRIMARY KEY,
	journal		INTEGER NOT NULL,
	site		INTEGER,
	issn		VARCHAR(8)
);

CREATE INDEX cjdb_issns_journal ON cjdb_issns (journal);
CREATE INDEX cjdb_issns_issn ON cjdb_issns (issn);
