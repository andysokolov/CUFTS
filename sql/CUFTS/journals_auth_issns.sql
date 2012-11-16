CREATE TABLE journals_auth_issns (
	id		SERIAL PRIMARY KEY,
	journal_auth	INTEGER,
	issn		VARCHAR(8),
	info		VARCHAR(512)
);

CREATE INDEX j_auth_issns_idx ON journals_auth_issns (issn);
CREATE INDEX j_auth_i_j_a_idx ON journals_auth_issns (journal_auth);