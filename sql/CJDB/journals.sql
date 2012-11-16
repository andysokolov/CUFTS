CREATE TABLE cjdb_journals (
	id              SERIAL PRIMARY KEY,
	title		    VARCHAR(1024) NOT NULL,
	sort_title	    VARCHAR(1024) NOT NULL,
	stripped_sort_title VARCHAR(1024) NOT NULL,
	call_number     VARCHAR(128),
	image           VARCHAR(2048),
	image_link      VARCHAR(2048),
	rss             VARCHAR(2048),
	miscellaneous   VARCHAR(2048),
	journals_auth   INTEGER,
	site            INTEGER NOT NULL,
	created         TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX cjdb_journals_st_idx ON cjdb_journals (sort_title);
CREATE INDEX cjdb_journals_ja_idx ON cjdb_journals (journals_auth);
CREATE INDEX cjdb_journals_site_idx ON cjdb_journals (site);
