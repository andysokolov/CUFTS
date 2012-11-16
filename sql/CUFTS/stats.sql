CREATE TABLE stats (
	id		SERIAL,
	request_date	DATE,
	request_time	TIME,
	
	site		INTEGER NOT NULL,

        issn		VARCHAR(8),
        isbn		VARCHAR(13),
        title		VARCHAR(512),
        volume		VARCHAR(64),
        issue		VARCHAR(64),
        date		VARCHAR(64),
        doi		VARCHAR(128),

	results		BOOLEAN NOT NULL DEFAULT FALSE
);
