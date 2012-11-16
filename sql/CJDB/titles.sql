CREATE TABLE cjdb_titles (
	id              SERIAL PRIMARY KEY,
	title           VARCHAR(1024) NOT NULL,
	search_title    VARCHAR(1024) NOT NULL
);

CREATE INDEX cjdb_titles_st_exact_idx ON cjdb_titles (search_title);
CREATE INDEX cjdb_titles_st_idx ON cjdb_titles (search_title varchar_pattern_ops);
CREATE INDEX cjdb_titles_ft_idx ON cjdb_titles USING gin(to_tsvector('english', search_title));