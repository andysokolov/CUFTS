CREATE TABLE accounts (
	id		SERIAL PRIMARY KEY,
	key		VARCHAR(64),
	name		VARCHAR(256),
	password	VARCHAR(32),

	email		VARCHAR(256),
	phone		VARCHAR(256),

	administrator	BOOLEAN DEFAULT FALSE,
	edit_global	BOOLEAN DEFAULT FALSE,
	journal_auth    BOOLEAN DEFAULT FALSE,

	active		BOOLEAN DEFAULT TRUE,
	last_login	TIMESTAMP,
	created		TIMESTAMP NOT NULL DEFAULT NOW(),
	modified	TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX accounts_key_idx on accounts(key);
