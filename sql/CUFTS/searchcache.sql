CREATE TABLE searchcache (
	id		    SERIAL PRIMARY KEY,

    type        VARCHAR(1024),
	query		TEXT,
	result		TEXT,

	created		TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX searchcache_typequery_idx ON searchcache (type, query);
