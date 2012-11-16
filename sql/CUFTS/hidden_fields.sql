CREATE TABLE hidden_fields (
	id		SERIAL PRIMARY KEY,

	site		INTEGER NOT NULL,
	resource	INTEGER,		/* id for a local resource */
	field		VARCHAR(256)
);
