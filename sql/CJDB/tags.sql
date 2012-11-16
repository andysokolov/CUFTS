CREATE TABLE cjdb_tags (
	id              SERIAL PRIMARY KEY,
	tag             VARCHAR(512),
	account         INTEGER NOT NULL,
	site            INTEGER NOT NULL,
	level           INTEGER NOT NULL DEFAULT 0,
	viewing         INTEGER NOT NULL DEFAULT 0,
	journals_auth   INTEGER NOT NULL,
	created         TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX cjdb_tags_j_a_idx     ON cjdb_tags (journals_auth);
CREATE INDEX cjdb_tags_account_idx ON cjdb_tags (account);
CREATE INDEX cjdb_tags_tag_idx     ON cjdb_tags (tag);
CREATE INDEX cjdb_tags_site_idx    ON cjdb_tags (site);
