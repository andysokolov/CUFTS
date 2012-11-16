ALTER TABLE cjdb_titles RENAME TO old_cjdb_titles;

CREATE TABLE cjdb_titles (
	id SERIAL PRIMARY KEY,
	title VARCHAR(1024),
	search_title VARCHAR(1024)
);

CREATE INDEX cjdb_titles_st_po_idx    ON cjdb_titles (search_title varchar_pattern_ops);
CREATE INDEX cjdb_titles_st_exact_idx ON cjdb_titles (search_title);


CREATE TABLE cjdb_journals_titles (
    id SERIAL PRIMARY KEY,
    journal INTEGER NOT NULL,
    title INTEGER NOT NULL,
    site INTEGER NOT NULL,
    main INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX cjdb_journ_ttl_j_idx ON cjdb_journals_titles ( journal );
CREATE INDEX cjdb_journ_ttl_s_t_idx ON cjdb_journals_titles ( site, title );

INSERT INTO cjdb_titles (title, search_title)
SELECT DISTINCT ON (title, search_title) title, search_title 
FROM old_cjdb_titles;

INSERT INTO cjdb_journals_titles (journal, title, site, main)
SELECT journal, cjdb_titles.id, site, main
FROM old_cjdb_titles, cjdb_titles
WHERE old_cjdb_titles.title = cjdb_titles.title
AND old_cjdb_titles.search_title = cjdb_titles.search_title;

