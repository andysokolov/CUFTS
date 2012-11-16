CREATE TABLE journals_auth_titles (
	id		SERIAL PRIMARY KEY,
	journal_auth	INTEGER,
	title		VARCHAR(1024),
	title_count	INTEGER
);

CREATE INDEX j_auth_titles_idx ON journals_auth_titles (title);
CREATE INDEX j_auth_j_a_idx ON journals_auth_titles (journal_auth);